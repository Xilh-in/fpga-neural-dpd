# PS/串口阻塞定位与有界 IO

## 适用场景

PS 裸机程序、MCU 或 Python 上位机出现“初始化后串口没反应”“等待 done 一直不返回”“写波形半途停止”的问题。通用代码不依赖 Xilinx UART/XTime；适配这些 API 是工程集成者的职责。

## 使用方法

先执行不打开串口的示例：`python fpga-bounded-io/scripts/mock_demo.py`。追加 `--short` 会故意触发短包超时并返回 1；这是失败路径演示，不是正常通过。

1. 使用根目录 `templates/interface_contract.md` 确认接口。
2. Python 用 importlib 从 `scripts/bounded_io.py` 加载 `Session`，给它有有限 read/write 超时的 transport。`transfer(packet, response_bytes, timeout, trailer)` 不假设任何命令名称、板卡地址或数据点数。
3. 成功只返回规定长度的 bytes；二进制含 LF 不会被提前切断。ACK 模式显式传 `ack_only=True` 与 delimiter。
4. C 侧复制 `assets/deadline_io.h`，接入计时/ready/get_byte/status 回调。传入暂存区容量；仅在 `skill_receive_staged()` 返回 1 后提交。返回 0 后的寄存器清理、停止输出和重新启动由具体工程决定。
5. 运行 `python verify_all.py` 验证通用 Python 模拟；C 的独立回调测试在本子目录 `tests/test_deadline.c`，需要可用本机 C 编译器。

具备本机 gcc 时，在 `skill/` 目录执行 `gcc -std=c99 -Wall -Wextra fpga-bounded-io/tests/test_deadline.c -o deadline_check`，再运行 `./deadline_check`（Windows 为 `.\deadline_check.exe`）。clang 可使用相同参数。交叉编译器产物不能当普通电脑程序直接运行；集成到 PS 后还需目标构建和板测。

期限单位由调用者定义。8N1 可按 `负载字节数 * 10 / 波特率` 估计线传输下限，再加基础等待和余量。本项目 70144 字节在 115200 baud 下仅线传输就约需 6.09 秒，不能统一设整包 2 秒。

## 已验证效果及来源

DPD 首版虽给 Python 加超时，PS 的启动 Data_Align 仍可能永远等待 CAP_DONE，Tx/Cyclic 仍会边接收边写。A 的反馈促使同时修复 PS：两个采集阶段超时退出、短包不提交、失败回命令接口、停止不可靠输出。

原项目 v2 的 C 模拟验证卡低/卡高后可继续接收寄存器命令、两种 7/8 字节短包 0 次 RAM 提交、最大 17536 点和滴流超时。本技能新提取的通用 transport/clock 代码另外执行回归；这些均为主机模拟，不是 2025.2 固件或实板通过证明。

## 失效条件

未配置 transport 自身有限超时、底层 MMIO 读卡死、计时器停止时，外层截止时间可能无效。没有帧号/CRC/重同步的旧协议，短包后的迟到字节仍可污染下一条命令；需由该协议定义复位/重连。内存不足以完整暂存时应采用带序号/提交的分块协议，不能直接把模板改成边收边提交而仍宣称原子性。清控制/停输出策略必须来自实际硬件，不默认套用 DPD 寄存器。
