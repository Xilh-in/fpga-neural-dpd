---
name: zynq-sdt-migration
description: Diagnose and adapt Zynq-7000 standalone no-OS drivers for a Vitis SDT BSP. Use when generated macros or SPI/GPIO/UART and timer APIs change, a build succeeds but peripheral initialization fails, or no-OS bus indices may be confused with BSP base addresses. Trace the active source and return values before proposing minimal edits. Includes a static SPI mapping checker and a validated Vitis 2025.2 case.
---

# Zynq no-OS 的 SDT 迁移

## 目标

依据实际源码和日志定位接口适配问题，交付最小必要修改、验证步骤和结论边界。先阅读 [迁移指南](references/migration_guide.md) 的适用条件，再执行以下流程。

## 1. 收集证据

确认处理器、工具版本、standalone 平台、实际编译文件、条件编译宏，以及下载使用的 ELF、比特流、硬件交接信息和 PS 初始化脚本。

读取当前 BSP 的 `xparameters.h`、设备配置表、实际生效的 `LookupConfig` 分支，以及 no-OS 通用层、平台适配层和应用入口。只补充当前判断确实缺少的文件，避免重复索取整个工程。

保留可运行基线和原始日志。在 [结果模板](references/result_template.md) 中记录依据。

## 2. 追踪设备标识与错误传播

逐层画出参数的传递关系，明确每个整数是逻辑总线编号、设备 ID、寄存器编号还是 MMIO 基地址。

检查 no-OS 对 `device_id` 的范围限制、数组索引和控制器选择。检查 BSP 当前分支接收的参数。不要全局将所有设备 ID 替换成基地址。

确认平台初始化返回值是否被应用检查，GPIO/SPI 操作失败是否继续被报告为成功。优先定位第一个实际失败的调用，不从 PLL 超时文字直接推断外接时钟故障。

## 3. 检查 SPI 配置契约

从实际源码和硬件配置填写 [正确配置示例](examples/spi_mapping_valid.json)，在技能目录执行：

```text
python scripts/check_spi_contract.py --config examples/spi_mapping_valid.json
```

必要时追加 `--bsp-header <xparameters.h>` 核对基地址宏。详细输入和退出码见 [脚本说明](references/script_usage.md)。

把配置检查结果作为辅助证据。明确该脚本不解析 C 调用路径、不选择预处理分支，也不访问硬件；配置自洽不能代替源码核对。

## 4. 提出最小修改

在平台适配层完成逻辑编号与 BSP 查找参数的转换。保留 no-OS 通用层的逻辑编号及其查表语义。多实例时逐项映射，并重新核对输入时钟和选择分支。

清零应用初始化参数和会被 BSP 读取状态的实例对象。增加返回值检查，失败后停止依赖该外设的后续操作。

分别核对 GPIO、UART、计时和延时服务。只使用当前 BSP 提供的宏与接口。头文件替换不能证明计时器运行正常，SPI 修复也不能推广为其他驱动的统一改法。

使用 [迁移指南](references/migration_guide.md) 中的代码作为集成模板，按当前类型和实例调整，不声称模板可覆盖所有版本。

## 5. 选择一次有效验证

根据主要假设选择能区分原因的验证。已有可运行 ELF 时，在硬件、比特流和初始化脚本一致的条件下做一次比较；已有确定的软件范围错误时，先复现并修正该错误。

重新编译并确认下载实际生成的 ELF。板测前从明确的外设状态开始。记录平台初始化返回值、关键芯片状态和最小功能测试，不把单条成功日志作为整个系统通过的证据。

不在缺少板卡时声称完成硬件验证。软件模拟、用户提供的实测摘录与新增本地检查应分别标明。参见 [验证记录](references/validation.md)。

## 6. 输出结果

按以下顺序报告：

1. 已确认的原因和对应源码或日志依据。
2. 文件、函数、修改内容和影响范围。
3. 实际执行过的检查，以及返回值或输出。
4. 尚未确认的假设和下一项必要验证。
5. 复用条件与不适用情形。

引用 [提示词模板](references/prompt_template.md) 组织新任务，使用 [结果模板](references/result_template.md) 保留记录。

## 约束与完成条件

只在证据支持的范围内修改。不要通过任意改时钟频率、删除范围检查或持续增大超时来掩盖初始化失败。

保持项目历史和验证记录可核实。不要将模板示例写成原始交互，不补写未执行的实验和跨板卡成功率。

获得修改授权时，完成条件是定位并修复首个可复现问题，提供相应实际验证和边界说明。若任务限定为只读诊断，以原因定位、拟议修改和静态验证边界作为本次完成条件，不擅自修改或下载程序。模型数值正确性、射频补偿效果及 JESD IP 跨版本兼容不属于本技能的默认完成声明。
