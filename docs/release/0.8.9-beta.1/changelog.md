> [中文版](changelog.zh.md)

# ControlFlex 0.8.9-beta.1 Changelog

- **Version:** `0.8.8.2` → `0.8.9-beta.1` (`mod_version` 0.8.9-beta.1; `cfx_api_version` 0.9.2; `gamepad_jni_version` 0.9.1)

This beta finishes the on-screen keyboard so it works on every screen, adds Quick Text and sent history to ChatScreen, ships Android launcher support, and backports the whole thing to 1.19.2, 1.18.2, 1.16.5, 1.12.2 and 1.10.2. Profiles migrate to v5 on first launch; #9 (PlayStation glyphs) and #10 (the water jump) are fixed.

---

## 1. On-Screen Keyboard (OSK)

The board is no longer a ChatScreen-only dock: ChatScreen keeps its embedded keyboard, and every other screen gets a floating layer that opens on whatever text field has focus.

- The layer never swaps `mc.screen`. Screen-event listeners (JEI and friends) keep their state while you type, and closing the board does not round-trip the host screen.
- **Six-tier avoidance placement** (`KeyboardPlacement`), recomputed per frame from the served field: bottom-center, dock right, dock left, split halves, raised above a thin strip, and a bottom-center + mirror fallback. The field gap is fixed at **6 px** (`KeyboardPlacement.FIELD_GAP`), and the board steps sideways around other text fields — JEI's filter bar, our own settings cards — or floats above one too wide to step around.
- **Modal while open:** off-panel clicks close the board and are swallowed, so a host widget (the JEI filter included) can no longer re-pin the caret mid-typing.
- **Four styles:** QWERTY (3 rows), QWERTY (4 rows), A–Z (3 rows), A–Z (4 rows). `KeyboardStyle.DEFAULT` is the four-row board; the `"qwerty"` style id still means three rows.
- **Size:** a global multiplier from **0.3× to 2.0×**, plus one notch past the top that fills the dock width (`onScreenKeyboard.keyboardScale`, default **1.0**). ChatScreen can override size and style per screen.
- **Keycap bindings** live in `bindings.json`; an open board owns the buttons its keycaps use (GUI-layer virtual-KBM bindings included), so one press cannot act twice.
- **Held virtual-KBM keys repeat:** a HOLD slot now emits PRESS → REPEAT → RELEASE like a physical keyboard — first repeat after 10 ticks, then every tick — so a held backspace deletes continuously. Mouse keys and pure modifier keys are excluded.
- **Field rects go through the draw transform:** our auto-scaled pages hand out logical-space rects, so the board places against the rect a field really occupies; a scaled or scrolled page no longer leaves the keyboard on a phantom position.
- **Entry points:** focus tracking (including widgets that own their `EditBox`), the pointer-click opener, and `KeyboardLayer.tryOpen`.
- **Settings:** Other → On-Screen Keyboard — enable switch, style, size, chat history limit, quick text and the keycap bindings. The hidden layout test page behind About is gone; `KeyboardLayoutTestScreen` is reachable from tests only.

---

## 2. ChatScreen: Layouts, Quick Text and Sent History

- **Four dock layouts:** Default (hint bar + lists), No hints, Keyboard + hints, Minimal. History and quick text stay editable in the settings page even when a layout hides them in-game.
- **Per-screen size and fonts:** keyboard size override plus font scale for the input field, sent history, quick text, suggestions, action hints and chat messages (`chat.json`).
- **Sent history:** sent lines only, **1–50** entries (default **10**), and any line can be pushed into the quick-text list.
- **Quick Text:** pre-written lines; selecting one only fills the field and never sends. The edit popup moves an entry to the top, reorders it, or deletes it.
- **List navigation** from the pad: focus switching between keyboard, history, quick text and suggestions, list selection, long-press edit, and auto-show for truncated entries.
- **Chat page settings** (Key Mapping → Screen Layer Mapping → ChatScreen): chat, backspace, cursor, autocomplete and list navigation rows with the usual pad / mode / Reset / Clear chrome, plus a Replace / Append input mode.

---

## 3. Android Support

- **Launchers:** ZalithLauncher2 > 2.7 and FoldCraftLauncher >= 1.3.4.0 work today; MojoLauncher and Amethyst need their next release.
- **One SDL instance — the launcher's.** The old failure was `sdl3 is not found`: the native loader picked a platform directory from `os.name` / `os.arch`, Android launchers report `os.name=Linux` + `aarch64`, and the desktop glibc build cannot load. cfx-gamepad-jni **0.9.1** resolves the launcher's own `libSDL3.so` from `POJAV_NATIVEDIR` instead of loading a second copy.
- **Same jar as desktop.** The mod only bundles `libgamepadjni.so` for arm64-v8a, armeabi-v7a and x86_64; there is no separate Android build.
- **Host detection:** gamepad-jni exposes `HostPlatform`, read once as `OS.HOST` / `OS.IS_ANDROID` / `OS.IS_MOBILE`.
- **Mobile cursor:** the "system" cursor style is skipped on mobile (launchers cannot hide their overlay cursor yet), and opening a GUI seeds the gamepad cursor at the window center instead of reading the OS position.

---

## 4. Version Coverage and Backports

- **1.20.1** (Fabric / Forge): Forge builds older than 47.3.10 start again — the mod class now offers the no-arg constructor FML looks up; keycap glyphs and words share one size and one centre line.
- **1.21.1 / 1.21.11 / 26.1.2 / 26.2 / 26.3** (Fabric / NeoForge): the same keyboard and chat work; 1.21.1 has no LWJGL SDL3, so it initializes the bundled one.
- **1.19.2 / 1.18.2 / 1.16.5** (Fabric / Forge): the EditBox mixins target vanilla's declared methods (these versions declare the input methods on the interface, where injection does not apply), a captured modifier is paired across the two capture steps, and the chat bottom offset uses composable injectors.
- **1.12.2** (Forge): synthetic screen keys impersonate LWJGL2's keyboard event state, synthetic clicks route through the screen's own `handleMouseInput`, mod key bindings re-scan on the first client tick, and the wheel scrolls an open filter popup instead of the page.
- **1.10.2** (Forge): a physical click on a field no longer opens the OSK, and the JEI compat data is aligned with the real 1.10.2 jar.
- **Dependencies:** `cfx-api` **0.9.2** drops the `IInputInjector` SPI (the remaining surface — `ICameraLookConsumer`, `setInteractiveContextRegistrar`, `VERSION` — is unchanged); `cfx-gamepad-jni` **0.9.1** carries the launcher-SDL3 resolution and the Android natives.

---

## 5. Config Migration v4 → v5

- `ProfileV5Step` runs after v4 in `MigrationGate` and seeds two defaults only where nothing is lost: `chat` = `dpadLeft|PRESS` on the main layer, and `key.keyboard.backspace` = `rightTrigger` on the GUI layer.
- A default lands only when the action slot is empty **and** the button has no standalone binding on that layer; combos do not block, disabled virtual-KBM slots do not occupy, and malformed data is left untouched.
- The step stamps version **5** even when it seeds nothing, so a second run is a no-op; the usual pre-migration backup still runs.
- `templateMeta.version` is 5 in all three templates. `ProfileV4Step` keeps writing 4 explicitly, so v2 sources still walk v3 → v4 → v5.
- `cfx-client.json` keeps the keyboard settings in `onScreenKeyboard.*` (`enabled`, `keyboardScale`). The unreleased `virtualKeyboard.*` block is ignored — no compatibility shim was kept.
- `chat.json`: a legacy `styleOverride: "inherit"` reads as "follow the global style"; unset now means follow, and choosing Follow Global deletes the stored style instead of writing a flag.

---

## 6. Fixes

- **#9 — PlayStation glyphs and names.** Auto glyph skin now resolves from the last connected pad (persisted in the selection config) and classifies Sony hardware by VID, so a PS4 pad no longer borrows the PS5 or Xbox look. Names follow the skin too: Create on DualSense / PS5, SHARE on DualShock / PS4.
- **#10 — one-shot jump in water.** PRESS / TAP / RELEASE / LONG_PRESS / DOUBLE_* released `keyJump` after a single tick, while vanilla spends only a *held* jump on the fluid swim-up. The press is now sustained until vanilla stops consuming it — out of the fluid, no longer affected by fluids, or shallow enough for the ground jump — or the 10-tick budget runs out; every cleanup path releases the synthetic key.
- A GUI-layer virtual-KBM binding no longer fires on top of the board's keycap; one RT press used to delete two characters.
- D-Pad Right no longer discards the highlighted suggestion: caret moves that cannot move the caret no longer notify the responder, so autocomplete applies the selected row.
- The keyboard opens on widgets that own their `EditBox` (Sophisticated Storage's search box), and the board no longer lands on other text fields.
- The decorative chat / EditBox injectors declare `require = 0`, so another mod overwriting a styled method costs the styling instead of crashing the client; physical-keyboard detection ignores synthetic key presses without a hardware scancode.
- 1.20.1: the suggestion list keeps a 2 px gap from the input bar, and the Delete / Clear / Done / Space keycaps draw at one shared size.

---

## 7. Defaults / Template Tuning

- On-Screen Keyboard is **enabled** by default (`onScreenKeyboard.enabled` = true), on the four-row QWERTY board at **1.0×**.
- ChatScreen follows the global style out of the box; no `styleOverride` is written, and the dock layout defaults to Default (hint bar + lists).
- Chat history limit defaults to **10** (range 1–50).
- Keycap defaults: cursorLeft = D-Pad Left, cursorRight = D-Pad Right, Space = LT, Clear = X, Delete = RT (HOLD), Done = Y — every keycap that carries a badge resolves out of the box.
- All three templates are **profile version 5**.
