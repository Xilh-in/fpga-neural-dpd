# Zynq-7000 裸机 DPD 项目协作技能包

版本：2026-10-27。目录按选题指南 3.3.5.2 提交；这是可单独解压使用的技能集合，既可人工使用，也可把各项 skill.md 提供给大模型读取。不要求安装 Codex 插件，不要求本队原工程路径，不会自动连接或配置板卡。

## 本项目实际平台

**板卡为 RK-ZYNQ7100-F，芯片 XC7Z100-2FFG900（工程 Part：xc7z100ffg900-2），PS 为双核 Cortex-A9，当前应用运行于 standalone 裸机环境。** PL 用 Vivado，板上 C/ELF 用 Vitis；Python 上位机运行在电脑，通过串口控制板卡。

Zynq 是芯片平台，PYNQ 是可选 Python/Linux 软件框架，两者不是同一概念。当前 DPD 没有使用 PYNQ Overlay/Jupyter，不能因为上位机用了 Python 就称为 PYNQ 项目。上一版把 PYNQ 扩展列为第四项主技能容易造成误解，本版已纠正。资料核对见 [板卡审查](zynq-baremetal-bringup/references/board_audit.md)。

## 陌生队伍从这里开始

准备 Python 3.11，在本目录运行：

```text
python verify_all.py
```

通用脚本和离线模拟只用标准库，无需 Vivado、Vitis、PYNQ、串口或板卡。复跑 DPD 真实采集案例时再安装可选 NumPy：

```text
python -m pip install -r requirements-dpd.txt
python verify_all.py --include-dpd
```

报告写入 `out/validation_results.json`，清楚区分 PASS、FAIL、SKIPPED、NOT_RUN。默认只验证 Zynq 裸机主技能；PYNQ 测试明确跳过，历史扩展证据不能计为当前平台的硬件结果。

## 每项的适用范围、用法与失效条件

| 技能与入口 | 可用在什么题目 | 最短使用方式 | 已验证效果 | 何时失效/不能声称什么 |
|---|---|---|---|---|
| [fpga-golden-check](fpga-golden-check/readme.md) | 任意可导出多通道 CSV 的 RTL/HLS 数值核对 | 提供 capture/reference/contract 给 scripts/golden_check.py；更换列、位宽、窗口和偏移 | 通用示例及错误注入；DPD 有效区 976 点、1952 个数精确一致，16 个最终饱和有越界证据 | 无参考、采样漂移、上下文缺失、整数精确度超过 53 位；不能把端点命中自动当溢出 |
| [fpga-bounded-io](fpga-bounded-io/readme.md) | PS/MCU 启动 done 等待、串口二进制收发 | scripts/mock_demo.py；传入 transport/clock，C 用 deadline_io.h 回调模板 | 分包/短包/错误 ACK/卡高卡低；通用 C 回调模拟；来源项目 v2 在短包时不提交 RAM | 底层调用不返回、计时器停、协议无重同步、缓冲不足；不提供未知硬件的自动恢复 |
| [fpga-repro-handoff](fpga-repro-handoff/readme.md) | 脚本/参考/源码补丁跨电脑交接 | package_check.py pack；smoke ZIP -- 显式命令 | 新目录运行、文件篡改检测、路径拒绝；源于 A 解压首版失败后的实际修复 | 新 cwd 不等于干净 OS/跨工具版本；哈希不证明 bit/XSA/ELF 兼容 |
| [zynq-baremetal-bringup](zynq-baremetal-bringup/readme.md) | Zynq-7000 Cortex-A9 裸机 PS/PL 恢复与交接 | 板型 profile 对照 XPR/.prj；按手册核对 XSA/BSP/ELF 和 UART | 本板资料与现有工程一致；能拒绝错误 Z020、CPU、OS 和缺失型号 | 不支持 A53/R5、Linux/PYNQ 或不同元数据格式；不凭 XML 一致就宣称板测通过 |

每项包含 skill.md（大模型入口）、readme.md（人类用法）、references（失败来源与边界）、scripts/assets（可执行工具或模板）。共享 templates 需要随整个 skill/ 一起携带；只抽取子项时携带其引用的模板。readme.md、skill.md 为约定入口名，其他新建文件名均为英文小写、数字、下划线或连字符。

## 经验确实来自哪里

[evidence/experience_log.md](evidence/experience_log.md) 逐项记录“观察/失败 → 修复 → 证据 → 推广边界”：

1. Python 有 Para_Write/Para_Read，PS 命令表不配套：提炼接口契约与分层定位。
2. 只给主机加超时，仍不能解除 PS 的启动等待或半包阻塞：提炼双端期限、整包暂存和失败返回。
3. A 反馈首版包要补 B 原目录才能测试：提炼包内夹具、不同工作目录与阶段化报告。
4. 模型 Q 路 16 点限幅：通过逐级定点和 +1 中心偏移核对，进一步发现 L2 中间饱和。
5. 旧工具生成 C 编译失败：明确分析/展开、仿真、构建、板测是不同状态，不用成功的中间步骤掩盖失败。

这里的提示词是基于这些已完成协作整理的新模板；脚本/案例已复测，但没有进行多模型、多随机种子的稳定成功率评测。不得凭模板存在就宣称跨模型稳定性已经验证。

## 验证证据

- [evidence/validation_results.json](evidence/validation_results.json)：本轮通用单元检查、CLI 与可选 DPD 回放的实际输出。
- [evidence/project_validation_excerpt.json](evidence/project_validation_excerpt.json)：旧项目 v2 的 C 模拟和旧 BSP 语法检查摘要，未运行的新版构建/板测保持未运行。
- [evidence/dpd_capture_audit.json](evidence/dpd_capture_audit.json)：本批合作方采集数值的核对摘要。
- [evidence/forward_review.md](evidence/forward_review.md) 与 [evidence/review_resolution.md](evidence/review_resolution.md)：历史可选 PYNQ 扩展的独立阅读测试，不是本板 PYNQ 验证。
- [evidence/c_template_check.json](evidence/c_template_check.json)：通用 C 模板实际编译/模拟执行结果。
- [validation.md](validation.md)：本技能集合的最终复测范围，包括独立解压结果。

## 可选 PYNQ 扩展不属于本项目运行环境

本提交包不包含 `extensions/pynq-overlay-contract/`，仅供未来实际 PYNQ 项目参考。它不在默认验证/默认提交包中，也不要求本板安装 PYNQ。只有确有相应运行环境时，才在源码集合中显式使用 `verify_all.py --include-pynq`。目前没有本板 PYNQ 镜像移植或板测证据，不将其作为本队已验证的加分成果。

## 用在自己的题目上

先选一项，把自己的接口、参考和实际失败交给模型，再使用该项的提示词模板。优先修改 JSON 契约和算法适配函数；不要把 DPD 的 576、+1、70144 或寄存器地址变成通用常量。保留原始输入和第一次失败日志，改动后用同一输入重跑，记录不能下结论的项。

可复制的共享模板：

- [接口契约](templates/interface_contract.md)：格式、地址单位、长度、期限、失败恢复。
- [验证报告](templates/validation_report.md)：逐项阶段状态与结论边界。
- [板测记录](templates/board_validation.md)：RK7100/Zynq 裸机 PS/PL 启动、寄存器与数据通路验证。
- [大模型协作记录](templates/llm_collaboration_log.md)：提示词、反馈、自我纠错和证据索引。

`evidence/collaboration_summary.md` 只是本项目过程摘要，不替代作品提交时要求的原始交互记录。完整工程、综合实现报告、上板输出、性能与资源对比仍应放在作品其他目录，不由 skill 包伪造或代替。

## 重新打包

```text
# 将当前 skill 材料随工程提交，打包由工程根目录统一完成。
```

压缩包顶层保留 `skill/`，带逐文件 SHA-256；不打包虚拟环境、缓存或 out 临时输出。完整性校验在解压后对 `skill/` 目录执行：`python fpga-repro-handoff/scripts/package_check.py verify .`。重新运行若改写了 evidence 文件，应重新打包更新清单。

默认还排除 extensions/ 和可选 PYNQ 板测模板。旧的含 PYNQ 主项版本仅为历史产物；当前交付以 Zynq 修正版压缩包为准。
