> [English](changelog.md)

# ControlFlex 0.8.9-beta.3 Changelog

- **版本：** `0.8.9-beta.1` → `0.8.9-beta.3`（`mod_version` 0.8.9-beta.3；`cfx_api_version` 0.9.2 —— 不变；`gamepad_jni_version` 0.9.1 → 0.9.3.1）

这是 0.8.9-beta.1 之上的两个 beta。beta.2 新增延迟与长按触发分层，用真正的 `delete_text` 动作取代虚拟退格键（profile 一步升到 v6），并修复 26.3 的 SDL 输入链路 —— 此前手柄被禁用、RT 删除完全无响应。beta.3 让「按住打开界面」的模组动作在进入 GUI 后继续存活，理顺 1.12.2 的 mixin 配置，并打磨屏幕键盘的尺寸与渲染。

---

## 1. 绑定：延迟与长按触发分层

在点按窗口与长按阈值之间新增第三个全局时间边界（`delayPressMs`），并配套三种触发模式：

- **DELAY_PRESS**：按下时长超过点按窗口后触发一次。
- **DELAY_HOLD**：到达延迟边界即激活，保持到松开。
- **LONG_HOLD**：到达长按阈值才激活，保持到松开。

组合引擎在按住达到 `delayPressTicks` 时，每个按压段发出一次新的 DELAY 事件。阈值不变式为 `tap < delay < long`，因此同一次按压绝不会同时触发 TAP 和 DELAY，中间这一段从「死区」变成「选择」：把延迟贴着点按窗口放就是一个双姿态按键（点按 = 闪避、按住 = 潜行），放宽就是一个三档按键。短点按也不会再在穿过中间带时把「按住」闪出来。

- 点按/长按间隙过窄时按确定性规则处理：加载器先把延迟锚在点按 + 1 tick 再读长按边界，上一个 profile 留下的旧值不可能抬高它；然后长按边界按最小步长抬高，保证三档互不重叠（之后显式设置的 `delayPressMs` 在这对边界内照常生效）。
- 旧 profile 推导为点按 + 1 tick，按压时间线不变。
- 阈值设置页新增第四张卡片、相邻互锁滑条、内容滚动（常见 GUI 缩放下四张卡会溢出）以及窄间隙规则说明；检测面板会记录 DELAY 状态，调参时边界可见。
- 缘起：ParCool 潜行映射帖提出的按住/延迟模式需求。

---

## 2. 绑定：`delete_text` 取代虚拟退格键

旧方案在 GUI 层播种 `key.keyboard.backspace`（`rightTrigger`）并注入物理退格 —— 挂在这个键上的所有模组行为都会跟着触发。新的 `delete_text` 动作直接从当前 Screen/Overlay 聚焦的输入框删除一个字符 —— 直达输入框自己的输入目标，绝不经过 `Screen.keyPressed` —— 没有聚焦输入框时为空操作。按住会连发（10 tick 延迟，之后每 3 tick 一次）。

- `delete_text` 能起作用时（有聚焦输入框）会在当 tick 经 release edge 独占其按键：这些按键上的其它动作与虚拟键鼠槽位都不触发。没有输入框时一切照旧绑定。
- 默认值：GUI 层 `rightTrigger|HOLD`；overlay 层默认为空，除非 RT 空闲。默认填充会在 vkbm 配置段加载后复查占用 —— 保留了旧退格槽位就不会再补默认值。
- 模板移除退格条目，profile version 均为 6。

---

## 3. 配置迁移 → v6

- v4/v5 → v6 **一步到位**。仅存在于 beta 的 v4 → v5 步骤移除；其中的聊天默认值（主层 `dpadLeft` = chat）改由 `ProfileV6Step` 为 v5 之前的来源补齐。
- 出厂退格槽位只在未被修改时清除；用户自定义过的槽位原样保留。
- 序列化新增 `delayPressMs`（见第 1 节）；此前的 profile 推导为点按 + 1 tick。
- 三套模板均为 version 6。

---

## 4. 屏幕键盘：尺寸与渲染

- **键帽内容按格子尺寸排版，不再跟随全局尺寸设置。** 旧规则让键盘和文字同比例放大，把文字钉在键帽约 10% 的高度 —— 手机横屏（宽格）下尤其没法看（96 px 键帽上只有约 0.5 mm 的笔画）。现在 `contentScale = cell / 13`（夹在 0.6–3.0），键帽图标固定占格子的 0.52；浮层键盘与聊天停靠键盘走同一条规则，同一屏幕上观感一致。
- **对齐键帽按实际内容测宽。** Delete / Clear / Done 三个键帽此前用布局里硬编码的标签测词列宽度，绘制时却是绑定标题，列比词宽；而且一份共享缩放让空格键更宽的徽标也参与投票，把四个键帽整体压小三成。现在徽标列按徽标本身测量，词列取最紧键帽剩下的宽度且对所有图标键帽一致，每个词用自己的缩放填满词列，空格不再参与对齐三件套的定档。
- **键盘卡片画在宿主深度之上**（1.7.10 / 1.8.9 / 1.10.2 / 1.12.2 / 1.16.5 / 1.18.2 / 1.19.2 / 1.20.1 / 1.21.1）：径向菜单的 Edit Slot 模态画在 z=500，OSK 卡片在 z=400 而键帽在 z=800 —— 开启深度测试后卡片被模态挡掉而按键仍显示，键盘看起来没有边框。现在键盘层按 overlay 绘制：保存并关闭整层深度，按画家序画卡片、按键与镜像，再原样恢复深度状态。
- 老版本线（1.7.10 / 1.8.9 / 1.10.2 / 1.12.2）：物理鼠标点击不再唤起键盘；拒绝 macOS 的 DEL 字符；Esc 可关闭键盘。

---

## 5. 26.1.2 / 26.2 / 26.3：SDL3、键码与焦点

- **26.x 使用宿主 SDL3。** Minecraft 26.x 自带 LWJGL SDL3，jar 构建时刻意剔除自带副本，但 SDL3Manager 仍向 gamepad-jni 请求 BUNDLED 来源，回退到 `System.loadLibrary("SDL3")` 时指向的 `java.library.path` 与 26.3 存放 native 的目录对不上 —— 于是出现「Minecraft 自己的 SDL 加载正常，手柄却被 no SDL3 in java.library.path 禁用」。现在按宿主选择来源：classpath 上有 `org.lwjgl.sdl.SDL` 用 HOST，否则 BUNDLED，并把选择写入日志。
- **合成 KeyEvent 带上自己的 SDL 键码。** 26.3 把按键事件换成 SDL 语义（`shortcutKey()` 是 SDL 键码，退格 = 8），而所有合成事件只填了扫描码 —— `EditBox.keyPressed` 把绑定的 Delete 当成未知键，键帽和 GUI 层 vkbm 两条路的 RT 删除都因此失灵。现在统一经 `SDL_GetKeyFromScancode` 解析键码。
- **自定义输入框聚焦时认领 SDL text-input 会话（26.3）。** 原版 EditBox 在 `setFocused` 里开会话，我们自己的 `EditTextField` 从没申请过 —— 径向菜单/槽位编辑器、绑定搜索、过滤框全部收不到键盘输入。现在聚焦即以该输入框为属主开启会话，失焦即结束（管理器有属主保护，被别的框接管时不去抢），并上报光标矩形，让 IME 候选窗跟随插入点。
- **26.3 / 26.x 聊天输入框不再被抬两次。** 渲染包装器和 `ChatKeyboardHost.layout()` 都在挪 EditBox 的 Y，429x248 GUI（自适应 guiScale、四行键盘）上输入框落到 y=30 而不是 y=133 —— 直接浮到屏幕顶部。渲染包装器只保留字号变换，移植时丢掉的输入栏背景填充钩子也一并恢复。
- **宿主焦点不在时刷新创造模式搜索**（26.1.2 / 26.2 / 26.3、1.20.1、1.21.1、1.21.11）：创造模式搜索框没有 EditBox responder，OSK 直接写框，`refreshSearchResults()` 永远不跑 —— 字进去了、结果不刷新。现在 OSK 优先走宿主自己的路由，值没被改动才直写字段；绑定的删除/清空/快捷短语也用同一个感知宿主的目标。
- **26.x：** 键盘层锚点从 `GameRenderer#extractGui` 换到 `applyCursor`；26.2 钉在 fabric-api 0.145.6（0.145.5 会坏）。
- **声明的 Fabric loader/API 下限下调**（26.1.2 / 26.2 / 26.3、1.20.1、1.21.1、1.21.11 —— 1.21.11 声明 loader 0.17.3 / API 0.135.1）：下限由 Fabric API 决定而不是我们，现在按真正能跑的最早版本声明并编译。

---

## 6. 版本覆盖与回移植

- **1.16.5**（Fabric / Forge）：模组按键绑定在第一个客户端 tick 重新扫描；KeyMapping 扫描不完整时保留兼容绑定。
- **1.10.2 / 1.12.2**（Forge）：Android 上不再丢手柄滚轮；1.10.2 把 MixinBooter 下限钉在 11.17。
- **1.8.9**（Forge）：注册配置并按 Mixin 注册表给 extras 加门。
- **1.7.10**（Forge）：实体 AABB 改读真实字段而不是 null 桩；GuiSlot 列表从 `drawScreen` 头部滚动；B 关闭 JEI 页面时背包保持打开；系统光标改经 gamepad-jni 的 JNI 入口隐藏 —— JNA 依赖（连同各平台 dispatcher）从 jar 里彻底移除。
- **Android：** 1.7.10 / 1.8.9 / 1.10.2 的手柄光标可以移动了。
- **1.12.2**（Forge）：去掉早期 mixin prepare —— 它在 core plugin 里就准备全部四个配置，早于 FMLDeobfTweaker 安装映射，于是所有引擎（Mixin 0.7.10 Surge、0.7.11、0.8.2、MixinCompat 0.8）都在 prepare 时急切解析目标并失败，整个模组静默失去全部 mixin（ATM3 报 32 条 "target not found"、0 条 mixin 生效；RLCraft 随后死在鼠标处理的类型转换上）。它防的 F12 崩溃现在本就不是致命的：GuiScreen 相关 mixin 住在非必需的 screen 配置里，目标已被加载就跳过而不是中止启动。58 个整合包实测：ATM3、FTB Academy、FTB Sky Odyssey、RLCraft 全部正常应用 mixin 并进入主菜单。
- **依赖：** `cfx-api` 维持 **0.9.2**；`cfx-gamepad-jni` **0.9.1 → 0.9.3.1**（0.9.2/0.9.3 承载 Android 启动器相关工作；0.9.3 把 `SystemCursor` 暴露为 JNI 入口，1.7.10 因此甩掉 JNA）。

---

## 7. 修复

- **「按住打开界面」的模组动作在 GUI 阶段存活（全版本线）。** `PhaseTransition.plan()` 只检查按键背后的第一个动作，而模组（动态）动作注册在所有内置动作之后 —— 一个 merely 共享按键的组合（如 `open_settings = buttonBack+buttonStart|PRESS`）通不过同绑定检查，按住的模组动作在进入 GUI 时被销毁、合成按键被释放。靠轮询这个键维持菜单的模组（Effortless Building、MineMenu）随即关界面、下一 tick 再打开：菜单闪烁且无法使用。现在由一个共享辅助函数遍历按键背后的所有动作，要求其完整按键组合此刻都被按住、且绑定在两个阶段中完全一致才保留 —— 保留的按键集合与保留的动作集合不再可能不一致。该辅助函数在 1.7.10 / 1.8.9 / 1.10.2 / 1.12.2 线保持 Java 8 兼容。
- **1.12.2 第二轮（随发布 jar 一起出）：** OSK 的两个 screen 钩子（Esc 关键盘、物理鼠标按下把门闩回 KBM）从必需 mixin 配置挪进非必需的 screen 配置 —— 当别的模组的 MixinTweaker 抢先变换了 GuiScreen，必需配置会 prepare 失败，客户端在加载主类之前就死在 `ClassNotFoundException`。首建的 beta.3 只能启动 58 个测试包里的 30 个；修复后 All the Mods 3、Enigmatica 2、Omnifactory (RandomPatches) 恢复启动（54+ / 58，与 beta.2 持平）。KBM UI 模式门闩同时挪进 `GuiScreen#handleInput` —— 所有 screen 都继承的唯一基础方法 —— 用过手柄后第一次物理点击输入框不再唤起键盘，Esc 一次就能关闭而不用两次。
