---
name: fpga-bounded-io
description: Diagnose FPGA/PS control paths that hang on hardware status or incomplete serial payloads, and design bounded polling, staged writes and explicit binary response contracts. Use for bring-up and transfer failures, not to infer an undocumented board register map.
---

# PS 与串口有界等待

先读 [readme.md](readme.md)。准备接口表后再改代码：命令头、参数计数、地址单位、负载长度、字节序、响应、期限、失败后的状态与恢复。

## 操作顺序

1. 沿启动路径先找进入命令循环之前的所有等待。分别给“状态变 1”和“状态回 0”设有限期限；每条失败路径明确清哪些控制、是否停止输出、返回哪里，不能继续打印成功。
2. 主机的 read 超时不能解除 PS 的阻塞。两端都必须有截止时间。IO 本身若永不返回或时钟不递增，软件外层期限无法补救，记录为平台故障。
3. 对长度可界定的二进制写命令，先验长度、容量和范围，完整收到暂存区后才提交硬件；使用静态/BSS 或明确分配，不能把大缓冲放入小 PS 栈。
4. 同时设接收总期限与静默期限；大包按波特率/线编码估算，不把整包一律硬限 2 秒。已开始的残缺命令头也要有退出路径，纯空闲等待新命令是另一状态。
5. 二进制负载按固定长度接收后再检查尾标志。超时/错误后使会话失效，按真实协议恢复；没有帧同步机制时不能承诺清主机缓冲就能继续。

`scripts/bounded_io.py` 用传入 transport/clock 做通用 Python 处理；`assets/deadline_io.h` 是不含 BSP/寄存器地址的 C 模板。移植时由用户提供时钟、状态、UART 和失败清理回调。

## 提示词模板

> 审查启动到命令循环的可达性。对每个轮询和二进制接收列出终止条件、时间来源、返回路径和失败后硬件状态。先处理启动状态等待，再处理短包接收。保留成功协议，补充卡低/卡高、半包、滴流和正常完成的模拟检查，不把模拟退出等同于板上恢复。

案例与触发条件见 [references/lessons.md](references/lessons.md)。只有具体任务已授权时才执行实际板卡写入或复位；技能包生成/离线回放不需要板卡操作。
