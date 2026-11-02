# 独立阅读反馈的处理

forward_review.md 保留第一次独立检查的原始结论，不修改其历史表述。该检查仅获得 PYNQ 子技能所需材料，没有获得预期答案或本项目前面的分析结论。

发现的问题：当时引用了尚未放入成品包的板测模板，并用“根目录”造成定位歧义。

处理：新增 skill/templates/board_validation.md；references/api_and_limits.md 改用 `../../templates/board_validation.md` 明确链接，并说明单独抽取子技能时应携带模板。最终链接检查会解析包内全部 Markdown 相对链接，模板存在且不会跳到作者仓库其他目录。

后续板卡核对修正：上述为上一版历史处理。PYNQ 扩展现移至 extensions/，其模板改为 templates/pynq_board_validation.md，链接相应调整；默认主包采用 Zynq 裸机板测模板，不包含该 PYNQ 扩展。

验证范围区分：独立检查实际执行了两套离线配置和一个越界配置；完整 FakeOverlay/FakeMMIO 保护项由本轮自动化测试另行覆盖。两者均未进行真实 PYNQ 硬件操作。
