# ControlFlex 0.8.8-beta1 Changelog

- **版本：** `0.8.7.1` → `0.8.8-beta1`（`mod_version` 0.8.8-beta1；`api_version` 0.8.7 不变）
- **基线提交：** `82ca0a99` — `release 0.8.7.1`
- **HEAD：** `2ba3fce8` — `change to 0.8.8-beta1`
- **范围：** `82ca0a99..HEAD`，共 16 commits
- **体量：** 191 files，`+23767 / −710`（其中 `src/` 约 +10.4k/−0.7k；`docs/` 含大量内部 spec/plan，+13k；`api/` 无改动）

这是 0.8.8 的第一个 beta：围绕模拟摇杆 360° 移动（本地/远端策略）、双击触发与 sneak/sprint Toggle 动作、逐页 Screen/Overlay 按键重绑定、模拟滚轮统一及逐屏速度覆盖、社区配置仓库同步后自动应用，以及把用户配置升到 v4（sneak/sprint 拆分、gamepad-selection 径向死区 + stickTuning、统一滚轮键）。

---

## 1. 模拟摇杆 360° 移动（Analog Movement）

摇杆不再是简单 8-way 推挤，而是真正的模拟量：平滑（analog-smooth）与键盘式（keyboard-like）两种手感，配合径向死区与每设备响应曲线。

- 设置项：`movement.analogEnabled`（默认 true，bool）、`movement.localPolicy` / `movement.remotePolicy`（`ANALOG` | `KEYBOARD_LIKE`，默认 ANALOG / KEYBOARD_LIKE）。
- 径向死区（radial deadzone）取代逐轴内死区；每设备响应曲线 `movementResponseCurve` / `cameraResponseCurve`（`stickTuning`）。
- DualInput MOVE 接管：摇杆移动与键盘移动共存时由手柄接管。
- 专用 **Analog Movement** 设置页。
- 默认策略：本地 / LAN 保持全模拟；远端服务器默认 8-way，`AnalogServerWhitelist`（地址 + Realm）可对指定连接开启 analog-smooth。
- Realms 检测：1.20.1 没有 `ServerData.isRealm()`，统一经 `MCCompat` 路由（`ConnectionPolicyCache` 缓存连接分类）。

相关提交：`07394675`、`d840c03b`

---

## 2. 双击触发模式与 Toggle 动作

新增四档双击触发语义，并把「按住」与「切换」两种潜行/奔跑拆成两套动作。

- 新触发模式 `DOUBLE_PRESS` / `DOUBLE_TAP` / `DOUBLE_HOLD` / `DOUBLE_TOGGLE`：复用 TAP 窗口；`DOUBLE_HOLD` 打断同键 HOLD。
- `toggle_sneak`：与 HOLD 版 sneak 并存（`SneakToggleCompose` / `SneakToggleSameButton`），同键 co-bound 的 HOLD + DOUBLE_TOGGLE 各自收到事件。
- `DOUBLE_TOGGLE` 改为在**第二次按下**（`Event.DOUBLE_PRESS`）翻转，与 DOUBLE_HOLD / DOUBLE_PRESS 节奏一致，并进入 `DOUBLE_PRESS_HOLD` 冲突组；game 与 GUI 两处 sink 的 DOUBLE_TOGGLE 分支都移到 press 分支处理。
- Sneak latch 改在 sneak PRESS（cross-key）时清除（不再是 release）；双击从手势起始 latch 解析，保证 turn-ON/turn-OFF 正确。
- `toggle_sprint`：与 HOLD 版 sprint 并存，默认空绑定；overlay 段保持空；v3→v4 迁移把非 TOGGLE 的 sprint 模式 clamp 成 HOLD。
- 共存提示：仅在 MC「Toggle Sneak」开启时提示「MC Sneak = Hold」；详情 tip 段挪到 Special Behavior 与 Conflict 之间。
- 动作详情弹出窗模式列加宽，容纳 Double Toggle。

相关提交：`437fbaeb`、`def3a722`、`434c6889`、`57e431d7`

---

## 3. 逐页 Screen / Overlay 按键重绑定

每个被适配的 Screen / Overlay 现在能冻结自己**范围内**的绑定，其它模组的键落到个人 override 存储，从而避免各 page 之间互相抢占。

- 每个 Screen / Overlay 冻结 in-scope 绑定；其它 mod 的键进 `UserScreenOverrideStore`。
- Independent 摇杆视为**不占用**。
- 编辑器、overlay resolver、layer-list 跳转链接均按新版 spec 走。

相关提交：`fb15ff2b`

---

## 4. 模拟滚轮统一 + 逐屏速度覆盖 + 阈值&灵敏度页面

把 GUI 列表滚动与 game/overlay 虚拟滚轮的重复间隔合并成一个全局键，并支持逐屏覆盖。

- 合并 `scrollRepeatMs`（GUI 列表）与相位 `virtualWheelRepeatMs` 为单一全局 `virtualWheelRepeatMs`（默认 **200ms**，clamp 50–1000）。
- per-Screen / Overlay 模拟滚轮速度覆盖：compat JSON 新增 `virtualWheelRepeatMs` 字段，`effectiveVirtualWheelRepeatMs` 在 GUI 与 game/overlay 相位统一解析。
- 虚拟滚轮灵敏度从 Cursor 面板迁到重命名的「阈值&灵敏度设置」（Threshold & Sensitivity）页，该页重构为**卡片式**（蓝色标题 + 小描述 + 每项滑块）。
- 未解析的 Screen/Overlay 摇杆默认 **LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT**（编辑器同步反映）。
- Adaptation UX：社区配置预览显示依赖安装状态（已装绿 / 未装红）、确认覆盖弹窗把被覆盖文件路径单独一行、逐页配置布局（cursor-style 对齐、滚轮行 filter-bar 重置按钮、间距）polish。

相关提交：`fbbc9856`、`3965149b`

---

## 5. 社区配置仓库自动应用

同步后自动为「空白」的已装模组应用一次社区 compat 配置，降低上手成本。

- 空白（未配置）模组且存在 repo 变体时，配置同步后自动应用一次。
- 只下载**已装模组**的 CAS 内容；空白模组取最高 `config_version`；`autoApplyDone` 标记与 applied hashes 一起持久化（在 `applyCore` 内标记，跨 tracker 重写仍存活）。
- installed-mod 快照在同步开始冻结；apply 在 reload 前的 worker thread 运行。
- `.applied.json` 用与 `sources.json` 相同的 pretty printer，保持可读。
- 后续更新与 Reset 仍为手动，靠 `autoApplyDone` 跟踪。

相关提交：`fa1c5cb6`

---

## 6. 配置迁移 v3 → v4

发版前在 `migrate` 包内下发链，接入启动 `MigrationGate`。

| 链 | 内容 |
|---|---|
| **profile** | v3→v4 Step：拆分 `sneak`/`toggle_sneak` 与 `sprint`/`toggle_sprint`；profile 格式戳 bump 到 **v4** |
| **gamepad-selection** | v2→v3 Step：逐轴内死区 → 径向内/外死区（inner/outer）+ 每设备 `stickTuning` |
| **cfx** | 把 legacy `scrollRepeatMs` 折进统一 `virtualWheelRepeatMs` |

- `CURRENT_PROFILE_VERSION` bump 到 4；`ProfileV3Step` 固定写 `PROFILE_VERSION_V3`，保证 v2 源仍顺序走 v3→v4。
- 真实 0.8.7.1 fixture（`migrate-fixtures/v3/**`）+ 门/Step 测试（`FixtureV3MigrationTest`、`ProfileV4StepTest`、`GamepadSelectionStepTest`）。
- 幂等可重跑；迁移前自动备份。
- 迁移参考：`docs/migration/migrate-v3-to-v4.md`（新建）。

相关提交：`3965149b`

---

## 7. 其它修复 / 用户体验

- Key Mapping 总览不再被 Screen blur 糊掉：back chevron 与标签改成显式绘制（matches ActionListScreen）。
- VKBM capture 高亮隔离到**点击行**：此前共用 dummy id 导致每行都高亮并残留中心提示；绑定到合成行 id，弹窗打开时抑制列表等待，去掉 overlay。
- capture / filter-pick 开始时会等待已按住的数字键松开才记录（GitHub #4）；虚拟鼠标点击在 capture 首次挂起 mapper 输入时完成。
- 重归属无 modid 键（如 MineMenu）后，把 profile 里捆绑的 `key.categories.misc:key.open_menu` 同步重映射，消除 phantom 手柄冲突提示。

相关提交：`ebffe51f`、`5e6b4e90`、`ae6e2c45`、`b5bf03c5`

---

## 8. 默认值 / 模板 Tuning

- 三套模板升到 **profile version 4**。
- `toggle_sneak` / `toggle_sprint` 默认**空绑定**；`sneak` / `sprint` 保留按键、模式改为 HOLD。
- `virtualWheelRepeatMs` 统一默认 **200**。
- 未解析 Screen/Overlay 摇杆默认 LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT。

---

## 9. 内部 / 开发者

- `com.ifels.controlflex.migrate` 新增 `ProfileV4Step` / `GamepadSelectionStep` / `CfxV4Step`。
- `MCCompat` 集中 Realm 检测（1.20.1 无 `ServerData.isRealm()`）。
- 新类型：`AnalogServerWhitelist`、`AnalogBindingResolver`、`ForegroundBindingResolver`、`UserScreenOverrideStore`、`GamepadSelectionConfig`、`ConnectionPolicyCache`、`RepoAutoApply`、`RepoAppliedTracker`。
- `docs/migration/migrate-v3-to-v4.md`；`docs/superpowers` 新增大量 spec / plan / e2e-notes（double-trigger、toggle-sneak/sprint、screen-overlay-rebinding、360-degree-stick、analog-policy-tabs、repo-auto-apply、v3-to-v4-migration 等）。
- 测试套件扩张：`ActiveComboManagerDoubleTest`、`RepoAutoApplyTest`、`AnalogServerWhitelistTest`、`ConnectionPolicyCacheTest`、`BindingRegistryReattributeTest`、`SneakToggleSameButtonTest`、`AnalogBindingResolverTest`、`ForegroundBindingResolverTest`、`ProfileV4StepTest`、`GamepadSelectionStepTest`、`DualInputTest`、`ConnectionIdentityTest`、`BindingCaptureHandlerTest`、`GamepadSelectionConfigTest` 等。

相关提交：`bfdff6ce`、`3965149b`、`fbbc9856`、`07394675`、`fa1c5cb6`

---

## 10. 提交一览（旧 → 新）

| Hash | Subject |
|------|---------|
| `5e6b4e90` | fix: isolate Virtual KBM capture highlight to the clicked row |
| `ae6e2c45` | fix: ignore held confirm button when starting bind capture |
| `b5bf03c5` | fix: remap layer bindings when reattributing modid-less keys |
| `437fbaeb` | feat: add double trigger modes and screen/overlay rebinding spec |
| `def3a722` | feat: add toggle_sneak action alongside hold sneak |
| `434c6889` | feat: fire DOUBLE_TOGGLE on second press and add sneak/toggle-sneak coexistence tip |
| `57e431d7` | feat: add Toggle Sprint alongside hold Sprint |
| `ebffe51f` | fix: keep layer-mapping header sharp by skipping Screen blur |
| `fb15ff2b` | feat: add per-page Screen and Overlay key rebinding |
| `fa1c5cb6` | feat(repo): auto-apply community compat configs after sync |
| `07394675` | feat: add 360-degree analog movement with local/remote policies |
| `d840c03b` | fix: detect Realms via isConnectedToRealms on 1.20.1 |
| `fbbc9856` | feat: unify virtual wheel repeat and per-screen speed override |
| `3965149b` | feat: implement v3->v4 config migration and card-style threshold page |
| `bfdff6ce` | release 0.8.8-beta.1 |
| `2ba3fce8` | change to 0.8.8-beta1 |
