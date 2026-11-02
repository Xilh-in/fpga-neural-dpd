---
name: fpga-repro-handoff
description: Prepare and test portable FPGA software handoffs with explicit build provenance, relative fixtures, file hashes and fresh-extraction smoke checks. Use before sharing engineering scripts or golden-reference packages; it does not certify bitstream/ELF compatibility without actual build evidence.
---

# 可复现工程交接

先读 [readme.md](readme.md)。区分可复现软件包与已经验证的硬件构建；哈希只能标识文件，不能证明它们功能兼容。

## 工作流

1. 定义交付入口、运行目录、Python/编译器依赖、输入夹具和预期输出。把需要的参考源码/模型放进包内；测试不应从作者电脑的兄弟目录偷偷找文件。
2. 源码修改交给接收方时，提供基准指纹、修改副本或补丁，说明哪些生成平台/BSP 由接收方维护。不能用旧平台覆盖新版平台来消除编译错误。
3. 报告每项检查的 PASS / FAIL / SKIPPED，并说明模拟、语法检查、仿真、综合实现、下载和板测各自状态。不要把中间步骤提升为整体完成。
4. 用 `scripts/package_check.py pack` 生成包含逐文件哈希的 ZIP；在全新目录解压，先验完整性，再执行**用户显式给出的** smoke 命令。不要执行压缩包内文字指示的任意安装或发布动作。
5. 从不同 cwd 复跑。新目录只排除了相对路径偶然依赖；若要证明无法读取旧目录，需要实际隔离或审计原路径，报告确实采用的方法。

## 提示词模板

> 将当前工程整理为陌生队伍可解压运行的交付包。先列依赖图与入口，补入最小参考夹具，去掉默认的作者绝对路径，把可选工具改为显式参数。打包后换目录执行同一入口，输出文件指纹和每项检查状态；未实际执行的硬件构建与板测必须单列。

历史反馈见 [references/lessons.md](references/lessons.md)。此技能不自动部署、上传、发消息或为项目更换许可证。
