# Zynq-7000 裸机平台核对

## 适用范围

Zynq-7000、Cortex-A9、Vivado PL + Vitis standalone PS 的工程恢复与交接。当前 DPD 的实际硬件是 RK-ZYNQ7100-F / XC7Z100-2FFG900，工程 Part 为 xc7z100ffg900-2。Python 控制程序在电脑上，通过串口与板上 C 程序通信，不要求板上安装 PYNQ 或 Jupyter。

## 使用方法

在 skill/ 目录执行合成元数据示例：

```text
python zynq-baremetal-bringup/scripts/platform_check.py --profile zynq-baremetal-bringup/assets/rk7100_profile.json --xpr zynq-baremetal-bringup/assets/mock_xpr.xml --application zynq-baremetal-bringup/assets/mock_app.xml --output out/platform.json
```

mock XML 只用于解析测试，不是可构建工程。检查实际旧工程时，把 --xpr 替换为真实 .xpr，--application 替换为真实 .prj。返回 0 表示选定 Part/CPU/OS 与 profile 一致，2 为错误；不会启动工具、改 BSP 或下载板卡。

板级联调前填写共享 templates/board_validation.md。通过这个检查后仍需检查约束、DDR/MIO/时钟、XSA 与 bit 配套、实际 BSP、ELF 和启动方式。应用代码使用的 XUartPs/XTime 等 API 须以实际 BSP 为准，寄存器编号和字节地址不能混用。

## 已验证效果及来源

本轮交叉核对了用户提供的板卡手册第 4～5 页、FPGA 开发教程第 8 页、现有 PL .xpr 和 PS .prj：均支持 XC7Z100 / Cortex-A9 / standalone 路径。Vitis 教程第 14 页有一行写 XC7Z020CLG484-2，但同页截图和后文选择 xc7z100ffg900-2，不能只复制那一行。

本地环境搭建 TXT 只让读者参考正点原子 Z100 的 2023.1 教程；这是学习参考，不代表该板等于另一款 Z100，也不覆盖项目已约定的 A 使用 2025.2。资料目录源码压缩包目前是 .downloading 文件，未将其当成可用官方例程或复现证据。

验证包括现有工程的只读元数据检查和正常/错误器件/错误 CPU/错误 OS 等合成回归。手册核对不等于确认实物丝印，元数据一致也不等于 2025.2 编译或板测通过。

## 失效条件

不适用于 Zynq UltraScale+ 的 A53/R5、Versal、Linux/PetaLinux 或 PYNQ 镜像流程。新版 Vitis 平台不使用该 .prj schema 时，脚本会拒绝或需要显式改适配器。不得从板名推断具体 DDR、MIO、UART 引脚或 BOOT 开关；这些必须按实物板版本和原理图确认。
