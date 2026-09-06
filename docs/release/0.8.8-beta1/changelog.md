> [中文版](changelog.zh.md)

# ControlFlex 0.8.8-beta1 Changelog

- **Version:** `0.8.7.1` → `0.8.8-beta1` (`mod_version` 0.8.8-beta1; `api_version` 0.8.7 unchanged)

This is the first beta of 0.8.8, centered on analog stick 360° movement (local/remote policies), double-press triggering and sneak/sprint Toggle actions, per-page Screen/Overlay key rebinding, unification of the analog wheel and per-screen speed overrides, automatic application of community configs after syncing the community config repo, and upgrading user configs to v4 (sneak/sprint split, gamepad-selection radial deadzone + stickTuning, unified wheel key).

---

## 1. Analog Stick 360° Movement (Analog Movement)

The stick is no longer a simple 8-way push but a true analog value: two feels — smooth (analog-smooth) and keyboard-like — combined with a radial deadzone and per-device response curves.

- Settings: `movement.analogEnabled` (default true, bool), `movement.localPolicy` / `movement.remotePolicy` (`ANALOG` | `KEYBOARD_LIKE`, default ANALOG / KEYBOARD_LIKE).
- A radial deadzone replaces the per-axis inner deadzone; per-device response curves `movementResponseCurve` / `cameraResponseCurve` (`stickTuning`).
- DualInput MOVE takes over: when stick movement and keyboard movement coexist, the controller takes over.
- Dedicated **Analog Movement** settings page.
- Default policies: local/LAN stays fully analog; remote servers default to 8-way, and `AnalogServerWhitelist` (address + Realm) can enable analog-smooth for specific connections.
- Realms detection: 1.20.1 has no `ServerData.isRealm()`, routed uniformly through `MCCompat` (`ConnectionPolicyCache` caches the connection classification).

---

## 2. Double-Press Trigger Modes and Toggle Actions

Adds four double-press trigger semantics, splitting both sneak and run into two sets of actions: "hold" and "toggle".

- New trigger modes `DOUBLE_PRESS` / `DOUBLE_TAP` / `DOUBLE_HOLD` / `DOUBLE_TOGGLE`: reuse the TAP window; `DOUBLE_HOLD` interrupts the same-key HOLD.
- `toggle_sneak`: coexists with the HOLD version of sneak (`SneakToggleCompose` / `SneakToggleSameButton`); HOLD + DOUBLE_TOGGLE co-bound on the same key each receive their events.
- `DOUBLE_TOGGLE` now toggles on the **second press** (`Event.DOUBLE_PRESS`), consistent with the DOUBLE_HOLD / DOUBLE_PRESS rhythm, and enters the `DOUBLE_PRESS_HOLD` conflict group; both the game and GUI sink DOUBLE_TOGGLE branches were moved to the press branch.
- The sneak latch is now cleared on sneak PRESS (cross-key) rather than on release; double-tap is resolved from the gesture-start latch, ensuring correct turn-ON/turn-OFF.
- `toggle_sprint`: coexists with the HOLD version of sprint, empty binding by default; the overlay section stays empty; the v3→v4 migration clamps non-TOGGLE sprint modes to HOLD.
- Coexistence tip: only when MC "Toggle Sneak" is enabled does it show "MC Sneak = Hold"; the detail tip section was moved to between Special Behavior and Conflict.
- The action detail popup's mode column was widened to accommodate Double Toggle.

---

## 3. Per-Page Screen / Overlay Key Rebinding

Each adapted Screen / Overlay can now freeze the bindings within its own **scope**, with other mods' keys falling into a personal override store, so pages no longer steal bindings from each other.

- Each Screen / Overlay freezes in-scope bindings; other mods' keys go into `UserScreenOverrideStore`.
- Independent sticks are treated as **not occupied**.
- The editor, overlay resolver, and layer-list jump links all follow the new spec.

---

## 4. Analog Wheel Unification + Per-Screen Speed Override + Threshold & Sensitivity Page

Merges the GUI list scroll and game/overlay virtual wheel repeat intervals into a single global key, and supports per-screen overrides.

- Merges `scrollRepeatMs` (GUI list) and the phase `virtualWheelRepeatMs` into a single global `virtualWheelRepeatMs` (default **200 ms**, clamped 50–1000).
- Per-Screen / Overlay analog wheel speed override: the compat JSON adds a `virtualWheelRepeatMs` field, and `effectiveVirtualWheelRepeatMs` is resolved uniformly in both the GUI and game/overlay phases.
- Virtual wheel sensitivity moved from the Cursor panel to the renamed "Threshold & Sensitivity Settings" (Threshold & Sensitivity) page, which was refactored into a **card-based** layout (blue header + short description + a slider per item).
- Unresolved Screen/Overlay sticks default to **LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT** (the editor reflects this too).
- Adaptation UX: the community config preview shows dependency install status (green if installed / red if not), the confirmation overwrite dialog puts each overwritten file path on its own line, and the per-page config layout was polished (cursor-style alignment, filter-bar reset button in the wheel row, spacing).

---

## 5. Community Config Repo Auto-Apply

After a sync, automatically applies the community compat config once to "blank" installed mods, lowering the barrier to get started.

- When a mod is blank (unconfigured) and a repo variant exists, it is automatically applied once after the config sync.
- Only downloads CAS content for **installed mods**; blank mods take the highest `config_version`; the `autoApplyDone` flag is persisted together with the applied hashes (marked inside `applyCore`, surviving tracker rewrites).
- The installed-mod snapshot is frozen when the sync begins; apply runs on the worker thread before reload.
- `.applied.json` uses the same pretty printer as `sources.json` to stay readable.
- Subsequent updates and Reset remain manual, tracked by `autoApplyDone`.

---

## 6. Config Migration v3 → v4

Before release, the chain is shipped within the `migrate` package, wired into the startup `MigrationGate`.

| Chain | Content |
|---|---|
| **profile** | v3→v4 Step: splits `sneak`/`toggle_sneak` and `sprint`/`toggle_sprint`; profile format stamp bumped to **v4** |
| **gamepad-selection** | v2→v3 Step: per-axis inner deadzone → radial inner/outer deadzone (inner/outer) + per-device `stickTuning` |
| **cfx** | folds the legacy `scrollRepeatMs` into the unified `virtualWheelRepeatMs` |

- `CURRENT_PROFILE_VERSION` bumped to 4; `ProfileV3Step` writes `PROFILE_VERSION_V3` fixed, ensuring v2 sources still take the v3→v4 path in order.
- Idempotent and re-runnable; automatically backs up before migrating.

---

## 7. Other Fixes / User Experience

- The Key Mapping overview is no longer blurred by the Screen: the back chevron and label are now drawn explicitly (matches ActionListScreen).
- The VKBM capture highlight is isolated to the **clicked row**: previously a shared dummy id caused every row to highlight and left a stale center prompt; it now binds to the synthetic row id, suppresses the list wait while the popup is open, and the overlay was removed.
- When capture / filter-pick starts, it waits for an already-held number key to be released before recording (GitHub #4); the virtual mouse click completes once capture first suspends mapper input.
- After reattributing modid-less keys (such as MineMenu), the bundled `key.categories.misc:key.open_menu` in the profile is remapped accordingly, eliminating phantom gamepad conflict prompts.

---

## 8. Defaults / Template Tuning

- All three templates upgraded to **profile version 4**.
- `toggle_sneak` / `toggle_sprint` have **empty bindings** by default; `sneak` / `sprint` keep their keys, with the mode changed to HOLD.
- `virtualWheelRepeatMs` unified default is **200**.
- Unresolved Screen/Overlay sticks default to LEFT=VIRTUAL_MOUSE / RIGHT=INDEPENDENT.

