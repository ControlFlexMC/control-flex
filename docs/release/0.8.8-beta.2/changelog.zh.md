> [English](changelog.md)

# ControlFlex 0.8.8-beta.2 更新日志

- **Version:** `0.8.7.1` → `0.8.8-beta.2`（`mod_version` 0.8.8-beta.2；`cfx_api_version` 0.8.8）

这是 0.8.8 beta 系列的累积更新日志，以 **0.8.7.1** 为基准统计。内容涵盖模拟摇杆 360° 移动、摄像机模式重构、双击触发与潜行/疾跑 Toggle 动作、按页面重绑定 Screen/Overlay 按键、虚拟滚轮统一、社区仓库自动应用、后退按键映射，以及 v3 → v4 配置迁移。

---

## 1. 模拟摇杆 360° 移动（Analog Movement）

摇杆不再是简单的 8 向推动，而是一个真正的模拟量：两种手感——平滑（analog-smooth）与类键盘——结合径向死区与按设备划分的响应曲线。

- 设置项：`movement.analogEnabled`（默认 true，bool）、`movement.localPolicy` / `movement.remotePolicy`（`ANALOG` | `KEYBOARD_LIKE`，默认 ANALOG / KEYBOARD_LIKE）。
- 径向死区取代了逐轴内死区；按设备划分的响应曲线 `movementResponseCurve` / `cameraResponseCurve`（`stickTuning`）。
- DualInput MOVE 接管：当摇杆移动与键盘移动同时存在时，由控制器接管。`PlayerInputManager` 始终包装当前的 `player.input`，因此即使其他模组包装了输入，模拟移动仍保留其注入点。
- 新增专用的 **Analog Movement** 设置页面。
- 默认策略：本地/局域网保持完全模拟；远程服务器默认 8 向，`AnalogServerWhitelist`（地址 + Realm）可为特定连接启用 analog-smooth。
- Realm 检测通过 `MCCompat` 实现（`ConnectionPolicyCache` 缓存连接分类）。
- 冲突的控制器模组由纯逻辑的 `AnalogConflictDetector` 检测（controlify / controlify-forgified / controllable / midnightcontrols）；存在冲突时，**Enable Analog Movement** 卡片会显示警告（标题、冲突模组标签、操作提示），否则不显示任何内容。
- 摄像机与移动相互独立：`MouseStickHandler.applyCamera` 仅依据 `!controllerEnabled` 门控，因此移动页面不再影响摄像机。

---

## 2. 摄像机模式与链式摄像机视角

摄像机处理变为明确的三选模式，并且多个消费者可以链式接入该视角，而不再由单一所有者独占。

- 摄像机模式下拉菜单提供三个选项——**Direct Turn（直连转向）** / **Smooth Turn（平滑转向）** / **Simulate Mouse（模拟鼠标）**。未配置的用户默认使用 **Simulate Mouse**。
- `DirectSmoothMath`（摄像机作用域、速率平滑 EMA、转向缩放）驱动一条 `DIRECT_SMOOTH` `turn()` 旁路通道。
- 启动时进行摄像机模式同步，并以 `simulateMouse` 作为回退，同时在 INFO 级别输出。
- 卡片式设置面板，配备循环选择器；新增 i18n 文案（"Direct Turn" zh: 直连转向; "Smooth Turn" zh: 平滑转向; "Simulate Mouse" zh: 模拟鼠标）。
- 摄像机视角消费者现在是**链式**的，而不再是单一所有者；消费者注册表移入主模组，默认值为平滑转向。
- cfx API 固定为 **0.8.8**（`api_version` 重命名为 `cfx_api_version`）。

---

## 3. 双击触发模式与 Toggle 动作

新增四种双击触发语义，将潜行与疾跑各自拆分为两套动作："按住"与"切换"。

- 新增触发模式 `DOUBLE_PRESS` / `DOUBLE_TAP` / `DOUBLE_HOLD` / `DOUBLE_TOGGLE`：复用 TAP 窗口；`DOUBLE_HOLD` 会中断同键的 HOLD。
- `toggle_sneak`：与 HOLD 版潜行共存（`SneakToggleCompose` / `SneakToggleSameButton`）；同一按键上共绑的 HOLD + DOUBLE_TOGGLE 各自接收其事件。
- `DOUBLE_TOGGLE` 在**第二次按下**时切换（`Event.DOUBLE_PRESS`），与 DOUBLE_HOLD / DOUBLE_PRESS 的节奏保持一致，并进入 `DOUBLE_PRESS_HOLD` 冲突组；游戏与 GUI 侧接收器的 DOUBLE_TOGGLE 分支都在按下时运行。
- 潜行锁存改为在潜行 PRESS（跨键）时清除，而非在释放时清除；双击由手势起始锁存解析，确保正确的开启/关闭。
- `toggle_sprint`：与 HOLD 版疾跑共存，默认空绑定；叠加区段保持为空；v3→v4 迁移将非 TOGGLE 的疾跑模式钳制为 HOLD。
- 共存提示：仅当 MC 的 "Toggle Sneak" 启用时才会显示 "MC Sneak = Hold"；详情提示区段位于 Special Behavior 与 Conflict 之间。
- 动作详情弹窗的模式列可容纳 Double Toggle。

---

## 4. 按页面重绑定 Screen / Overlay 按键

每个已适配的 Screen / Overlay 都可以冻结其自身**作用域**内的绑定，其他模组的按键则落入个人覆盖存储，因此页面之间不再相互窃取绑定。

- 每个 Screen / Overlay 冻结作用域内的绑定；其他模组的按键进入 `UserScreenOverrideStore`。
- 独立摇杆被视为**未占用**。
- 编辑器、叠加解析器与层级列表跳转链接均遵循新规范。

---

## 5. 模拟滚轮统一 + 按屏幕速度覆盖 + 阈值与灵敏度页面

将 GUI 列表滚动与游戏/叠加虚拟滚轮的重复间隔合并为单一全局键，并支持按屏幕覆盖。

- 将 `scrollRepeatMs`（GUI 列表）与阶段 `virtualWheelRepeatMs` 合并为单一的全局 `virtualWheelRepeatMs`（默认 **200 ms**，钳制范围 50–1000）。
- 按 Screen / Overlay 的模拟滚轮速度覆盖：compat JSON 新增 `virtualWheelRepeatMs` 字段，`effectiveVirtualWheelRepeatMs` 在 GUI 与游戏/叠加两个阶段统一解析。
- 虚拟滚轮灵敏度从 Cursor 面板移至重命名后的 "Threshold & Sensitivity Settings" 页面，并重构为**卡片式**布局（蓝色标题 + 简短说明 + 每项一个滑块）。
- 未解析的 Screen/Overlay 摇杆默认 **LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT**。
- 适配体验：社区配置预览会显示依赖安装状态（已安装为绿色 / 未安装为红色），确认覆盖对话框将每个被覆盖的文件路径单独成行，按页面配置布局也经过打磨（光标样式对齐、滚轮行中的过滤栏重置按钮、间距）。

---

## 6. 社区配置仓库：自动应用与源迁移

同步后，对"空白"的已安装模组自动应用一次社区 compat 配置，并保持内置源固定版本为最新。

- 当某个模组为空白（未配置）且存在仓库变体时，会在配置同步后自动应用一次。
- 仅为**已安装模组**下载 CAS 内容；空白模组取最高的 `config_version`；`autoApplyDone` 标志与应用哈希一同持久化（在 `applyCore` 内标记，可在跟踪器重写后保留）。
- 已安装模组快照在同步开始时冻结；应用在重载前于工作线程上运行。`.applied.json` 使用与 `sources.json` 相同的格式化输出器。
- 后续更新与 Reset 仍为手动，由 `autoApplyDone` 跟踪。
- 两个内置 compat 源提升至 **0.8.8**；`RepoOfficialSources` 是官方仓库版本及其 URL 形式的唯一事实来源。
- 新增 `RepoSourceVersionStep`（MigrationGate "repo" 链），仅重写指向官方仓库、且其 ref 为严格早于内置版本的纯版本号的内置条目；用户添加的源、相等/更新的固定版本、分支 ref 和外部仓库均保持不变。重复的基础 URL 会合并为首次出现的那个，迁移前的文件会被备份，而无操作运行时不会写入任何内容。

---

## 7. 配置迁移 v3 → v4

该链路随 `migrate` 包一同发布，并接入启动时的 `MigrationGate`。

| Chain | Content |
|---|---|
| **profile** | v3→v4 步骤：拆分 `sneak`/`toggle_sneak` 与 `sprint`/`toggle_sprint`；配置文件格式标记提升至 **v4** |
| **gamepad-selection** | v2→v3 步骤：逐轴内死区 → 径向内/外死区（内/外）+ 按设备 `stickTuning` |
| **cfx** | 将旧的 `scrollRepeatMs` 折叠进统一的 `virtualWheelRepeatMs` |
| **repo** | 将过期的内置 compat 源固定版本重定向到当前内置版本 |

- `CURRENT_PROFILE_VERSION` 为 4；`ProfileV3Step` 固定写入 `PROFILE_VERSION_V3`，确保 v2 来源仍按顺序走 v3→v4 路径。
- 幂等且可重复运行；迁移前会自动备份。

---

## 8. 后退按键映射与按键范围

- 新增 **Back Button Mapping** 设置页面。
- 映射到背键的 Action 与 VKBM 组合可以选择启用额外的按键类别；**F1–F25 始终允许**，且导航默认开启。
- 捕获拒绝处理，并且该策略在配置文件反序列化之前加载。
- "Other" 将 Back Button Mapping 列在 Key Detection 之上。

---

## 9. 模组适配与 Compat UI

- 当动态 action 的 compat 配置声明了 `virtualKbm` 通道时（例如 Exposure `camera_controls`），Action 详情页的投递通道区段会显示单行只读的 **Virtual KBM** 行，并抑制其他四个通道开关；当未绑定任何键盘 / 鼠标按键时，该行会变为红色并带有无按键后缀。
- 模组页面会将声明的依赖渲染为第三行信息（"依赖 <name>（已安装/未安装）"），复用仓库预览的链接样式；依赖来自生效的 compat 配置，并回退到因缺少依赖而被跳过的配置，因此被门控的页面能够解释其为何没有适配，而不是看起来空空如也。
- `ModCompatConfig` 会解析 `dependencies[].mod_name` / `home_pages` 以供显示；`getDependencyModIds()` 由其派生，激活门控保持不变。
- 动态 action 不再在按键映射就绪之前被删除（`reconcile()` 将其移除操作门控于 `IClientLifecycle.isKeyMappingsReady()`）。

---

## 10. 其他修复 / 用户体验

- **支持后台输入**：当游戏窗口处于后台（未聚焦）时，输入仍能被正确处理，因此 Control Flex 可与 Split-Screen Mod 配合使用。`OVERLAY` 阶段信号现在要求窗口处于活动状态，未聚焦的窗口不再误入叠加阶段并重映射按键（LB/RB = 滚轮/快捷栏切换，阻塞 `open_settings`）。
- `cursor_navi_*` 绑定按摇杆独立工作：GUI 阶段依据左摇杆的模式来门控由绑定推导出的光标轴，而叠加阶段依据右摇杆的模式，导致一个摇杆的模式会禁用另一个摇杆的绑定。现在只要任一侧不处于占用状态，该轴即会生效，而每个绑定仍会按其物理所在摇杆的模式被置零。`INDEPENDENT` 在 GUI 路径中不再被视为覆盖。
- 按键映射总览不再被 Screen 模糊：后退箭头与标签会被显式绘制（与 ActionListScreen 一致）。
- VKBM 捕获高亮被隔离到**被点击的行**：此前共享的 dummy id 会导致每一行都高亮，并留下一个残留的居中提示。
- 当捕获 / 过滤选择开始时，会等待已按住的数字键释放后再记录（GitHub #4）；虚拟鼠标点击在捕获首次暂停映射器输入后完成。
- 在重新归属没有 modid 的按键（例如 MineMenu）之后，配置文件中内置的 `key.categories.misc:key.open_menu` 会被相应重映射，从而消除虚假的手柄冲突提示。

---

## 11. 默认值 / 模板调优

- 三个模板全部升级至 **配置文件版本 4**。
- `toggle_sneak` / `toggle_sprint` 默认**空绑定**；`sneak` / `sprint` 保留其按键，模式改为 HOLD。
- `virtualWheelRepeatMs` 统一默认为 **200**。
- 未解析的 Screen/Overlay 摇杆默认 LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT。
- 摄像机模式默认 **Simulate Mouse**；未聚焦的 Simulate Mouse 使用 **Smooth Turn** 而非 Direct Turn。
