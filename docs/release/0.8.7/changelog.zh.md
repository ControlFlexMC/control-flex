> [English](changelog.md)

# ControlFlex 0.8.7 Changelog

- **版本：** `0.8.6.1` → `0.8.7`（`mod_version` / `api_version` 均为 0.8.7）

这是 0.8.x 线上最大的一次功能跨度：新增 Overlay 相位、Mod Adaptation、社区配置仓库、Virtual KBM、容器 Slot 方向导航，以及从 0.8.6.1 格式到 profile v3 的启动迁移。

---

## 1. Overlay 输入相位

交互式 HUD（法术轮盘、MineMenu 类环形菜单、第三方 overlay）不再挤占 Screen 层或 Main 层。

- 三相状态机：`game` / `overlay` / `screen`，带 `PhaseTransition`。
- Overlay 绑定**显式、不继承**：未配置的动作在 overlay 相位不触发（与 Screen 层同模型）。
- 默认 overlay 绑定贴近游戏层：左摇杆移动、右摇杆视角、跳跃/攻击/使用、滚轮、B = 返回。
- API overlay（`notifyOverlayForeground/Background`）即使鼠标被 grab（如 Exposure 拍照 HUD）也会强制进入 OVERLAY 相位。
- grab 状态下的 HUD 不显示控制器光标。
- Overlay 上的 RADIAL_PATH 摇杆接管光标所有权，并隐藏系统光标。
- `suppressLayerSwitch`：按键 extra 行为，overlay 打开时抑制层切换。
- 相位持久锁（PPA / `phasePersistentKeys`）：可把 Main 绑定成对派生到 overlay/screen，并带锁图标 UI。
- Overlay 默认跟随 Main 的游戏手感；Mod Adapter 可覆盖摇杆（RADIAL_PATH / DISABLED / VIRTUAL_MOUSE 等）。

---

## 2. Mod Adaptation（模组适配中心）

独立设置页，按模组管理 Screen / Overlay 适配，不再只靠手写 JSON。

- 模组目录 `ModCatalog` + 模组详情页（Bindings / Screen / Overlay 分栏）。
- Overlay 识别、黑名单 / 豁免、claim-only 的空适配也会留在列表里。
- 摇杆适配：`RADIAL_CURSOR` 更名为 `RADIAL_PATH`；可配 `cursorSpeed`、`showCursor`、`disabled`；卡片式 `StickEntryEditor`。
- Screen / Overlay 历史写入磁盘缓存，重开「添加适配」可回看最近窗口。
- 打开弹窗时扫描 API 标注的 overlay，并自动扫描。
- 大包性能：视口裁剪、图标异步缩小、上传预算，避免模组列表卡顿。
- 导入 / 导出本地适配配置。
- Compat 激活条件：目标 `mod_id` + `dependencies[].mod_id`（运行时不再用 `required_mod` / `loader`）。
- NeoForge 上豁免 `fabric_*`（Forgified Fabric API），避免误当独立模组。
- 内置 compat JSON 精简：删除 `dragonminez` / `invincible` / `irons_spellbooks` / `minemenu`，改走社区仓库；保留 `jei.json`、`epicfight.json`、`nightfall.json`、`exempt_mods.json`。
- 内置 compat 每次启动都抽出并加载；动态 action 注册时序修复（MineMenu 一类配置此前会静默失效）。
- 缺依赖模组时跳过对应 compat（早期 `required_mod`，后续改为 `mod_id` + `dependencies[]`）。

---

## 3. 社区配置仓库（Community Repo）

可添加远程源、同步、浏览、预览、应用别人分享的适配/绑定配置。

- HTTP + CAS 内容寻址；同步任务带日志。
- 浏览列表：仅已下载标记、变体、依赖预览。
- 预览 UI 与已应用绑定/适配同结构（模组信息 vs compat 分段）。
- 应用前备份已有用户文件。
- 本地配置导入 / 导出。
- Source 列表：URL 为空时禁用 Add。
- 再次打开预览时恢复 Applied 状态。

---

## 4. Virtual KBM（虚拟键盘鼠标通道）

新增 `VIRTUAL_KBM` 分发通道：手柄可注入物理键盘/鼠标键，而不必先注册成游戏 Action。

- 两步捕获、全层 UI、Overview 的 KBM 列。
- Overlay / Screen 层均可配置；层归属与绑定解耦。
- 物理键合并进 VKBM：去掉独立的 `KEY_LEFT_SHIFT` / `PAGE_UP` / `PAGE_DOWN` action；`PHYSICAL_KEYS` 类别改为 `SCROLL_WHEEL`。
- 启动迁移把旧物理键绑定迁到 VKBM（保留 F 键绑定）。
- 模板中 ESC 占位行；GUI 层 Left Shift 默认绑 LT（内置锁定）。
- 滚轮：每一层都可归属；TAP = 滚动一格；HOLD 按 `virtualWheelRepeatMs` 连发（默认 100ms，范围 50–1000）。
- GUI Back（B）经 VKBM 发送物理 ESC，与鼠标按 ESC 行为一致。
- Overlay 按键捕获不再泄漏到宿主搜索框。

---

## 5. 容器 Slot 方向导航

容器界面可用 DPAD 在格子之间瞬移光标（锥形几何，不假设规则网格）。

- 新动作 `slot_navi_*`；原 `gui_navi_*` 更名为 `cursor_navi_*`（左摇杆连续移动），带旧 ID 迁移。
- 默认：DPAD = slot 跳转（HOLD），左摇杆 = 光标移动。
- 算法修复：锥形过滤失效、`wrapToEdge` 主方向损坏、屏幕外 slot、以光标位置为参考（创造模式/滚动容器）。
- v2→v3 迁移会**空种** `slot_navi` 键，避免 backfill 抢走旧档里 JEI 的 DPAD 绑定。
- `warpToGui` 在 SLOT_NAVI 前更新 `lastSetCursor`，避免系统光标被误恢复。

---

## 6. 按键映射 UI / 设置结构

- Key Mapping 总览：7 列（Main / Shift1–4 / Screen / Overlay）+ KBM 列；筛选、搜索、单元格状态（未归属 / 未绑定 / overlay fallback / paused）。
- Action 详情弹窗：分发通道、冲突建议、Forge 冲突检测。
- 动态 action 可在 overlay/screen 编辑，默认不勾选。
- 设置拆分：Camera / Cursor / Other 子页；按手柄死区校准。
- 自定义 KeyMapping：打开设置（默认 F9，手柄 BACK+START）；径向菜单 1–5 迁到 `controlflex:` 命名空间。
- 注册自定义 KeyMapping 时**不再强制保存 `options.txt`**，避免 Forge 1.20.1 加载顺序把用户模组按键冲掉。
- 设置列表进入子页返回后保持滚动位置。
- 各类 polish：F 键字形、stick 开关、预览 Tab、Add Adaptation 点击遮罩、Support Me 芯片等。

---

## 7. 光标与手柄输入可靠性

- macOS 与全平台统一隐藏/同步：`TEXTURE_CURSOR_ENABLED`、`CURSOR_HIDDEN`、每帧 synthetic 过滤（含 macOS CGWarp 反馈）。
- 切屏时若控制器光标激活，重同步 MC 鼠标位置（修 FTB Quests 从背包跳到屏幕中心）。
- 手柄已按住时打开 GUI：第一 tick 抑制 HOLD，避免立刻触发 GUI 动作。
- 去掉 GUI Back 的「手上物品放回槽位」特例：B 与 ESC 完全一致，并修 1.20.1 `ClassCastException`。
- Xbox Wireless Adapter 同数量重连不再留下已关闭 wrapper（Unknown Gamepad）。
- 键注入走 `setDown()`，子类 press edge 生效（Iron's Spells 法术轮盘）。
- JEI Fabric：`defaultKey` 回退 + 合成按键走 `KeyboardHandler.keyPress()`，DPAD 可触发 showRecipe / showUses。
- `releaseUsingItem` mixin 从 `@Redirect` 改为 `@WrapOperation`，避免与 simplyusekey 抢 Redirect 崩溃。

---

## 8. 配置迁移（0.8.6.1 → 0.8.7）

启动时 `MigrationGate` 在配置加载前跑三条链，失败只打日志，不阻断启动。

| 链 | 内容 |
|---|---|
| **profile** | v1→v2 字段、v2→v3（actionId 派生修正）、空种 `overlayActionBindings`、空种 `slot_navi`、旧物理键 → VKBM |
| **compat** | 旧 `*_keys.json` / 扁平格式 → `inGameKeys` / `screenKeys` / `overlayKeys` |
| **cfx** | `cfx-client.json` 字段（slotSnap、controllerDisabled 等） |

- 备份目录：`config/controlflex/backup/<category>/`
- 幂等：已是最终格式则 no-op
- actionId 派生修复（`deriveGroupKey` / `ActionIdDerivation`），模板升到 version 3
- 模板会清掉空的模组专用 action 绑定（`invincible:` / `jei:` / `epicfight:` / `efn:` / `minemenu:` / `unknown:`）

---

## 9. 其它用户可见改动

- About / 顶栏 **Support Me**：Ko-fi、Patreon、Discord、GitHub；简中显示爱发电。支持链接改为代码绘制，去掉整图按钮资源。
- 设置热键与径向菜单 KeyMapping 可在原版 Controls 里看到（`controlflex:` 命名空间）。

---

## 10. 默认值 / 模板 Tuning

- 三套模板（Basic / Bedrock / Recommend）均为 **profile version 3**。
- Overlay 段与 Main 同手感；`gui_back` = B PRESS。
- GUI：`cursor_navi_*` = 左摇杆 HOLD；`slot_navi_*` = DPAD HOLD。
- JEI showRecipe / showUses 默认改为 **RT + DPAD Left/Right**，给 DPAD 让给 slot 导航。
- 滚轮 LB/RB 可在 Main 与 Overlay HOLD；TAP 一格。
- `virtualWheelRepeatMs` 默认 **100**。
- 内置 compat 仅 JEI / Epic Fight / Nightfall（Epic Fight 提示安装 bridge）。

---

