# 黄金参考、定点与限幅核对

## 适用范围

RTL/HLS 滤波、通信、图像、控制或小型神经网络的多通道数值采集。只需参考与实测 CSV；通用比较器不绑定 DPD、PYNQ 或板卡。DPD 重算案例额外需要 NumPy。

## 使用方法

在 `skill/` 目录执行一个不涉及 DPD 的两通道例子：

```text
python fpga-golden-check/scripts/golden_check.py --capture fpga-golden-check/assets/capture.csv --reference fpga-golden-check/assets/reference.csv --contract fpga-golden-check/assets/contract.json --output out/golden_demo.json
```

返回 0 为比较通过、1 为数值不一致、2 为输入契约无效。修改契约的列名、位宽、区间 `[start, stop)`、偏移与容差即可换题目。关系固定为 `capture[n]` 对 `reference[n+offset]`。`preclip_columns` 可选，值必须已换算成**最终整数输出单位**，不能直接填写未缩放累加器。

脚本不会自动搜索偏移或归一化。先按 skill.md 推导；若扫描延迟，将校准区与验证区分开，不能把挑出的最低误差当作独立验证。

复跑本项目沉淀的真实采集案例：

```text
python -m pip install -r requirements-dpd.txt
python fpga-golden-check/cases/dpd/replay_case.py --output out/dpd
```

会重新计算，不能只读取已保存的 PASS。案例内输入来自合作方提供的三份 CSV；本轮未操作板卡。

## 已验证效果与经验来源

- DPD 案例：同参数定点重算，有效区 976 点、1952 个标量全部一致；16 个 Q 路端点均由最终累加器越界解释。
- 第 5 非线性分支另有 58 次中间饱和；只做浮点计算并在末尾 clip，会错误地认为硬件数值不对。
- 输入中心偏移为 +1，首尾合计 48 点没有完整上下文；不能把所有 1024 点都列为已通过。
- 新通用两通道例子及故意破坏参考/偏移/输入的回归测试，见根目录验证报告。

原观察与源码定位记录在 `references/lessons.md`。这是本批数据上的结论，不是算法正确性的全输入证明。

## 失效条件

没有黄金参考或节点/采样顺序不明时只能给诊断，不能判定正确；偏移随时间漂移、丢点、变采样率需要先修复数据契约。超过 53 位的整数不能使用当前 binary64 比较器做逐位精确比较。端点可能是合法输入值，缺少限幅前节点不能把它当作溢出证据。新的 DSP 算法必须替换 DPD 特例，浮点容差也必须由精度预算决定。
