---
name: zynq-baremetal-bringup
description: Cross-check Zynq-7000 board identity and standalone Cortex-A9 PS/PL bring-up against board manuals and project metadata. Use for Vitis bare-metal platform handoff and tutorial conflicts; do not treat PC Python control as a PYNQ runtime.
---

# Zynq-7000 裸机 PS/PL 联调

先读 [readme.md](readme.md) 和 [references/board_audit.md](references/board_audit.md)。Zynq 是芯片/硬件平台，PYNQ 是可选的软件框架；当前项目采用前者的 standalone 开发路径，并未采用后者。

## 工作流

1. 对照实物标识、板卡手册、原理图、已有工程 Part，确认器件、封装、速度级和板卡版本。有冲突先记录，不照搬其他板卡的器件、DDR/MIO 或约束。
2. 明确 PS 应用位置和运行环境：板上 Cortex-A9 的裸机 C/ELF 与电脑上的 Python 上位机是两层；不能因用了 Python 就写成板上运行 PYNQ/Jupyter。
3. 从当前 PL 导出配套 XSA，由接收方在实际 Vitis 版本创建平台/BSP。确认 CPU、standalone domain、UART 与时钟；应用补丁与平台生成文件分别管理。
4. 依次检查启动日志、计时器/状态等待退出、可安全回读寄存器、已知数据和模型参数。串口/AXI 的每一步均记录长度、单位、预期与实际结果，不以非零数据替代数值正确。
5. `scripts/platform_check.py` 只读检查老式 .xpr/.prj 与配置的一致性。新版 Vitis 元数据格式不同则改适配器或人工核对，不能解析失败后自动猜 CPU 或 OS。

## 提示词模板

> 对照实物型号、板卡手册、原理图和现有 XPR/PS 元数据确认 Zynq 平台。区分板上裸机 C、PL 与电脑 Python。列出 bit/XSA/BSP/ELF 的生成与对应关系，定位进入命令循环之前的阻塞。若教程型号冲突，以交叉核对证据说明取舍；未完成编译或板测的部分保持未验证，不引入 PYNQ Overlay 工作流。

通用性来自平台核对与阶段化流程，RK7100 参数只在 assets 的板型 profile 中；换板必须核对自己的 profile、约束和外设。
