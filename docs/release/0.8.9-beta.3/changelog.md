> [中文版](changelog.zh.md)

# ControlFlex 0.8.9-beta.3 Changelog

- **Version:** `0.8.9-beta.1` → `0.8.9-beta.3` (`mod_version` 0.8.9-beta.3; `cfx_api_version` 0.9.2 — unchanged; `gamepad_jni_version` 0.9.1 → 0.9.3.1)

Two betas on top of 0.8.9-beta.1. Beta.2 adds delay and long-hold trigger tiers, replaces the virtual-keyboard backspace key with a proper `delete_text` action (profiles migrate to v6 in one step), and repairs the 26.3 SDL input path that left controllers dead and RT-to-delete inert. Beta.3 keeps hold-to-open mod actions alive across the GUI phase, untangles 1.12.2's mixin configs, and polishes the on-screen keyboard's sizing and rendering.

---

## 1. Binding: Delay and Long-Hold Trigger Tiers

A third global timing boundary (`delayPressMs`) now sits between the tap window and the long-press threshold, with three trigger modes that use it:

- **DELAY_PRESS** fires once when the press outlives the tap window.
- **DELAY_HOLD** activates there and stays active until release.
- **LONG_HOLD** activates at the long-press threshold and stays active.

The combo engine emits a new DELAY event once per pressed segment when the hold reaches `delayPressTicks`. The threshold invariant is `tap < delay < long`, so TAP and DELAY can never fire for the same press and the middle band becomes a choice instead of a dead zone: park the delay just past the tap window for a two-gesture button (tap = dodge, hold = crawl), or widen it for a three-tier button. A short tap can no longer flicker the hold on its way through.

- Narrow tap/long gaps resolve deterministically: the loader parks the delay at tap + 1 tick before reading the long-press boundary, so a stale value from a previously loaded profile can never raise it, and the long-press boundary is then raised by the minimum step needed to keep the three boundaries distinct (an explicit `delayPressMs` is honoured inside that pair afterwards).
- Profiles written before this change derive tap + 1 tick, so their press timeline is unchanged.
- The threshold page gets a fourth card, neighbour-clamped sliders, content scrolling (four cards overflow at common GUI scales) and the narrow-gap rule in its copy; the detection panel logs the new DELAY state so the boundary is visible while tuning.
- Backstory: the hold/delay-mode request from the ParCool crawl mapping thread.

---

## 2. Binding: `delete_text` Replaces the Virtual Backspace Key

The old scheme seeded `key.keyboard.backspace` on the GUI layer (`rightTrigger`) and injected a physical Backspace — so every mod hanging its own behaviour on that key fired too. The new `delete_text` action deletes one character from the input field the current Screen/Overlay has focused — straight to the field's own input target, never through `Screen.keyPressed` — and no-ops without a focused field. Holding repeats (10-tick delay, then every 3 ticks).

- While `delete_text` can act (a field is focused) it captures its buttons for the tick through release edge: no other action or vkbm slot on those buttons fires that tick. Without a field everything binds as before.
- Defaults: GUI layer `rightTrigger|HOLD`; the overlay stays empty unless RT is free. The default fill re-checks occupancy after the vkbm section loads — a kept backspace slot withholds the default.
- Templates drop the backspace entry and carry profile version 6.

---

## 3. Config Migration → v6

- v4/v5 → v6 **in one step**. The beta-only v4 → v5 step is removed; its chat default (`dpadLeft` = chat on the main layer) now lives in `ProfileV6Step` for pre-v5 sources.
- The factory backspace slot is stripped only while untouched; customized slots are kept.
- Serialization gains `delayPressMs` (see section 1); profiles written before this change derive tap + 1 tick.
- All templates carry version 6.

---

## 4. On-Screen Keyboard: Sizing and Rendering

- **Keycap content is sized from the cell, not the size setting.** The old rule grew the board and the label by the same factor and pinned the ink at ~10% of the keycap — illegible on a phone in landscape (about 0.5 mm on a 96 px keycap). Now `contentScale = cell / 13` (clamped 0.6–3.0) and keycap icons take a fixed 0.52 of the cell; both boards (layer keyboard and chat dock) follow the same rule so they read alike on one screen.
- **Aligned keycaps fit honestly.** The Delete / Clear / Done keycaps used to measure their word column from the layout's hardcoded label while drawing the binding's caption, and one shared fit let the space bar's wider badge drag all four keycaps down by a third. The badge column is now measured from the badges, each word takes its own scale to fill the shared field, and Space no longer votes on the aligned three's size.
- **The card draws above host depth** (1.7.10 / 1.8.9 / 1.10.2 / 1.12.2 / 1.16.5 / 1.18.2 / 1.19.2 / 1.20.1 / 1.21.1): the radial menu's Edit Slot modal draws at z=500, the OSK card at z=400 and its keycaps at z=800, so with depth testing on the card was rejected behind the modal while the keys still showed — a frameless keyboard. The keyboard layer now draws as an overlay: depth saved and disabled for the layer, card, keys and mirror in painter order, exact depth state restored.
- Old lines (1.7.10 / 1.8.9 / 1.10.2 / 1.12.2): a physical mouse click no longer opens the board, the macOS DEL character is rejected, and Esc closes the board.

---

## 5. 26.1.2 / 26.2 / 26.3: SDL3, Keycodes and Focus

- **Host SDL3 on 26.x.** Minecraft 26.x ships LWJGL SDL3 and the jar deliberately strips the bundled copy, but SDL3Manager still asked gamepad-jni for the BUNDLED source, which fell back to `System.loadLibrary("SDL3")` against a `java.library.path` that keeps 26.3's natives elsewhere — controllers were disabled with "no SDL3 in java.library.path" even though Minecraft's own SDL loaded fine. The source is now picked from the host: HOST when `org.lwjgl.sdl.SDL` is on the classpath, BUNDLED otherwise, with the choice logged.
- **Synthesized KeyEvents carry their SDL keycode.** 26.3 moved key events to SDL terms (`shortcutKey()` is an SDL keycode, Backspace = 8), while every synthetic event filled only the scancode — `EditBox.keyPressed` treated the bound Delete as an unknown key, so RT-to-delete did nothing from either the OSK keycap or the GUI-layer vkbm injection. A shared resolver (`SDL_GetKeyFromScancode`) now routes every synthetic press.
- **Custom text fields claim the SDL text-input session on focus (26.3).** Vanilla EditBox starts the session from `setFocused`; our own `EditTextField` never asked, so radial menu / slot editors, binding search and filter boxes stayed silent to the keyboard. Focusing now starts the session with the field as owner, losing focus stops it, and the caret rect is reported so the IME candidate window follows the insertion point.
- **The chat input is no longer lifted twice on 26.3 / 26.x.** Both the render wrapper and `ChatKeyboardHost.layout()` moved the EditBox up, landing the field near the top of the screen (y=30 instead of y=133 on a 429x248 GUI). The render wrapper keeps the font-scale transform only, and the input-bar background fill hooks dropped in the port are restored.
- **The creative search refreshes when host focus is elsewhere** (26.1.2 / 26.2 / 26.3, 1.20.1, 1.21.1, 1.21.11): the creative search box has no EditBox responder, so the OSK wrote the box directly and `refreshSearchResults()` never ran — text appeared, results did not. The OSK now walks the host's own route first and only writes the field directly when its value did not move; bound delete/clear/quick-text use the same host-aware target.
- **26.x:** the keyboard layer is anchored on `applyCursor`, not `GameRenderer#extractGui`; 26.2 is pinned to fabric-api 0.145.6 (0.145.5 breaks it).
- **Declared Fabric loader/API floors lowered** (26.1.2 / 26.2 / 26.3, 1.20.1, 1.21.1, 1.21.11 — 1.21.11 declares loader 0.17.3 / API 0.135.1): the floor is set by Fabric API, not by us, and the mod now declares and compiles against the earliest versions that actually work.

---

## 6. Version Coverage and Backports

- **1.16.5** (Fabric / Forge): mod key bindings re-scan on the first client tick, and compat bindings are kept when the KeyMapping scan is incomplete.
- **1.10.2 / 1.12.2** (Forge): the controller wheel is no longer dropped on Android; 1.10.2 pins its MixinBooter floor at 11.17.
- **1.8.9** (Forge): configs are registered and the extras gated on the Mixin registry.
- **1.7.10** (Forge): the entity AABB is read from the real field instead of the null stub; GuiSlot lists scroll from the `drawScreen` head; the inventory stays open when B closes a JEI page; and the system cursor is hidden through gamepad-jni's JNI entry point — the JNA dependency (and its per-platform dispatchers) is gone from the jar entirely.
- **Android:** the gamepad cursor moves on 1.7.10 / 1.8.9 / 1.10.2.
- **1.12.2** (Forge): the early mixin prepare is dropped — it prepared all four configs inside the core plugin, before FMLDeobfTweaker installed the name mapping, so every engine (Mixin 0.7.10 Surge, 0.7.11, 0.8.2, MixinCompat 0.8) resolved targets eagerly, failed, and the whole mod went silently unmixed (ATM3 showed 32 "target not found" and 0 applied mixins; RLCraft died later on a mouse-handler cast). The F12 crash the hack tried to prevent is non-fatal now: the GuiScreen-targeting mixins live in the non-required screen config, so an already-loaded target is skipped instead of aborting the launch. Measured over 58 packs: ATM3, FTB Academy, FTB Sky Odyssey and RLCraft all apply their mixins and reach the main menu.
- **Dependencies:** `cfx-api` stays at **0.9.2**; `cfx-gamepad-jni` moves **0.9.1 → 0.9.3.1** (0.9.2/0.9.3 carry the Android launcher work; 0.9.3 exposes `SystemCursor` as a JNI entry point, which lets 1.7.10 drop JNA).

---

## 7. Fixes

- **Hold-to-open mod actions survive the GUI phase (all lines).** `PhaseTransition.plan()` inspected only the first action behind a button, and mod actions register after every built-in — so a combo that merely shares the button (e.g. `open_settings = buttonBack+buttonStart|PRESS`) failed the same-binding check and the held mod action was destroyed on GUI enter, releasing its synthetic key. Any mod that keeps a menu visible by polling that key (Effortless Building, MineMenu) closed the screen immediately and reopened it on the next tick: the menu flickered and could not be used. Preservation is now resolved by one shared helper that walks every action behind the button, requires the action's whole button set to be held right now, and keeps the ones whose binding is identical in both phases — the preserved button set and the preserved action set can no longer disagree. The helper is kept Java 8 compatible on the 1.7.10 / 1.8.9 / 1.10.2 / 1.12.2 lines.
- **1.12.2, second round (in the shipped jar):** the two OSK screen hooks (Esc closes the keyboard, a physical mouse press latches the gate back to KBM) moved out of the required mixin config into the non-required screen config — a required GuiScreen config fails to prepare when another mod's MixinTweaker transformed GuiScreen first, and the client died with a `ClassNotFoundException` before the main class ever loaded. The first beta.3 build booted 30 of the 58 test packs; with the fix, All the Mods 3, Enigmatica 2 and Omnifactory (RandomPatches) boot again (54+ of 58, matching beta.2). The KBM UI-mode latch also moved into `GuiScreen#handleInput` — the one base method every screen inherits — so the first physical click on a field after gamepad use no longer opens the board, and one Esc closes it instead of two.
