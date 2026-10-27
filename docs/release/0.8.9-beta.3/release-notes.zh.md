> [English](release-notes.md)

# Control Flex 0.8.9-beta.3

**新特性：**
- 延迟与长按触发分层 —— DELAY_PRESS / DELAY_HOLD / LONG_HOLD，新增全局 `delayPressMs` 边界（点按 = 闪避、按住 = 潜行，短点按不闪误触）
- `delete_text` 动作取代虚拟退格键 —— 直接删除聚焦输入框内的字符，不再误触发挂在退格键上的模组；Profile 升级到 v6

**修复：**
- 「按住打开」的模组菜单（Effortless Building、MineMenu）在进入 GUI 时不再闪烁关闭
- 1.12.2：mixin 容错恢复 —— 带其它 MixinTweaker 的整合包（All the Mods 3、Enigmatica 2、Omnifactory）可正常启动，模组不再静默失去全部 mixin
- 屏幕键盘：键帽文字按键帽格子定尺寸（手机横屏可读）；卡片绘制在模态宿主（径向菜单 Edit Slot）之上
