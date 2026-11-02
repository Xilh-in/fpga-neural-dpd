# Zynq 裸机 no-OS 的 SDT 迁移技能包

本目录只包含一项技能 `zynq-sdt-migration`。它面向将 Zynq-7000 standalone 软件统一到 Vitis 2025.2 SDT 平台时出现的接口差异和初始化故障。

## 内容与入口

| 文件 | 用途 |
|---|---|
| [skill.md](zynq-sdt-migration/skill.md) | AI 助手的执行入口，规定证据收集、排查顺序和输出要求 |
| [迁移指南](zynq-sdt-migration/references/migration_guide.md) | 开发者操作步骤、适配代码、失败案例、自我纠错过程和失效条件 |
| [提示词模板](zynq-sdt-migration/references/prompt_template.md) | 将技能用于其他项目时的调用方法 |
| [检查脚本](zynq-sdt-migration/scripts/check_spi_contract.py) | 检查逻辑总线编号、SDT 查找参数类型和硬件基地址的配置契约 |
| [验证记录](zynq-sdt-migration/references/validation.md) | 软件检查结果、板测证据及尚未覆盖的范围 |
| [结果模板](zynq-sdt-migration/references/result_template.md) | 记录另一项目的定位依据、修改和验证结论 |

脚本只读取配置和可选 BSP 头文件，不修改工程、不连接串口、不启动 Vivado/Vitis。它检查使用者提供的配置是否自洽，不自动证明实际 C 源码已经采用该配置。

## 环境与快速开始

脚本依赖 Python 3.10 或以上版本的标准库，不需要额外 pip 包、GPU 或板卡。已经配置好的 Python 环境可直接使用。

进入本目录后，检查正确的示例配置。

```bat
python zynq-sdt-migration/scripts/check_spi_contract.py --config zynq-sdt-migration/examples/spi_mapping_valid.json
```

正常退出码为 `0`，JSON 中 `status` 为 `PASS`。再执行故意设置错误的示例。

```bat
python zynq-sdt-migration/scripts/check_spi_contract.py --config zynq-sdt-migration/examples/spi_mapping_invalid.json
```

预期退出码为 `1`，报告包含 `BUS_ID_OUT_OF_RANGE`。这是预期检出错误，不是脚本运行故障。

执行全部软件自检。

```bat
python zynq-sdt-migration/scripts/verify_bundle.py
```

该命令检查包内引用、技能入口、示例 CLI 行为和单元测试。详细输出见 [验证记录](zynq-sdt-migration/references/validation.md)。软件自检不代替板上验证。

## 用在自己的项目上

1. 阅读迁移指南第 1、2 节，确认平台与驱动结构符合条件。
2. 复制 `spi_mapping_valid.json`，按实际 no-OS 实现填写最大总线编号、所选编号、各编号与控制器基地址的对应关系、SPI 输入时钟和当前查找参数类型。
3. 从实际编译命令确认 `sdt` 的取值，不能仅根据工具版本推测。
4. 执行配置检查。若需核对实际生成的基地址宏，额外提供 BSP 头文件。
5. 将技能入口、实际源码、BSP 文件和错误日志交给 AI 助手，或手动按迁移指南执行。
6. 根据输出完成最小修改，并记录一次实际编译和板上初始化结果。

带 BSP 核对和报告文件的调用示例。尖括号中的内容是需替换的路径。

```text
python zynq-sdt-migration/scripts/check_spi_contract.py --config <your_config.json> --bsp-header <xparameters.h> --report <spi_contract_report.json>
```

基地址宏可使用直接整数定义或简单宏别名。复杂表达式、条件编译选择及完整预处理应由实际 C 工具链核对，脚本遇到无法解析的宏会报出限制，不会猜测数值。

退出码约定如下。

| 退出码 | 含义 |
|---|---|
| 0 | 配置静态检查通过 |
| 1 | 配置或可解析的 BSP 宏存在冲突 |
| 2 | 文件、JSON、输入格式或脚本支持范围问题 |

## 适用范围和验证依据

已验证案例使用 `xc7z100ffg900-2`、Cortex-A9 standalone 和 Vivado/Vitis 2025.2。修复 SPI 总线编号与 SDT 基地址混用后，平台及射频器件初始化成功，TX/RX 本振均读回 800 MHz。

相关工作围绕 JESD 系统的软件版本兼容与平台统一展开。技能中的 PS 驱动适配方法不依赖 JESD 协议，也不证明 JESD IP 可以任意跨版本替换。

可复用对象包括采用相同 no-OS 驱动结构的传感器、数据转换器和通信控制软件。

## 比赛提交说明

将解压得到的整个 `skill` 目录放入提交工程。`skill/readme.md` 是人工阅读入口，`zynq-sdt-migration/skill.md` 是 AI 执行入口；普通 Markdown 阅读器也能阅读全部内容。

目录组织依据 AMD 指南第 3.3.5.2 节。该指南允许提示词工作流、案例模板、校验脚本和踩坑清单等形式。`skill.md` 是本包为方便 AI 复用增加的入口，不是声称赛方强制规定的文件名。

提示词模板是本次整理得到的可复用模板，板测摘录来自已提供的实际输出。完整原始对话仍应由参赛队伍另行导出，放入设计报告的大模型协作材料中；包内案例叙述不冒充原始逐字对话。

本包只包含一项驱动迁移技能。模型训练、预失真效果、时序优化、IP 授权和完整工程构建流程不纳入该技能的已验证范围。
