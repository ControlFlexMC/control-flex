> [中文版](changelog.zh.md)

# ControlFlex 0.8.8-beta.2 Changelog

- **Version:** `0.8.7.1` → `0.8.8-beta.2` (`mod_version` 0.8.8-beta.2; `cfx_api_version` 0.8.8)

This is the cumulative changelog for the 0.8.8 beta line, measured from **0.8.7.1**. It covers analog stick 360° movement, the camera-mode rework, double-press triggering and sneak/sprint Toggle actions, per-page Screen/Overlay key rebinding, virtual wheel unification, community-repo auto-apply, back-button mapping, and the v3 → v4 config migration.

---

## 1. Analog Stick 360° Movement (Analog Movement)

The stick is no longer a simple 8-way push but a true analog value: two feels — smooth (analog-smooth) and keyboard-like — combined with a radial deadzone and per-device response curves.

- Settings: `movement.analogEnabled` (default true, bool), `movement.localPolicy` / `movement.remotePolicy` (`ANALOG` | `KEYBOARD_LIKE`, default ANALOG / KEYBOARD_LIKE).
- A radial deadzone replaces the per-axis inner deadzone; per-device response curves `movementResponseCurve` / `cameraResponseCurve` (`stickTuning`).
- DualInput MOVE takes over: when stick movement and keyboard movement coexist, the controller takes over. `PlayerInputManager` always wraps the current `player.input`, so analog movement keeps its injection point even when another mod wraps the input.
- Dedicated **Analog Movement** settings page.
- Default policies: local/LAN stays fully analog; remote servers default to 8-way, and `AnalogServerWhitelist` (address + Realm) can enable analog-smooth for specific connections.
- Realm detection works through `MCCompat` (`ConnectionPolicyCache` caches the connection classification).
- Conflicting controller mods are detected by a pure-logic `AnalogConflictDetector` (controlify / controlify-forgified / controllable / midnightcontrols); the **Enable Analog Movement** card shows a warning (title, conflicting-mod chips, action hint) when a conflict is present, and nothing otherwise.
- Camera is independent of movement: `MouseStickHandler.applyCamera` gates only on `!controllerEnabled`, so the movement page no longer affects camera.

---

## 2. Camera Modes & Chained Camera Look

Camera handling becomes an explicit three-way mode, and several consumers can chain onto the look instead of one owner.

- Camera-mode dropdown with three options — **Direct Turn** / **Smooth Turn** / **Simulate Mouse**. Unconfigured users default to **Simulate Mouse**.
- `DirectSmoothMath` (camera scoping, rate-smoothing EMA, turn-scale) drives a `DIRECT_SMOOTH` `turn()` bypass channel.
- Startup camera-mode sync with a `simulateMouse` fallback, surfaced at INFO level.
- Card-style settings panel with a cycler picker; i18n copy added ("Direct Turn" zh: 直连转向; "Smooth Turn" zh: 平滑转向; "Simulate Mouse" zh: 模拟鼠标).
- Camera-look consumers are **chained** rather than single-owner; the consumer registry moves into the main mod, and the default is smooth turn.
- The cfx API is pinned to **0.8.8** (`api_version` renamed to `cfx_api_version`).

---

## 3. Double-Press Trigger Modes and Toggle Actions

Adds four double-press trigger semantics, splitting both sneak and run into two sets of actions: "hold" and "toggle".

- New trigger modes `DOUBLE_PRESS` / `DOUBLE_TAP` / `DOUBLE_HOLD` / `DOUBLE_TOGGLE`: reuse the TAP window; `DOUBLE_HOLD` interrupts the same-key HOLD.
- `toggle_sneak`: coexists with the HOLD version of sneak (`SneakToggleCompose` / `SneakToggleSameButton`); HOLD + DOUBLE_TOGGLE co-bound on the same key each receive their events.
- `DOUBLE_TOGGLE` toggles on the **second press** (`Event.DOUBLE_PRESS`), consistent with the DOUBLE_HOLD / DOUBLE_PRESS rhythm, and enters the `DOUBLE_PRESS_HOLD` conflict group; both the game and GUI sink DOUBLE_TOGGLE branches run on the press.
- The sneak latch is cleared on sneak PRESS (cross-key) rather than on release; double-tap is resolved from the gesture-start latch, ensuring correct turn-ON/turn-OFF.
- `toggle_sprint`: coexists with the HOLD version of sprint, empty binding by default; the overlay section stays empty; the v3→v4 migration clamps non-TOGGLE sprint modes to HOLD.
- Coexistence tip: only when MC "Toggle Sneak" is enabled does it show "MC Sneak = Hold"; the detail tip section sits between Special Behavior and Conflict.
- The action detail popup's mode column accommodates Double Toggle.

---

## 4. Per-Page Screen / Overlay Key Rebinding

Each adapted Screen / Overlay can freeze the bindings within its own **scope**, with other mods' keys falling into a personal override store, so pages no longer steal bindings from each other.

- Each Screen / Overlay freezes in-scope bindings; other mods' keys go into `UserScreenOverrideStore`.
- Independent sticks are treated as **not occupied**.
- The editor, overlay resolver, and layer-list jump links all follow the new spec.

---

## 5. Analog Wheel Unification + Per-Screen Speed Override + Threshold & Sensitivity Page

Merges the GUI list scroll and game/overlay virtual wheel repeat intervals into a single global key, and supports per-screen overrides.

- Merges `scrollRepeatMs` (GUI list) and the phase `virtualWheelRepeatMs` into a single global `virtualWheelRepeatMs` (default **200 ms**, clamped 50–1000).
- Per-Screen / Overlay analog wheel speed override: the compat JSON adds a `virtualWheelRepeatMs` field, and `effectiveVirtualWheelRepeatMs` is resolved uniformly in both the GUI and game/overlay phases.
- Virtual wheel sensitivity moved from the Cursor panel to the renamed "Threshold & Sensitivity Settings" page, refactored into a **card-based** layout (blue header + short description + a slider per item).
- Unresolved Screen/Overlay sticks default to **LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT**.
- Adaptation UX: the community config preview shows dependency install status (green if installed / red if not), the confirmation overwrite dialog puts each overwritten file path on its own line, and the per-page config layout is polished (cursor-style alignment, filter-bar reset button in the wheel row, spacing).

---

## 6. Community Config Repo: Auto-Apply & Source Migration

After a sync, automatically applies the community compat config once to "blank" installed mods, and keeps the builtin source pins current.

- When a mod is blank (unconfigured) and a repo variant exists, it is automatically applied once after the config sync.
- Only downloads CAS content for **installed mods**; blank mods take the highest `config_version`; the `autoApplyDone` flag is persisted together with the applied hashes (marked inside `applyCore`, surviving tracker rewrites).
- The installed-mod snapshot is frozen when the sync begins; apply runs on the worker thread before reload. `.applied.json` uses the same pretty printer as `sources.json`.
- Subsequent updates and Reset remain manual, tracked by `autoApplyDone`.
- The two builtin compat sources are bumped to **0.8.8**; `RepoOfficialSources` is the single source of truth for the official repo version and its URL forms.
- New `RepoSourceVersionStep` (MigrationGate "repo" chain) rewrites only builtin entries that point at the official repo and whose ref is a plain version strictly older than the builtin version; user-added sources, equal/newer pins, branch refs and foreign repos are left alone. Duplicate base URLs collapse to the first occurrence, the pre-migration file is backed up, and a no-op run writes nothing.

---

## 7. Config Migration v3 → v4

The chain ships within the `migrate` package, wired into the startup `MigrationGate`.

| Chain | Content |
|---|---|
| **profile** | v3→v4 Step: splits `sneak`/`toggle_sneak` and `sprint`/`toggle_sprint`; profile format stamp bumped to **v4** |
| **gamepad-selection** | v2→v3 Step: per-axis inner deadzone → radial inner/outer deadzone (inner/outer) + per-device `stickTuning` |
| **cfx** | folds the legacy `scrollRepeatMs` into the unified `virtualWheelRepeatMs` |
| **repo** | retargets stale builtin compat source pins to the current builtin version |

- `CURRENT_PROFILE_VERSION` is 4; `ProfileV3Step` writes `PROFILE_VERSION_V3` fixed, ensuring v2 sources still take the v3→v4 path in order.
- Idempotent and re-runnable; automatically backs up before migrating.

---

## 8. Back Button Mapping & Keyboard Ranges

- New **Back Button Mapping** settings page.
- Paddle-mapped Action and VKBM combos can opt into additional keyboard categories; **F1–F25 stay always allowed** and navigation is on by default.
- Capture reject handling, and the policy is loaded before profile deserialize.
- "Other" lists Back Button Mapping above Key Detection.

---

## 9. Mod Adaptation & Compat UI

- The Action Detail delivery-channel section shows a single read-only **Virtual KBM** row when a dynamic action's compat config declares the `virtualKbm` channel (e.g. Exposure `camera_controls`), suppressing the other four channel toggles; the row turns red with a no-key suffix when no keyboard/mouse key is bound.
- The mod page renders a declared dependency as a third info line ("依赖 <name>（已安装/未安装）"), reusing the repo preview's link styling; dependencies come from the effective compat config, falling back to configs skipped because a dependency is missing, so a gated page explains why it has no adaptation instead of looking empty.
- `ModCompatConfig` parses `dependencies[].mod_name` / `home_pages` for display; `getDependencyModIds()` is derived from it, leaving the activation gate untouched.
- Dynamic actions are no longer deleted before key mappings are ready (`reconcile()` gates their removal on `IClientLifecycle.isKeyMappingsReady()`).

---

## 10. Other Fixes / User Experience

- **Background input support**: input is handled correctly while the game window is in the background (unfocused), so Control Flex works alongside Split-Screen mods. The `OVERLAY` phase signal now requires an active window, so an unfocused window no longer falsely enters the overlay phase and remaps buttons (LB/RB = wheel/slot switch, blocking `open_settings`).
- `cursor_navi_*` bindings work independently per stick: the GUI phase gated the binding-derived cursor axis on the left stick's mode and the overlay phase on the right stick's, so one stick's mode disabled the other stick's binding. The axis now applies whenever either side is non-occupying, and each binding is still zeroed by the mode of the stick it physically lives on. `INDEPENDENT` is no longer treated as an override in the GUI path.
- The Key Mapping overview is no longer blurred by the Screen: the back chevron and label are drawn explicitly (matches ActionListScreen).
- The VKBM capture highlight is isolated to the **clicked row**: previously a shared dummy id caused every row to highlight and left a stale center prompt.
- When capture / filter-pick starts, it waits for an already-held number key to be released before recording (GitHub #4); the virtual mouse click completes once capture first suspends mapper input.
- After reattributing modid-less keys (such as MineMenu), the bundled `key.categories.misc:key.open_menu` in the profile is remapped accordingly, eliminating phantom gamepad conflict prompts.

---

## 11. Defaults / Template Tuning

- All three templates upgraded to **profile version 4**.
- `toggle_sneak` / `toggle_sprint` have **empty bindings** by default; `sneak` / `sprint` keep their keys, with the mode changed to HOLD.
- `virtualWheelRepeatMs` unified default is **200**.
- Unresolved Screen/Overlay sticks default to LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT.
- Camera mode defaults to **Simulate Mouse**; an unfocused Simulate Mouse uses **Smooth Turn** instead of Direct Turn.
