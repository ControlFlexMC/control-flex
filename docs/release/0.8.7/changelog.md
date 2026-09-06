> [中文版](changelog.zh.md)

# ControlFlex 0.8.7 Changelog

- **Version:** `0.8.6.1` → `0.8.7` (`mod_version` / `api_version` both 0.8.7)

This is the largest feature span in the 0.8.x line to date: new Overlay phase, Mod Adaptation, a community config repo, Virtual KBM, container Slot directional navigation, and a startup migration from the 0.8.6.1 format to profile v3.

---

## 1. Overlay input phase

Interactive HUDs (spell wheels, MineMenu-style radial menus, third-party overlays) no longer crowd the Screen layer or the Main layer.

- Three-phase state machine: `game` / `overlay` / `screen`, with `PhaseTransition`.
- Overlay bindings are **explicit, not inherited**: unconfigured actions do not fire in the overlay phase (same model as the Screen layer).
- Default overlay bindings feel close to the game layer: left stick move, right stick look, jump/attack/use, scroll wheel, B = back.
- API overlays (`notifyOverlayForeground/Background`) force the OVERLAY phase even while the mouse is grabbed (e.g. Exposure photo HUD).
- HUDs in the grabbed state do not show the controller cursor.
- The RADIAL_PATH stick on the overlay takes over cursor ownership and hides the system cursor.
- `suppressLayerSwitch`: key extra behavior that suppresses layer switching while an overlay is open.
- Phase-persistent lock (PPA / `phasePersistentKeys`): a Main binding can be paired and derived to overlay/screen, with a lock icon UI.
- The overlay follows Main's game feel by default; the Mod Adapter can override the stick (RADIAL_PATH / DISABLED / VIRTUAL_MOUSE, etc.).

---

## 2. Mod Adaptation (Mod Adaptation center)

A standalone settings page that manages Screen / Overlay adaptation per mod, instead of relying only on hand-written JSON.

- Mod catalog `ModCatalog` + mod detail page (Bindings / Screen / Overlay sections).
- Overlay detection, blacklist / exemptions, and claim-only empty adaptations still remain in the list.
- Stick adaptation: `RADIAL_CURSOR` renamed to `RADIAL_PATH`; configurable `cursorSpeed`, `showCursor`, `disabled`; card-style `StickEntryEditor`.
- Screen / Overlay history is written to a disk cache; reopening "Add Adaptation" lets you review recent windows.
- Scans API-annotated overlays when the popup opens, and scans automatically.
- Large-pack performance: viewport culling, asynchronous icon downscaling, upload budget, to avoid mod list stutter.
- Import / export local adaptation configs.
- Compat activation condition: target `mod_id` + `dependencies[].mod_id` (runtime no longer uses `required_mod` / `loader`).
- Exempts `fabric_*` on NeoForge (Forgified Fabric API), to avoid mistaking it for a standalone mod.
- Built-in compat JSON slimmed down: removed `dragonminez` / `invincible` / `irons_spellbooks` / `minemenu`, moved to the community repo; kept `jei.json`, `epicfight.json`, `nightfall.json`, `exempt_mods.json`.
- Built-in compat is extracted and loaded on every launch; dynamic action registration timing fixed (MineMenu-style configs previously failed silently).
- When a dependency mod is missing, the corresponding compat is skipped (earlier `required_mod`, later changed to `mod_id` + `dependencies[]`).

---

## 3. Community config repo (Community Repo)

Add remote sources, sync, browse, preview, and apply adaptations/binding configs shared by others.

- HTTP + CAS content addressing; sync tasks with logs.
- Browse list: downloaded-only marker, variants, dependency preview.
- Preview UI uses the same structure as applied bindings/adaptations (mod info vs compat sections).
- Backs up existing user files before applying.
- Local config import / export.
- Source list: Add disabled when the URL is empty.
- Restores the Applied state when reopening the preview.

---

## 4. Virtual KBM (Virtual keyboard/mouse channel)

New `VIRTUAL_KBM` dispatch channel: the gamepad can inject physical keyboard/mouse keys without having to first register them as game Actions.

- Two-step capture, all-layer UI, Overview KBM column.
- Configurable on both Overlay / Screen layers; layer membership and binding are decoupled.
- Physical keys merged into VKBM: removed the separate `KEY_LEFT_SHIFT` / `PAGE_UP` / `PAGE_DOWN` actions; the `PHYSICAL_KEYS` category changed to `SCROLL_WHEEL`.
- Startup migration moves old physical-key bindings to VKBM (keeps the F key bindings).
- ESC placeholder row in templates; GUI-layer Left Shift defaults to bound LT (built-in lock).
- Scroll wheel: assignable to each layer; TAP = scroll one notch; HOLD repeats per `virtualWheelRepeatMs` (default 100ms, range 50–1000).
- GUI Back (B) sends a physical ESC via VKBM, matching clicking ESC with the mouse.
- Overlay key capture no longer leaks into the host search box.

---

## 5. Container Slot directional navigation

The container screen can teleport the cursor between slots using the DPAD (conical geometry, without assuming a regular grid).

- New actions `slot_navi_*`; the old `gui_navi_*` renamed to `cursor_navi_*` (left stick continuous movement), with old-ID migration.
- Defaults: DPAD = slot jump (HOLD), left stick = cursor movement.
- Algorithm fixes: cone filter failure, `wrapToEdge` primary direction broken, off-screen slots, cursor-position reference (creative mode / scrolling containers).
- v2→v3 migration now **seeds empty** `slot_navi` keys, to avoid backfill stealing JEI's DPAD bindings in old saves.
- `warpToGui` updates `lastSetCursor` before SLOT_NAVI, to avoid the system cursor being wrongly restored.

---

## 6. Key mapping UI / settings structure

- Key Mapping overview: 7 columns (Main / Shift1–4 / Screen / Overlay) + KBM column; filtering, search, cell states (unassigned / unbound / overlay fallback / paused).
- Action detail popup: dispatch channel, conflict suggestions, Forge conflict detection.
- Dynamic actions can be edited on overlay/screen, unchecked by default.
- Settings split: Camera / Cursor / Other sub-pages; per-gamepad dead-zone calibration.
- Custom KeyMapping: opens settings (default F9, gamepad BACK+START); radial menu 1–5 moved to the `controlflex:` namespace.
- Registering a custom KeyMapping **no longer forces saving `options.txt`**, to avoid Forge 1.20.1 load order wiping the user's mod keys.
- Settings list keeps scroll position after returning from a sub-page.
- Various polish: F key glyphs, stick toggles, preview tab, Add Adaptation click mask, Support Me chip, etc.

---

## 7. Cursor & gamepad input reliability

- macOS and all-platform unified hide/sync: `TEXTURE_CURSOR_ENABLED`, `CURSOR_HIDDEN`, per-frame synthetic filtering (including macOS CGWarp feedback).
- When switching screens with the controller cursor active, resync the MC mouse position (fixes FTB Quests jumping from the backpack to screen center).
- Opening a GUI while the gamepad is already held: HOLD is suppressed on the first tick, to avoid immediately triggering GUI actions.
- Removed the "return held item to slot" special case for GUI Back: B is now fully identical to ESC, and fixes the 1.20.1 `ClassCastException`.
- Xbox Wireless Adapter reconnects with the same count no longer leave an already-closed wrapper behind (Unknown Gamepad).
- Key injection goes through `setDown()`, so subclass press edges take effect (Iron's Spells spell wheel).
- JEI Fabric: `defaultKey` fallback + crafting keys go through `KeyboardHandler.keyPress()`, DPAD can trigger showRecipe / showUses.
- `releaseUsingItem` mixin changed from `@Redirect` to `@WrapOperation`, to avoid a crash from fighting simplyusekey for the Redirect.

---

## 8. Config migration (0.8.6.1 → 0.8.7)

At startup, `MigrationGate` runs three chains before config load; failures are only logged and do not block startup.

| Chain | Content |
|---|---|
| **profile** | v1→v2 fields, v2→v3 (actionId derivation fix), seed empty `overlayActionBindings`, seed empty `slot_navi`, old physical keys → VKBM |
| **compat** | old `*_keys.json` / flat format → `inGameKeys` / `screenKeys` / `overlayKeys` |
| **cfx** | `cfx-client.json` fields (slotSnap, controllerDisabled, etc.) |

- Backup directory: `config/controlflex/backup/<category>/`
- Idempotent: no-op if already in final format
- actionId derivation fix (`deriveGroupKey` / `ActionIdDerivation`), templates bumped to version 3
- Templates clear empty mod-specific action bindings (`invincible:` / `jei:` / `epicfight:` / `efn:` / `minemenu:` / `unknown:`)

---

## 9. Other user-visible changes

- About / top bar **Support Me**: Ko-fi, Patreon, Discord, GitHub; shows Afdian in Simplified Chinese. Support links now drawn in code, removing the full-image button assets.
- Settings hotkey and radial-menu KeyMapping are visible in the vanilla Controls (`controlflex:` namespace).

---

## 10. Defaults / template tuning

- All three templates (Basic / Bedrock / Recommend) are **profile version 3**.
- Overlay section matches Main's feel; `gui_back` = B PRESS.
- GUI: `cursor_navi_*` = left stick HOLD; `slot_navi_*` = DPAD HOLD.
- JEI showRecipe / showUses default changed to **RT + DPAD Left/Right**, freeing the DPAD for slot navigation.
- Scroll wheel LB/RB can be HELD on Main and Overlay; TAP is one notch.
- `virtualWheelRepeatMs` default **100**.
- Built-in compat is only JEI / Epic Fight / Nightfall (Epic Fight prompts to install the bridge).

---

