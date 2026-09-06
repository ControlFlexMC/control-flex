> [English](release-notes.md)

## Control Flex 0.8.7

这个版本是一次重大改动，目标是让 Control Flex 能适配更多种类的模组。虽然我已经尽力让现有的本地配置继续可用，但仍有可能出现部分旧版本的设置失效的情况。如果发生这种情况，我先在此致歉 —— 大多数问题都可以通过重新配置受影响的按键来解决。

### 功能特性

*   Overlay 相位 —— 当交互式 HUD（法术轮盘、径向菜单等类似 overlay）打开时，使用独立的控制器绑定，与游戏界面和背包界面分离。
*   模组适配中心 —— 按模组设置 Screen / Overlay 规则，包括摇杆模式（radial path、光标速度、显示/隐藏光标）。
*   社区配置仓库 —— 添加远程源后同步、浏览、预览并应用共享的兼容配置。本地配置也可以导入与导出。
*   虚拟键盘与鼠标 —— 可在任意层把手柄按键映射为真实键盘与鼠标键（包括 Shift、Page Up/Down、Escape 与滚轮）。
*   容器 Slot 导航 —— D-Pad 在背包与容器格子之间跳跃光标。左摇杆仍可自由移动光标。
*   按键映射总览围绕七层重新设计（Main、Shift 1–4、Screen、Overlay），外加一列键盘/鼠标。
*   从手柄（Back + Start）或键盘（F9）打开设置。径向菜单 1–5 注册为 Control Flex 的按键映射。
*   现有的 0.8.6.x 配置在首次启动时自动迁移（profiles、兼容文件与客户端设置）。原文件复制到 `config/controlflex/backup/` 下。

### 修复

*   Fabric 上 JEI 的 Show Recipe / Show Uses 现在可从手柄触发。
*   修复与 simplyusekey 同载时的崩溃（`releaseUsingItem` mixin 冲突）。
*   修复 NeoForge 上用 L1/R1 切换快捷栏时立即崩溃（`MouseScrollingEvent` 构造函数不匹配）。
*   修复手柄断连或拔插后不被识别的问题（包括 Xbox 无线适配器 / 接收器重连）。

### 调整

*   Overlay 默认值现在跟随游戏内布局（移动、视角、攻击、使用、跳跃、滚轮），打开 overlay 感觉像在玩游戏而不是开箱子。
*   滚轮可在每一层绑定。轻按滚动一格；按住每 100 ms 重复一次（`virtualWheelRepeatMs`）。
*   Slot 导航默认绑定到 D-Pad。JEI Show Recipe / Show Uses 改到 RT + D-Pad，避免与 Slot 跳转冲突。
