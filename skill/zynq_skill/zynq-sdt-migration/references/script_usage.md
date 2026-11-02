# SPI 配置契约检查脚本

## 检查对象

`scripts/check_spi_contract.py` 检查显式声明的配置。它不自动解析 no-OS C 源码，不自动判定实际编译分支，也不执行硬件访问。使用者应先阅读源码，再如实填写配置。

脚本支持多控制器的编号和地址映射。重复编号、重复地址会报错。若某项目有意让多个逻辑设备共享一个控制器，应按“控制器编号”填写此表，片选和具体从设备另行配置。

## 配置字段

| 字段 | 含义 |
|---|---|
| `schema_version` | 固定为 1 |
| `sdt` | 实际编译命令是否定义 SDT，必须使用 JSON 布尔值 |
| `max_bus_id` | 当前 no-OS 实现允许的最大总线编号，本案例为 8 |
| `selected_bus_id` | 传给 no-OS 通用层的逻辑编号 |
| `lookup_argument_kind` | SDT 示例使用 `base_address`，非 SDT 示例使用 `device_id` |
| `buses` | 当前项目的控制器映射列表 |
| `logical_id` | 控制器的 no-OS 逻辑编号 |
| `base_address` | 非零、32 位、按 4 字节对齐的控制器基地址 |
| `base_address_macro` | BSP 中对应的基地址宏，提供 BSP 头文件核对时必填 |
| `input_clock_hz` | 当前控制器输入时钟的正整数 Hz 值，需来自实际 BSP |

数字可使用 JSON 整数，或十进制、十六进制数字字符串。布尔值不能代替编号。脚本只检查时钟为正，不验证时钟树或 SPI 分频计算。

本案例的 BSP 原生接口接受查找参数 `0`，表示选择配置表的首实例。配置中的 `base_address` 仍要求填写实际非零地址，这是显式控制器映射的契约要求，不是在声称 BSP 原生 API 禁止参数 `0`。

`lookup_argument_kind` 的判断针对本技能描述的 BSP 接口模式。若目标 BSP 不符合该约定，应先人工分析并调整适配方法，不通过伪造配置来获得 PASS。

## 命令

在技能目录中执行。

```text
python scripts/check_spi_contract.py --config examples/spi_mapping_valid.json
python scripts/check_spi_contract.py --config examples/spi_mapping_invalid.json
python scripts/check_spi_contract.py --config examples/non_sdt_mapping_valid.json
```

同时核对生成的 BSP 宏与 no-OS 编号上限。

```text
python scripts/check_spi_contract.py --config examples/spi_mapping_valid.json --bsp-header examples/example_bsp.h --no-os-spi-header examples/example_no_os_spi.h
```

将上述两个示例头文件替换为实际工程对应文件后，脚本可检查配置与头文件是否一致。包内 `example_bsp.h` 和 `example_no_os_spi.h` 是明确构造的软件夹具，不是完整 BSP 或第三方驱动源码。

保存报告时指定 `--report`，并确保输出文件的父目录已存在。

```text
python scripts/check_spi_contract.py --config examples/spi_mapping_valid.json --report spi_contract_report.json
```

无 `--report` 时仅向标准输出写结果。配置不通过仍可生成 FAIL 报告。文件或输入格式错误会向标准错误输出 JSON，并返回 2；这类错误不生成报告文件。

## 退出码与结果解释

- `0` 和 `PASS` 表示声明的配置满足静态检查。
- `1` 和 `FAIL` 表示配置存在可定位的冲突。
- `2` 和 `INPUT_ERROR` 表示文件、格式、宏解析或支持范围问题。命令行选项用法错误也返回 2，并显示 argparse 的用法说明。

结果中固定包含 `hardware_access=false` 和 `source_call_path_verified=false`。这两个字段防止把配置检查结果误用为板测或实际调用路径通过的证明。

常见错误码如下。

| 错误码 | 处理方法 |
|---|---|
| `BUS_ID_OUT_OF_RANGE` | 检查 no-OS 编号是否误填为 MMIO 基地址 |
| `UNMAPPED_BUS_ID` | 为所选逻辑编号提供对应控制器映射 |
| `LOOKUP_KIND_MISMATCH` | 核对实际 SDT 分支与查找参数类型 |
| `DUPLICATE_BUS_ID` | 修正一号多映射的配置 |
| `DUPLICATE_BASE_ADDRESS` | 确认控制器编号是否被重复配置 |
| `INVALID_BASE_ADDRESS` | 填写显式的非零 32 位控制器地址 |
| `UNALIGNED_BASE_ADDRESS` | 核对地址抄录及寄存器访问宽度 |
| `INVALID_INPUT_CLOCK` | 从实际 BSP 核对输入时钟 |
| `BSP_BASEADDR_MISMATCH` | 处理配置与 BSP 宏值不同的问题 |
| `NO_OS_BUS_LIMIT_MISMATCH` | 按实际 no-OS 头文件更新编号范围 |

## 宏解析边界

支持对象宏的直接十进制或十六进制整数、普通整数后缀、简单外层括号、注释和递归别名。不支持运算表达式、八进制、函数宏和条件编译求值。

同一宏存在不同定义时会拒绝猜测当前分支。缺少宏、别名成环或遇到不支持的表达式时返回 INPUT_ERROR。此时应使用目标 C 工具链预处理生成当前分支的宏定义，或人工核对，而不是删掉错误检查。
