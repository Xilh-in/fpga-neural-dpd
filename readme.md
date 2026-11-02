# 神经网络数字预失真 FPGA 系统

基于 Zynq-7000 与 AD9371 的神经网络 DPD 实现。PC 通过 UART 下发 TX 波形、采集原始 RX、完成时间及幅相补偿、训练误差模型，再将 576 个定点参数写入 FPGA。PL 实时计算模型输出，并与对应采样的延迟 TX 相减。

## 环境与硬件

- Vivado / Vitis 2025.2，器件 xc7z100ffg900-2。
- Zynq Cortex-A9 standalone 裸机程序，FMC AD9371 与 AD9528 时钟配置。
- Windows PC，Python 与 Spyder。Python 位于 PC，不在 PS 上运行。
- 上位机配置采样率 122.88 MS/s、ACPR 积分带宽 20 MHz、采集长度 16384。它们是当前程序的配置值。
- 串口默认 COM5、115200 baud，运行前按实际设备修改。

## 目录

| 目录 | 内容 |
| --- | --- |
| src/pl | 自定义 RTL、系统 HDL、约束、14 组 IP DCP 和 stub、实现脚本 |
| src/ps | PS C 源码、AD9371/AD9528/no-OS 驱动、XSA 和应用编译配置 |
| src/host | 上位机、数据处理、神经网络训练与定点参考、输入波形 |
| sim/dpd_path_sim | TX、模型输出、最终减法与采集接口的 RTL 仿真 |
| sim/model_core | 模型核定点参考、限幅核对和独立 RTL testbench |
| build/reports | 原有实现报告和验证记录 |
| board/hardware | 已提供的 dpd_align_fix.bit |
| board/software | 已提供的 dpd_app.elf |
| board/logs | 板上初始化日志 |
| data | 原始实测 NPZ、metadata 和图片 |
| skill | 通用 FPGA 验证工具及 Zynq SDT 迁移技能材料 |
| report | 技术报告 |
| tools | 工具固定文件名导出程序 |

## 文件命名与工具固定名称

提交目录中的文件和目录均使用小写 ASCII 名称。

CMake 和 skill 加载器分别需要 CMakeLists.txt 和 SKILL.md。提交包保留 cmakelists.txt、skill.md；实际使用这些工具前，在提交目录以外导出运行副本。例如在提交根目录运行：

```bat
python tools/export_tool_files.py --dest D:/vivado_example/dpd_runtime
```

目标目录必须为空或不存在，并且不能位于提交目录内。导出过程会在运行副本恢复工具固定文件名。Python 上位机和 Vivado RTL 仿真可直接从提交目录运行，无需先导出。

## 直接使用已有 bit 和 ELF

1. 连接板卡电源、JTAG、UART、AD9371 所需时钟和射频器件。
2. 在 Vivado Hardware Manager 下载 board/hardware/dpd_align_fix.bit。
3. 在 Vitis 使用匹配的 PS 平台初始化处理器，并下载 board/software/dpd_app.elf。调试配置如自动下载 bit，应选择同一个 dpd_align_fix.bit。
4. Continue 运行程序，等待 RF System Initial Successful，随后保持 CPU 运行。
5. 关闭占用该 COM 口的 Vitis 串口终端，再用 Python 连接。同一时刻只让一个串口软件使用该 COM 口。

## 上位机与训练
首次使用时，在 Anaconda Prompt 中创建环境并安装 Spyder：

```bat
conda activate dpd
cd /d D:/解压目录/src/host
python -m pip install -r requirements.txt
spyder --new-instance --debug-info verbose
```

打开 dpd_fpga.py，修改 PORT；依次按 # %% 单元格执行。运行 00、01 只加载配置与定义，03 打开串口。仅采集板上已有波形时可运行 00、01、03、06。需要更换发射波形时先执行 02，再执行 03、04、05，之后运行 06。

完整实验依次完成旁路采集、07 软件对齐与误差目标、08 训练、09 浮点与定点预测核对、10 参数下发与回读，之后按文件内后续单元格检查 DPD 输出和绘图。F5 整文件会执行硬件操作与训练，首次使用建议逐块执行。

- 输入 source.mat 与一个历史可选模型已从原始工程补入。source.mat 是历史工程输入，不代表本次实测数据。默认训练新模型。
- 当前模型文件为 expcnn_final.py、训练文件为 expcnn_bp_adam.py，模型类名为 expcnn。
- 原始 RX 使用 node1，软件浮点对齐后计算训练目标。node2 是硬件幅相处理结果，可能因定点运算限幅，不能替代原始 RX 评估射频频谱。
- TX 衰减、RX 增益改变后，需要重新采集旁路、训练和 DPD 数据；比较时保持相同配置。
- source.mat 不应与 PS 编译内置波形混为一谈；DO_DATA_ALIGN 默认关闭。

## 通路 RTL 仿真

在新的 Vivado 2025.2 窗口、不打开工程时，执行：

```tcl
source {D:/解压目录/sim/dpd_path_sim/create_sim_project.tcl}
```

点击 Run Simulation / Run Behavioral Simulation，然后 Run All。通过标准为 PATH_SIM_PASS 且 ERRORS=0。输入 mem 在 simulation 目录，脚本通过 SIM_DIR 参数传入路径。该仿真不需要射频板、JESD IP 许可、Vitis 或综合实现。

独立 CSV 复核：

```bat
python sim/dpd_path_sim/tools/check_path_trace.py
```

修改后的通路仿真 RTL 和 src/pl 对应 RTL 已检查代码一致。保留两份是为了维持原有独立仿真工程的相对路径；后续修改应同步两份。

## 模型参考核对

```bat
python -m pip install -r sim/model_core/requirements.txt
python sim/model_core/run_checks.py
python -m unittest discover -s sim/model_core -p test_reference.py -v
```

需要 XSim 模型核仿真时，在 PowerShell 执行：

```powershell
./sim/model_core/run_rtl_sim.ps1 -VivadoBin "D:/AMDDesignTools/2025.2/Vivado/bin"
```

该项使用历史采集数据，只对具备完整输入上下文的区间核对。它的 1 个采样偏移结论属于历史模型核采集关系，不应据此撤销已经通过通路仿真核对的最终 TX 相减对齐修改。

## 重新实现 PL

在新的 Vivado 2025.2 窗口执行：

```tcl
source {D:/解压目录/src/pl/run_restore.tcl}
```

脚本完成 RTL 综合、按实例插入现有 IP DCP、优化、布局、物理优化、布线和报告。布局后执行 phys_opt_design -directive AggressiveFanoutOpt，再执行 route_design -directive Explore，采用此前通过时序的实现策略。

结果放入 src/pl/build 的时间戳目录。默认不保存设计检查点，也不生成 bit。脚本检查时序报告是否满足当前约束，最终时序和 DRC 状态以本次生成的报告为准。

确认实现与时序通过后，保持当前设计打开，执行：

```tcl
source {D:/解压目录/build/scripts/finalize_bitstream.tcl}
```

该脚本检查 setup/hold 路径与黑盒，重新生成报告，再调用 write_bitstream。负 slack 时停止，不以历史通过报告替代当前时序结果。IP DCP 作为输入保留；不能只保留 stub。

## 重新编译 PS

先用 tools/export_tool_files.py 导出运行副本。然后在 Vitis 2025.2：

1. 根据导出目录 src/ps/hw/dpd_legacy_hw.xsa 创建硬件平台，处理器选择 ps7_cortexa9_0，系统为 standalone。
2. 在 BSP 选择实际使用的 UART 为 stdin/stdout，构建平台。
3. 创建 empty C application。将导出目录 vitis_app_config 中的 CMakeLists.txt、empty_applicationexample.cmake、userconfig.cmake 和 lscript.ld 复制到新应用的 src 目录。保留 Vitis 新生成的 app.yaml，不用提交包里的精简描述覆盖它。
4. 导出程序已将 userconfig.cmake 中的源码目录指向运行副本中的 app_src。源码无需再复制两份。移动运行副本后应重新导出或修改这些路径。
5. 构建应用并选择新 ELF 进行调试。XSA 用于创建当前 PS 平台；加载 PL 时选择最终 bit。若后续修改 PS 配置、地址映射或硬件接口，必须同步更新 XSA 和平台。

## Skill 材料

skill/skill 包含四个通用验证技能，skill/zynq_skill 包含 Zynq SDT 驱动迁移技能。它们的脚本可以直接运行；自动发现/安装 skill 时使用导出副本中的 SKILL.md。

```bat
python skill/skill/verify_all.py --include-dpd
python skill/zynq_skill/zynq-sdt-migration/scripts/verify_bundle.py
```

## 结果与复现边界
data 目录保留上传包的实测采样和 metadata。
\build\reports 记录各项检查报告

## 包完整性自检

```bat
python -B tools/verify_package.py
```

检查文件名、Python 语法、PL 输入路径和原有二进制校验和，不打开串口。
