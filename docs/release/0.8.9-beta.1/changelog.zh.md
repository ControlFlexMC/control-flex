> [English](changelog.md)

# ControlFlex 0.8.9-beta.1 Changelog

- **版本：** `0.8.8.2` → `0.8.9-beta.1`（`mod_version` 0.8.9-beta.1；`cfx_api_version` 0.9.2；`gamepad_jni_version` 0.9.1）

这个 beta 把屏幕键盘补成「每个界面都能用」，ChatScreen 新增 Quick Text 与发送历史，加入 Android 启动器支持，并把整套功能回移植到 1.19.2、1.18.2、1.16.5、1.12.2 与 1.10.2。首次启动把 profile 升到 v5；#9（PlayStation 图标）与 #10（水里跳跃）已修复。

---

## 1. 屏幕键盘（OSK）

键盘不再是 ChatScreen 专属的 dock：ChatScreen 保留内置键盘，其它界面则得到一个浮层，聚焦到任意输入框即可唤起。

- 浮层**从不替换 `mc.screen`**：JEI 一类的 screen 事件监听在打字期间保持自己的状态，关闭键盘也不会让宿主 screen 走一遍往返。
- **六档避让布局**（`KeyboardPlacement`），每帧按被服务的输入框重算：底部居中、右侧停靠、左侧停靠、左右对半、抬到薄条上方，以及底部居中 + 镜像兜底。输入框间距固定 **6 px**（`KeyboardPlacement.FIELD_GAP`），键盘会横向绕开其它输入框（JEI 搜索栏、我们自己的设置卡片），太宽绕不过时改为浮在它上方。
- **打开时是模态的**：面板外的点击会关闭键盘并被吞掉，宿主控件（包括 JEI 搜索框）无法在打字中途把光标抢回去。
- **四种样式：** QWERTY（3 行）、QWERTY（4 行）、A–Z（3 行）、A–Z（4 行）。`KeyboardStyle.DEFAULT` 是四行；样式 id `"qwerty"` 仍表示三行。
- **尺寸：** 全局倍率 **0.3×–2.0×**，最高档之后还有一格「填满」停靠宽度（`onScreenKeyboard.keyboardScale`，默认 **1.0**）。ChatScreen 可按屏覆盖尺寸与样式。
- **键帽绑定**放在 `bindings.json`；键盘打开时独占其键帽用到的按键（含 GUI 层虚拟键鼠绑定），一次按下不会被消费两次。
- **按住虚拟键鼠键会连发：** HOLD 槽位现在像实体键盘一样输出 PRESS → REPEAT → RELEASE —— 第 10 tick 首次重复，之后每 tick 一次，因此按住退格会连续删字。鼠标键与纯修饰键除外。
- **输入框矩形经过绘制变换：** 我们的自适应页面给的是逻辑坐标矩形，键盘按输入框**实际占据**的矩形摆放，缩放或滚动过页面不会再让它停在幽灵位置。
- **入口：** 焦点追踪（包括自持 `EditBox` 的控件）、指针点击入口，以及 `KeyboardLayer.tryOpen`。
- **设置页：** 其他 → 屏幕键盘 —— 开关、样式、尺寸、聊天历史上限、快捷短语与键帽绑定。About 里隐藏的布局测试入口已移除，`KeyboardLayoutTestScreen` 只对测试可见。

---

## 2. ChatScreen：布局、快捷短语与发送历史

- **四种停靠布局：** Default（提示栏 + 列表）、No hints（无提示）、Keyboard + hints（键盘 + 两侧提示）、Minimal（仅键盘）。即使某布局在游戏内隐藏了历史/快捷短语，设置页里仍可编辑。
- **逐屏尺寸与字号：** 键盘尺寸覆盖，外加输入框、发送历史、快捷短语、补全建议、动作提示与聊天消息的字号（`chat.json`）。
- **发送历史：** 只记录已发送的行，**1–50** 条（默认 **10**），任意一行可推入快捷短语列表。
- **Quick Text（快捷短语）：** 预先写好的短语，选中只填入输入框、**不会发送**；编辑弹窗支持置顶、上下移动与删除。
- **列表导航：** 用手柄在键盘 / 历史 / 快捷短语 / 补全之间切换焦点、选择列表项、长按编辑，以及被截断条目的自动展开。
- **Chat 页面设置**（Key Mapping → Screen Layer Mapping → ChatScreen）：聊天、退格、光标、补全与列表导航各自成行，沿用一致的 pad / 模式 / Reset / Clear 交互，并新增 Replace / Append 输入模式。

---

## 3. Android 支持

- **启动器：** ZalithLauncher2 > 2.7 与 FoldCraftLauncher >= 1.3.4.0 现在可用；MojoLauncher 与 Amethyst 需等它们的新版本。
- **只用一份 SDL —— 启动器自带的那份。** 旧报错 `sdl3 is not found` 的根因是 native loader 用 `os.name` / `os.arch` 推导平台目录，而 Android 启动器报的是 `os.name=Linux` + `aarch64`，于是去加载桌面 glibc 版本。cfx-gamepad-jni **0.9.1** 改为从 `POJAV_NATIVEDIR` 解析启动器自己的 `libSDL3.so`，不再加载第二份 SDL。
- **与桌面同一个 jar。** 只额外打包 `libgamepadjni.so` 的 arm64-v8a、armeabi-v7a、x86_64 三个 ABI，没有单独的 Android 构建。
- **平台识别：** gamepad-jni 暴露 `HostPlatform`，mod 侧一次性读取为 `OS.HOST` / `OS.IS_ANDROID` / `OS.IS_MOBILE`。
- **移动端光标：** 移动端跳过「系统」光标样式（启动器还无法隐藏其浮层光标），打开 GUI 时手柄光标落在窗口中心，而不是读取系统光标位置。

---

## 4. 版本覆盖与回移植

- **1.20.1**（Fabric / Forge）：Forge 47.3.10 以下版本恢复启动 —— mod 类现在提供 FML 会查找的无参构造；键帽图标与文字统一到同一尺寸、同一条中线。
- **1.21.1 / 1.21.11 / 26.1.2 / 26.2 / 26.3**（Fabric / NeoForge）：同样的键盘与聊天功能；1.21.1 这一代没有 LWJGL SDL3，因此初始化自带的 SDL3。
- **1.19.2 / 1.18.2 / 1.16.5**（Fabric / Forge）：EditBox mixin 改为瞄准原版**声明**的方法（这些版本把输入方法声明在接口上，无法注入），捕获到的修饰键跨两次捕获步骤配对，聊天底部偏移改用可组合注入点。
- **1.12.2**（Forge）：合成 screen 按键模拟 LWJGL2 的键盘事件状态，合成点击走 screen 自己的 `handleMouseInput`，模组按键绑定在第一个客户端 tick 重新扫描，滚轮在过滤器弹窗打开时滚动弹窗而不是页面。
- **1.10.2**（Forge）：物理点击输入框不再唤起屏幕键盘，JEI compat 数据与真实的 1.10.2 jar 对齐。
- **依赖：** `cfx-api` **0.9.2** 移除了 `IInputInjector` SPI（其余接口 —— `ICameraLookConsumer`、`setInteractiveContextRegistrar`、`VERSION` —— 不变）；`cfx-gamepad-jni` **0.9.1** 携带启动器 SDL3 解析与 Android 原生库。

---

## 5. 配置迁移 v4 → v5

- `ProfileV5Step` 接在 v4 之后由 `MigrationGate` 执行，只在**不会覆盖已有配置**时补两个默认值：主层 `chat` = `dpadLeft|PRESS`，GUI 层 `key.keyboard.backspace` = `rightTrigger`。
- 只有动作槽为空**且**该按键在该层没有独立绑定时才补；组合键不阻塞，停用的虚拟键鼠槽位不算占用，畸形数据原样保留。
- 即使什么都没补，也会把版本戳写成 **5**，因此重复执行是空操作；迁移前的自动备份照常进行。
- 三套模板的 `templateMeta.version` 均为 5。`ProfileV4Step` 仍显式写入 4，保证 v2 源按 v3 → v4 → v5 顺序走完。
- `cfx-client.json` 的键盘配置位于 `onScreenKeyboard.*`（`enabled`、`keyboardScale`）。未发布的 `virtualKeyboard.*` 块直接忽略，不保留兼容垫片。
- `chat.json`：旧的 `styleOverride: "inherit"` 读作「跟随全局样式」；现在「未设置」即跟随，选择 Follow Global 会删除存储的样式而不是写入标记。

---

## 6. 修复

- **#9 —— PlayStation 图标与名称。** 自动图标皮肤改为解析最后连接的手柄（持久化在选择配置里），并按 VID 归类索尼硬件，PS4 手柄不会再借用 PS5 或 Xbox 的外观。名称也跟随皮肤：DualSense / PS5 上是 Create，DualShock / PS4 上是 SHARE。
- **#10 —— 水里的一次性跳跃。** PRESS / TAP / RELEASE / LONG_PRESS / DOUBLE_* 都在一个 tick 后就释放 `keyJump`，而原版只把**按住**的跳跃用于上浮。现在这类按下会被持续按住，直到原版不再消费它（离开流体、不再受流体影响、或水浅到能用地面跳）或 10 tick 预算耗尽；所有清理路径都会释放这个合成按键。
- GUI 层的虚拟键鼠绑定不再叠在键盘键帽上触发；此前一次 RT 会删掉两个字符。
- D-Pad 右键不再丢掉已选中的补全项：无法真正移动光标的操作不再通知 responder，补全会应用你选中的那一行。
- 自带 `EditBox` 的控件（如 Sophisticated Storage 搜索框）现在能唤起键盘，键盘也不再压住其它输入框。
- 聊天/EditBox 的装饰性注入点改为 `require = 0`：别的模组覆盖了被注入的方法时，代价只是样式失效而不是客户端崩溃；物理键盘识别忽略没有硬件扫描码的合成按键。
- 1.20.1：补全列表与输入栏保留 2 px 间距，Delete / Clear / Done / Space 四个键帽按同一尺寸绘制。

---

## 7. 默认值 / 模板 Tuning

- 屏幕键盘默认**开启**（`onScreenKeyboard.enabled` = true），默认四行 QWERTY，尺寸 **1.0×**。
- ChatScreen 默认跟随全局样式，不写入 `styleOverride`；停靠布局默认 Default（提示栏 + 列表）。
- 聊天历史上限默认 **10**（范围 1–50）。
- 键帽默认值：cursorLeft = D-Pad Left、cursorRight = D-Pad Right、Space = LT、Clear = X、Delete = RT（HOLD）、Done = Y —— 所有带徽标的键帽开箱即解析出绑定。
- 三套模板均为 **profile version 5**。
