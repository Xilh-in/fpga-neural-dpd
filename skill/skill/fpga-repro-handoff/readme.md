# 可复现交付与陌生目录检查

## 适用范围

把参考模型、脚本、测试或工程交给另一台电脑/队伍时使用。工具仅需 Python 3.11 标准库，不依赖本队仓库路径、Git 服务或 FPGA 工具版本。

## 使用方法

在 `skill/` 目录运行项目无关的最小例子：

```text
python fpga-repro-handoff/scripts/package_check.py pack fpga-repro-handoff/assets/demo_project out/demo.zip
python fpga-repro-handoff/scripts/package_check.py smoke out/demo.zip -- python main.py
```

`pack` 生成相对路径清单与 SHA-256；ZIP 放在源目录之外。`verify root` 校验已解压文件，`smoke ZIP -- command` 则新建临时目录，验证后执行明确指定的命令。ZIP 中的配置不能自行决定要执行什么。

打包实际项目时，把 smoke 入口和测试夹具都纳入 source，先用 `python verify_all.py` 检查本技能包。C/EDA/PYNQ 运行时按接收方环境显式提供，不写 B 机器的默认路径。

## 已验证效果与来源

首版 DPD 包在 B 原目录可运行，但 A 单独解压后，部分测试仍寻找 B 的原始源码目录，补齐目录才通过。修正版把 8 个参考输入放进包、显式指定可选编译器，并在禁止读取原 ps/pl/Python/交付目录的情况下验证默认检查及 C 模拟通过。

这是实际反馈推动的修复，不是最初交付就已经可复现。当前通用脚本另行验证新目录运行、文件破坏检测和不安全路径拒绝。实际记录摘要见 `references/lessons.md` 和根目录 evidence。

## 失效条件

新 cwd 不等于干净系统：系统 Python 包、EDA 安装、操作系统和绝对路径仍可能可访问。此脚本不是沙箱，不能证明跨操作系统/跨器件成功。哈希清单不是签名，不证明来源可信；bit/XSA/ELF 同名或存在哈希，也不证明同一硬件版本。板测、时序、资源数据必须来自真实报告，不由本脚本推断。长期卡死需由 subprocess 超时终止，不能用失败重试掩盖环境缺失。
