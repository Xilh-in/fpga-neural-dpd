# DPD 最终相减通路仿真（Vivado 2025.2）

这份包补上此前缺少的通路 TB。运行对象是真实的 `data_ctrl`，包含 TX RAM 读取、`align` 的直通延迟、`dpd_top` 模型、最终相减与饱和，以及节点 5/6/7 的采集写入和总线读回。

**直接运行无需 Python、板卡、Vitis、JESD IP 或 JESD 许可。无需先综合或生成比特流。**

## 先说明这份包里的 RTL

基线是你此前上传的 `rtl.zip`，使用 `dpd_ip_v1`。只在本包的 `data_ctrl.v` 副本里加入已经讨论的修改：

1. 增加 `dout_vd_d1`，与现有 `model_out_i_d1/q_d1` 一起打一拍。
2. `yn_out_L_i/q` 在 `dout_vd_d1` 有效时减去 `model_out_i_d1/q_d1`。
3. `ch_sel=001` 时，节点 G 采集同一组实际用于相减的延迟后模型值。

`align.v` 的 `delay_data_x[65]` 保持原值，触发常数 66 保持原值。不要同时把 TX 抽头改成 64。

修改内容见根目录 readme.md 和 build/reports/reorganization_validation.md。包内 RTL 是独立仿真副本，不会自动更新你用于生成比特流的工程。如果你昨天又改过其他 RTL，请先核对差异，再把相应版本放入此独立仿真工程。

## 方法一：在 Vivado 内一条命令建立仿真工程（推荐）

1. 把压缩包解压到 `D:/vivado_example`，确认存在：

   `D:/vivado_example/dpd_path_sim/create_sim_project.tcl`

   注意避免多嵌套一层 `dpd_path_sim/dpd_path_sim`。

2. 打开 **Vivado 2025.2 新窗口**，停留在首页，不打开原来的实现工程。
3. 在下方 **Tcl Console** 输入：

   ```tcl
   source {D:/vivado_example/dpd_path_sim/create_sim_project.tcl}
   ```

   你解压在别处时，把命令中的路径改成实际路径。脚本会自动配置 TB 数据路径，无需编辑 TB。

4. 出现 `PATH_SIM_PROJECT_READY` 后，在左侧点击：

   **SIMULATION → Run Simulation → Run Behavioral Simulation**。

5. 等待编译、展开与运行结束。脚本已设置运行到结束；如果仿真窗口只停在 1000 ns，点上方 **Run All**，或在仿真窗口的 Tcl Console 输入：

   ```tcl
   run all
   ```

6. 在 Tcl Console 搜索末尾的 **`PATH_SIM_PASS`**。`$finish` 是 TB 正常结束，不是出错。

每次建立的工程放在 `work/时间戳/`，不会覆盖已有工程。第二天双击该文件夹里的 `dpd_path_sim.xpr`，即可重新打开。

## 方法二：完全通过图形界面新建工程

如果用了方法一，不用再做这一节。

1. **Create Project → Next**，工程名填 `dpd_path_sim`，位置选一个新的空目录。
2. 选择 **RTL Project**，勾选 **Do not specify sources at this time**。
3. **Default Part → Parts** 搜索并选择 `xc7z100ffg900-2`，然后 Finish。
4. 左侧 **Add Sources → Add or create design sources → Add Files**，选中本包 `rtl/dpd_ip_v1/` 下全部 **13 个 HDL 文件**。只添加这个目录里的文件，不添加原项目顶层、BD、XCI、DCP 或约束。
5. 为便于核对路径，先不勾选 **Copy sources into project**。Finish 后，在 Sources 的文件属性中确认这些文件的 **File Type 为 SystemVerilog**。其中 `.v` 文件也按 SystemVerilog 处理，因为模型有数组端口。
6. **Add Sources → Add or create simulation sources → Add Files**，添加 `tb_tx_model_path.sv`。
7. 展开 **Simulation Sources → sim_1**，右击 `tb_tx_model_path`，选择 **Set as Top**。不要把 `data_ctrl` 设成仿真顶层。
8. 双击 TB，找到开头：

   ```systemverilog
   parameter SIM_DIR = "D:/vivado_example/dpd_path_sim/simulation";
   ```

   将路径改为你解压后实际的 `simulation` 文件夹路径。使用正斜杠 `/`，保留双引号，不指向工程的 `sim_1/behav` 文件夹。

9. 保存，点击 **Run Simulation → Run Behavioral Simulation**。
10. 仿真窗口打开后点 **Run All**。默认运行的 1000 ns 不够，本 TB 需要约 0.6 ms 的仿真时间。不要用“跑到 1000 ns 没报错”作为通过依据。

## 通过标准和结果文件

本 TB 自动检查以下内容，失败会输出 `PATH_ERROR`，最终以 `PATH_SIM_FAIL` 或 `$fatal` 结束。

| 检查 | 具体含义 |
| --- | --- |
| 系数写入 | 通过 `data_ctrl` 实际系数接口写入 576 个参数，并核对模型系数存储 |
| 直通 | `ch_sel=000` 时最终输出等于该拍直通操作数 |
| 同一个采样的模型输出 | 以 TX I/Q 唯一数值识别样本编号 k，要求相减所用模型值等于独立定点参考 F(x)[k] |
| 最终相减 | 要求 TX 最终输出等于 `sat16(x[k] - F(x)[k])`，I/Q 分别计算 |
| 采集通路 | 通过实际读接口读取节点 5/6/7，逐点核对直通、模型与最终结果 |
| 关闭模型 | 等待流水线排空后，要求补偿模式退回直通 |
| 停止发送 | 等待 TX 有效流水线排空后，要求 TX 输出为零 |
| 覆盖范围 | 相减阶段必须覆盖全部 1024 个不同输入采样，四个测试阶段都必须运行 |

仿真会输出：

- `simulation/path_result.txt`：结果摘要。成功时包含 `ERRORS=0` 和 `PATH_SIM_PASS`。
- `simulation/path_trace.csv`：逐拍比较日志。直通和模型操作数取时钟边沿前值，最终结果取该边沿寄存器更新后的值，避免日志本身制造一拍偏移。
- `simulation/cap_tx_model.csv`：通过采集读接口读回的 1024 点节点 5/6/7 数据。

**发给我 `path_result.txt` 即可判断这轮是否通过。**失败时再加上前几条 `PATH_ERROR` 和两个 CSV。不必压缩整个 Vivado 工程。

只以你这次仿真新生成的 `simulation/path_result.txt` 为准。本包 `validation/` 目录是交付前的本地验证记录，不代表你已在 Vivado 里运行过。

## 参考值怎么来的

输入与 576 个系数沿用 B 核对过的 `tx_delay_1024.csv` 和 `model_0216_0.json`。模型参考由 B 的逐位定点 Python 实现生成，包含 RTL 中的移位、截断和限幅规则，不能用理想浮点模型直接代替。

这次 TB 用 TX RAM 周期重复 1024 点。参考计算先把输入重复三遍，再取中间一帧结果，以提供帧边界两侧的真实周期上下文；因此可以比较整帧 1024 点，而不必丢弃此前孤立抓取数据缺少上下文的首尾采样。

TB 实例化时把 `DATA_LENGTH` 设为 1024，便于使用这组已核对输入；这不要求把上板工程的生产参数 17536 改成 1024。

本测试使用 AXI 100 MHz 和数据时钟约 61.44 MHz，只是确定性的仿真激励，不代表已经确认板卡外接时钟频率。RX 输入固定为零，不模拟射频器件、JESD 链路或 LNA 性能。

如需换输入或系数，再使用 Python 重新生成三个 `.mem`：

```bat
conda activate dpd
cd /d D:\vivado_example\dpd_path_sim
python -m pip install -r requirements.txt
python tools/regenerate_vectors.py
```

如需 B 再独立核对 CSV，可以在仿真完成后运行 `python tools/check_path_trace.py`，生成 `simulation/path_csv_validation.json`。

不换数据时完全不需要这些命令。当前计分板要求 1024 个 I/Q 对唯一，才能用数值可靠识别采样编号。

## 常见问题

- **Cannot find samples.mem**：方法二中的 `SIM_DIR` 路径错误，或压缩包多套了一层目录。
- **重复 module / already declared**：同时加入了两个版本的同名 RTL；工程里每个模块只保留一份。
- **模型输出大量 X**：先看系数文件路径及 `COEFFICIENTS_PASS 576/576` 是否出现，再看编译日志，不要把 X 忽略掉。
- **波形窗口没结束**：点击 Run All。编译耗时和仿真时间是两件事。
- **直接替换源文件后重跑**：关闭当前仿真，保存修改后重新启动 Behavioral Simulation，避免继续运行旧的仿真快照。
- **只出现宽度或隐式 wire 警告**：源代码保留了原有这类告警；要以具体错误、最终自动检查及报告为准。交付未把这些警告全部消除，也没有据此保证所有其他模式。

仿真通过后，再将相同 `data_ctrl` 修改同步到正式实现所用源文件，重新走实现、时序检查和生成比特流；本包不会替你更新已有 `.bit` 或 `.elf`。
