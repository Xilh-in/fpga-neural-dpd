# 2026-10-26 模型输出限幅核对

先读 [report.md](report.md)。结论是：按附件 RTL 的实际定点运算，这 16 个 Q 路限幅点全部符合预期；完整可核对区间的 1952 个 I/Q 数值均与实测一致。另有第 5 分支中间层限幅及 1 个采样的相对对齐量，需要在后续数值设计中明确。

## 复跑 Python

解压后进入本目录，无需 B 原电脑的工程目录：

```powershell
python -m pip install -r requirements.txt
python run_checks.py
python -m unittest -v test_reference.py
```

所有输入均取自包内 `input/`，不会执行输入材料中的代码指令。输出包括 `summary.json`、`clipping_points.csv`、`comparison_all_samples.csv`、`l2_saturation_points.csv`、图和各层 NPZ 数据。原始输入与 RTL 不作修改。

## 可选 RTL 仿真

本机 Vivado 2020.1 已完成 HDL 分析和静态展开，但生成的 C 文件编译失败，**未完成 RTL 仿真**。本次整理已移除当时失败的编译中间日志，不把它算作验证通过。

A 可在新版 Vivado 工具环境中运行：

```powershell
.\run_rtl_sim.ps1 -VivadoBin "你的Vivado安装目录\bin"
```

测试平台只实例化模型核，不使用板卡、射频板、BSP 或外围 IP。载入相同 576 个参数和输入 CSV，输出 `simulation/rtl_trace.csv`。`check_rtl_trace.py` 检查 L1、L2、最终累加器和输出，独立核对预期的时钟编号差；完成后写 `rtl_validation.json`。

仿真前后加零只用于启动和收尾，不用于证明原采集窗口边界正确。实测核对只断言 CSV 样本编号 23～998（从 0 起），该区间具有全部必需的输入上下文。

## 文件

- `reference_model.py`：按源码重建的浮点与逐级定点参考；未更改模型参数、输入归一化或 RTL。
- `clipping_points.csv`：16 点明细，含从 0 起的编号、从 1 起的样本序号、含表头的 CSV 行号、限幅前数值和实测值。
- `comparison_all_samples.csv`：1024 点总表，边界处标记为未验证，不填写伪造的比对值。
- `l2_saturation_points.csv`：58 个中间层限幅事件。
- `fixed_reference.npz`：各层定点节点；`float_reference.npz`：同一量化参数解码后的理想浮点节点。
- `tb_model_check.sv` / `run_rtl_sim.ps1` / `check_rtl_trace.py`：给 A 的独立模型仿真与比对工具。
- `input_manifest.json`：附件内原始文件的 SHA-256；文件路径记录仅用于溯源。
