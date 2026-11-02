# 技能包验证范围

日期：2026-10-27。

| 验证项 | 本轮结果 | 证据与限制 |
|---|---|---|
| 四个 skill.md 的规范检查 | 通过 skill-creator quick_validate | 命名/frontmatter 合法，不等于行为已全部验证 |
| Python 主技能单元检查 | 29 项通过，13 项可选 PYNQ 测试跳过 | 覆盖正确值、故意改错、错误偏移、NaN、短包、卡高/卡低、器件/CPU/OS、篡改与新 cwd |
| 通用 CLI | 黄金比较、mock IO、Zynq 平台核对通过 | 默认不执行 PYNQ，均不访问硬件 |
| DPD 重计算 | 976 点/1952 标量精确一致，16 个最终饱和，58 次 L2 饱和 | 合作方提供的采集数据；边界 48 点不验证，模型重算需要 NumPy |
| 通用 C 模板 | Clang 3.9 编译为 LLVM IR 并模拟执行通过 | 回调替身，含完整/短包、状态卡高卡低、容量拒绝；非 PS BSP 或板级验证 |
| 独立阅读者使用（历史扩展） | 两套 PYNQ 合成配置通过，越界配置拒绝 | 是上一版可选扩展记录，不是本板运行环境；已移至 extensions/ |
| 本包链接与独立解压 | 最终执行结果见 evidence/package_validation.json | 修正版默认包不含 PYNQ 扩展，主流程和 DPD 从另一个 cwd 执行 |
| 本板资料与当前工程 | XC7Z100 / Cortex-A9 / standalone 一致 | 见 evidence/board_audit.json 和 actual_zynq_project_check.json；不是实物检测或构建证明 |
| PYNQ 下载、MMIO、跨板卡 | 不属于本项目，NOT_RUN | 默认不提交扩展；若另有真实 PYNQ 项目才另行验证 |
| Vitis 2025.2 构建、DPD 整板验证 | 本轮 NOT_RUN | 不用历史主机检查冒充本轮硬件结果 |

本包的工作流是从项目经验重新整理的提示词，不声称已测得跨模型稳定成功率。没有生成资源/时序优化的虚假数值，也没有为未运行的仿真或硬件检查给出 PASS。

板卡审查后主技能更正为 Zynq 裸机，历史 35 项含 PYNQ 的结果存于 evidence/history/，不能当作本版默认测试数量。当前默认 42 个被发现的测试中实际执行 29 个，另外 13 个可选扩展测试明确跳过。

复跑方式：`python verify_all.py`；安装 requirements-dpd.txt 后加 `--include-dpd`。可选 DPD 未执行时报告 SKIPPED；真实硬件项目始终另标 NOT_RUN。已保存的 evidence/validation_results.json 是本次运行证据，不取代接收方重新执行。
