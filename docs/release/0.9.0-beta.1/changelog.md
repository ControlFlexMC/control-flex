> [中文版](changelog.zh.md)

# ControlFlex 0.9.0-beta.1 Changelog

- **Version:** `0.8.9` → `0.9.0-beta.1` (`mod_version` 0.9.0-beta.1; `cfx_api_version` 0.9.2 → 0.9.2.2; `gamepad_jni_version` 0.9.4 → 0.9.6.2)

This beta makes the GUI layer somewhere you can actually live: the cursor and the virtual wheel get four speed tiers with draggable split points, every screen gets bindable action menus, the radial menu grows to 12 slots with live item status, and vehicles can be driven with the stick. Bridges get native actions and screen handlers, modpack authors get a `pack/` compat layer, and the client config migrates to v7 so an existing install keeps the feel it had. Under all of that, the bundled gamepad library learns to notice a controller plugged in on Linux, and gains a second binding for the machines where Windows blocks its native DLL. 22 jars across 13 Minecraft versions.

---

## 1. Cursor and Virtual Wheel Speed Tiers

- **Four tiers each** — `slow` / `medium` / `fast` / `full` — picked from the deadzone-normalised stick tilt. Cursor: **1–50 px/tick**, defaults **2 / 5 / 8 / 20**. Wheel: **10–500 ms** per notch, defaults **300 / 200 / 100 / 50** (smaller scrolls faster).
- **±0.03 hysteresis per input source**, so a stick resting on a boundary does not flutter between two speeds. With the default splits the full tier enters at 95 % and exits at 92 %, so a worn stick is not required to reach exactly 1.0.
- **The fixed path is untouched.** Switch tiers off and the cursor uses `cursorSpeed` with the same 0.35 per-axis threshold as before; the wheel uses `virtualWheelRepeatMs`.
- **The wheel falls back to one fixed speed by itself** when the wheel is not bound to a stick axis (a button / D-pad / trigger has no deflection to read) or when the current Screen / Overlay sets its own `virtualWheelRepeatMs`. GUI and game/overlay repeat both go through `WheelScrollSpeed`, so the two paths cannot drift.
- Config: `cursorTiers` and `virtualWheelTiers` in `cfx-client.json`.

---

## 2. Tier Split Points, Cards and Slider Colors

- **The three split points are the player's.** `split1` / `split2` / `split3` (defaults **32 / 63 / 95** %) persist in both tier sections; missing keys fall back to the defaults, so an untouched config keeps its current feel.
- **A three-handle split bar** in Cursor Settings and on the Virtual Wheel card: cool-to-warm segment colours, tier labels tinted to match, range labels updating live. Dragging clamps between neighbours and never pushes them.
- **Hysteresis follows the narrower neighbouring band** (min 0.03, or narrow band / 4), so a thin tier cannot lock up and the full tier still enters without upward hysteresis.
- **One card shape** for both: title, fixed row, tier row, description, then the four tiers. The fixed row only dims when tiers are on — it sits *above* the switch, so hiding it would move the switch under the pointer right after the click that turned tiers on. The tier block is collapsed when tiers are off; it sits below the switch and costs ~120 px that old configs would otherwise read as six dead controls. Both cards derive one label column from the widest label, so the fixed slider and the four tiers start at the same x.
- Descriptions follow the state and read the live third split point instead of hardcoding 95 %.
- **Every slider now draws through `GuiHelper.drawBoundedSlider`:** values a control cannot take are filled on both sides (`#262626`), the allowed band is grey (`#606060`), and the lower bound → knob segment carries the control's own accent — tier colours for the cursor, `#55AAFF` for the thresholds, no fill for the wheel, where the knob carries the tier colour instead. The wheel tiers mirror their bounds because a larger interval is slower; the threshold bounds follow `tap ≤ delay − step` and `delay + step ≤ long`, which is what the drag clamp already enforced.
- Copy: the wheel's two modes read 固定滚轮间隔 / 分段滚轮间隔, and its switches read 分段光标速度 / 分段滚轮间隔. The fallback hint says 某个界面 rather than 当前界面, because it is about any screen that sets its own speed.

---

## 3. Screen Action Menus

- **Up to 5 menus per screen, 12 slots each**, opened by `screen_menu_open_1..5`. Menu #1 ships bound to the Back / View button (PRESS); #2–5 are unbound and cost nothing until used.
- **A pure overlay.** No `setScreen`, no pause, no lost `hoveredSlot`: the panel draws over the screen in `post-screen-render` and leaves the container to the mod that owns it. A modal input mask keeps clicks and keys away from the screen underneath and clears its hover while the menu is up — a hidden hover target is a hazard, so hover-dependent actions are not offered inside the menu.
- **List, not radial.** A radial menu relies on spatial memory formed over many sessions; this layer holds actions used less than once a session. One line per action with the full name, scrolled with the stick, A confirms, B or releasing the trigger closes.
- **Candidates come from the screen itself:** the built-in set plus the keys the screen's own mod owns. Nothing to pre-configure, nothing to keep in sync.
- **Settings:** a Menu tab in the per-screen page with the menu list, drag reorder, name / position / height / scale, a preview page and per-pane scrolling. One action per menu, enforced in `ScreenMenu` too, so hand-edited JSON gets the same treatment; a duplicate click answers with a toast instead of being silently dropped later.
- **Layer Mapping gained "Hide inactive actions"** (on by default): the table lists only rows that can fire on this screen. Reset still walks the unfiltered set, and a row that is already bound always stays visible — a player who switched modpacks must still be able to unbind it.
- **Along the way:** one shared footer across all three tabs (the pages stop looking like they were made by different people), a back header whose hit box covers its label and not just the 12 px arrow, stick cards that size to their content, tooltips that wrap between words, and Save & exit before Keep editing in the unsaved-changes dialog.

---

## 4. Radial Menu

- **Slot cap 8 → 12**; bundled menus still start with 8 empty slots.
- **Live slot status.** `use_item` slots show the inventory count (`×N`, capped at `99+`), a missing state and an unknown state (the target id is not registered — a removed mod or a typo) instead of a blank ring. Unregistered items stay as placeholder slots so the menu keeps its shape.
- **Vanilla cooldowns** render as a hotbar-style water-level fill with seconds above it, layered over the count badge. The seconds label is dropped past 90 s, where only the fill remains.
- **Stick selection follows partial deflection:** activation at 0.20, release at 0.08 (after the deadzone), with 10 % sector hysteresis, replacing the square 0.5 gate.
- **Per-language names.** `name` stays a plain string and is the fallback every language without an override uses; `translations` maps language code to text and is ignored by builds that predate the feature, so downgrading no longer crashes them. Lookup is current language → a unique same-base sibling (`zh_tw` for `zh_cn`) → `en_us` → `name` → derived label.
- **The editor writes back where it read from:** the field seeds from the current translation or the base, and a blank field removes that entry. Derived labels are no longer prefilled or persisted and resolve at render time, so switching language updates the ring without a restart.
- **Malformed configs recover.** A `radial_menus.json` that failed to parse used to recurse load → createDefaults → load until `StackOverflowError`; it is now moved to `radial_menus.json.bak`, replaced by the bundled default and retried once. Config version is **2**, and bundled menus ship bilingual names.

---

## 5. Per-Vehicle Input Modes

- **Compat configs name the ridden entity and pick how the stick reaches it:** `vehicleInput` takes `classes` (glob, `*` only) and `mode`.
- **`ANALOG`** passes the stick through untouched. **`EIGHT_WAY`** quantizes each axis to −1 / 0 / 1 past the 0.3 threshold, which is what stops a slight tilt from being read as a full turn. **`WASD`** quantizes and then presses the player's own movement bindings through the Virtual KBM channel.
- **Why WASD exists:** some vehicles never read `Input`. Snowy Spirit's sled derives direction flags from the impulse, and Immersive Vehicles polls `glfwGetKey` directly — for those, an analog pulse is not a weaker signal, it is no signal at all.
- **Resolved per ridden entity class** from the compat layers, so one entity can be targeted without touching the global drive/ride policies. A connection-level keyboard-like policy still wins over everything.
- **Injected keys are diffed every tick and released in a `finally`**, so leaving the vehicle, opening a screen or a controller dropping cannot leave W stuck.

---

## 6. Compat Pack Layer

- **Layer order is now `default → mods → pack → user`.** `pack/` is hand-placed by modpack authors; ControlFlex never creates, writes, backs up or migrates it. Overrides are whole-file and keyed by `{mod_id}.json`, with a strict filename match — `pack/JEI.json` or `pack/jei-tweaks.json` is skipped with a WARNING.
- **Reset falls back to the nearest layer**, so a player who resets goes back to what the pack intended, not to the official default.
- **A layer whose `mod_versions` does not match is dropped instead of loaded empty.** It no longer occupies the slot, lower layers take over, and the mod page shows a real adaptation instead of a blank one. This applies to all four layers, so upgrading a mod past a config's range now falls back instead of appearing "adapted but empty".
- **Key ownership now comes from every section that declares a key** — `inGameKeys` / `screenKeys` / `overlayKeys` — not just `screenKeys`. A few actions move from their `KeyMapping` category back to the mod that owns them.
- **Reset is immediate:** the lower layer goes back into the live slot without a restart, and per-key channel and per-screen overrides for that mod are cleared (only when a user file really existed).
- **Community auto-apply treats `pack/` as occupied**, so it no longer overwrites an author's intent. Known edge: a `pack/` file skipped for a version mismatch still counts as occupied — the log says so, and the player can still Apply by hand.
- **The mod detail page shows the effective config path**, so "which file is actually in use" needs no guessing: the second-to-last path segment is the layer.

---

## 7. Bridge API: Native Actions and Screen Handlers

- `cfx-api` **0.9.2 → 0.9.2.2**.
- **Native action registration.** Bridges declare actions through `IControlFlexPlugin.onRegisterActions` instead of registering pseudo `KeyMapping`s: an id in their own namespace, a display name, the adaptation group, the layers, an optional Screen/Overlay class filter and one default binding. Nothing reaches the vanilla controls screen, ids are never re-attributed by a compat config, and `BindingSerializer` keeps them out of the global GUI/overlay maps.
- **Registered ids join `getActionIds()` and resolve through `getEffectiveBinding`**, so candidate construction, suppression, double-press and the hint query reuse the existing paths instead of growing a second one. Screen / Overlay bindings live in the per-screen table the editor already owns (`user_screen_overrides.json`); a separate store gave the same concept two homes and left a saved binding unreachable at runtime.
- **Callbacks fire from the event stream, not the per-tick GUI dispatch**, so a HOLD binding triggers once and releases once instead of 20 times a second. The registration window opens around `discoverPlugins` and closes before `onControlFlexReady`; calling the registrar later throws. A captured binding is written to the action's declared target classes, not the focused one — otherwise a capture made from the settings screen would land on the settings screen.
- **Screen handlers.** `ScreenHandlerRouter` replaces `GuiBackRouter`: one table for the back press and the per-class HUD state. Back is consumed only for the focused class, a throwing handler falls through to Escape, and one handler per class is enforced rather than letting two mods fight over a press.
- **HUD toggle.** `hud_toggle` is a built-in cross-phase action (GUI / OVERLAY / GAME) that flips a per-class visible/hidden flag, persists it to `config/controlflex/screen_hud_state.json` and pushes it to the handler. The handler is notified before the write, so an apply that reports failure is not persisted; a 150 ms cooldown keeps a HOLD binding from reading as flicker.
- **Binding queries.** `ActionBindingProviderImpl` answers "which button fires this now" against the same layer the dispatcher uses, per-screen and per-overlay tables included. Configured-but-unreachable now reads as unbound, so a bridge cannot draw a hint for a button that cannot fire. `warpToGui` (park the virtual pointer on a hand-drawn highlight) and the glyph-skin peek are exposed for screen-only UIs.
- **Input.** `PhaseEdgeSeed` stops a press carried across a phase switch from firing again in the phase it opens — X bound to PRESS on both MAIN and SCREEN no longer flips a screen in and out.

---

## 8. Config Migration v6 → v7

- `CfxV7Step` pins `cursorTiers` and `virtualWheelTiers` to `enable = false` for anyone who already had config before this version, so an upgrade keeps the fixed cursor speed and the fixed wheel interval. A clean install keeps the four tiers on.
- **Old user ⟺ `profiles/*.json` exists or `cfx-client.json` exists.** `cache/`, `backup/` and `gamepad-selection.json` are runtime traces and do not count, so a machine that only kept its cache is still treated as new. The profile branch is kept on purpose: deleting `profiles/` to reset bindings leaves the cursor and camera settings in place, and that player still feels the change.
- **The predicate is evaluated before any write**, and `JsonStep.create` seeds a minimal `cfx-client.json` on first launch — without that seed, the second launch would see an existing file and misclassify every new user as an old one. It never overwrites a file that exists but cannot be parsed.
- **Each section is written complete** (four tiers + three split points) from the runtime constants, and skipped wholesale when the section already exists, so choices made in the settings panel survive.
- **The profile format does not change:** `templateMeta.version` stays **6**; only the client config goes 6 → 7. `cursorSpeed` and `virtualWheelRepeatMs` are untouched — they are what `enable = false` falls back to.
- 21 new tests and 7 fixtures cover both user classes, partial sections, corrupt JSON, the cache-only case and idempotency.

---

## 9. Bundled Runtime: cfx-gamepad-jni 0.9.6.2

Eleven megabytes of SDL3 and JNI natives travel inside this jar — about 4.4 MB once compressed — so the library they come from gets a section of its own: `0.9.4` → `0.9.6.2`, three releases, two of which are about controllers that used to disappear.

- **Linux: a controller plugged in mid-session is noticed.** SDL's Linux joystick driver only dispatches udev add/remove from `SDL_PumpEvents()` → `SDL_UDEV_Poll()`; its `Detect()` is a no-op in udev enumeration mode. This library has no SDL event loop of its own, so a pad connected while the game was running was never discovered — it appeared only after SDL was re-initialised, that is, after a restart. Enabling libudev for hidraw made that path the default. Now the existing `SDL_UpdateGamepads` entry point pumps the event loop when it runs on the SDL main thread (the host's client tick); the background poll thread keeps the plain update path, and Android is excluded because its SDL comes from the launcher APK, which owns the event loop. No new native entry points were added, so the symbol check still passes and only the Linux natives were rebuilt.
- **Windows: a blocked native library no longer means no controller.** SAC blocks unsigned binaries with no cloud reputation, which is what our own `gamepadjni.dll` is — the load fails with *"An Application Control policy has blocked this file"* / *"The publisher of gamepadjni.dll could not be verified"*. SAC has no per-file allow: Defender exclusions, a self-signed certificate and a WDAC supplemental policy all do nothing, so the old choice was "turn SAC off, or play without a controller". **0.9.6.2 adds a second binding instead.** JNI is tried first; if it cannot load, the same SDL3 is bound through JNA direct mapping, using the JNA copy the game already ships. On the machine that reported this, the controller works with Smart App Control left on. (SAC can also block `SDL3.dll` itself; that case is not solved here.)
- **The JNI load is probed, not trusted.** `System.load` only runs `JNI_OnLoad`: a binary whose exported names lag the Java side still loads and then throws on every call. After loading, the library calls `SDL_GetVersion()`; a stale binary fails the probe and takes the JNA path instead of silently ending up with no gamepad.
- **Nothing above the backend changes.** `GamepadJNI`, `Gamepad`, `GamepadManager`, `SystemCursor` and `Sdl3Source` keep their signatures — a process that loads the JNI bridge never touches the JNA code, and no call site in any of ControlFlex's 12 version repos had to change.
- **JNA is not packaged.** It is a `compileOnly` dependency, compiled against **3.4.0** and compatible up to 5.17.0, so the jar does not grow and no new runtime dependency appears. Every Minecraft version from 1.8.9 on already ships JNA (1.20.1 has 5.12.1), so the fallback works out of the box there. 1.7.10 ships none: both paths fail, and the error says why.
- **1.7.10 can still be rescued** by putting a JNA jar where the game class loader sees it — `-Xbootclasspath/a:/path/to/jna-5.12.1.jar` in the launcher's JVM arguments. The probe runs through `Class.forName`, which delegates to the boot class path, so the fallback engages with no configuration change.
- **Failures are named.** When neither backend works, the error is three labelled segments — `JNI:` the load failure, `JNA:` either "not on the classpath, this version ships no JNA" or its own exception, and a `hint:` that points at SAC when the JNI message says an Application Control policy blocked the file. Not one line of "Failed to load native library".
- **Backend switch for troubleshooting:** `-Dcfx.gamepadjni.binding=jni|jna|auto`, or `CFX_GAMEPADJNI_BINDING` when the property is absent. `jni` never falls back, `jna` never tries JNI, `auto` is the default; anything unrecognised behaves like `auto` and is logged once.
- **What the JNA path does differently:** strings are decoded as UTF-8 by hand — JNA's default is the platform encoding, GBK on a Chinese Windows, which used to mojibake pad names and error text. The Windows cursor goes through `user32.ShowCursor` and degrades to cursor-only when it cannot bind. SDL's log capture stays JNI-only on purpose: a JNA `Callback` would be invoked from SDL's internal log lock, possibly off the Java thread, which is the deadlock the native ring buffer exists to avoid.
- **0.9.6 itself** is the first release built entirely by CI with reproducible archives, a `GLIBC_2.29` Linux floor and a pinned Android NDK — all 13 bundled natives are byte-identical to the published jar.

---

## 10. Version Coverage and Backports

- **22 jars across 13 versions:** 1.7.10, 1.8.9, 1.10.2, 1.12.2 (Forge); 1.16.5, 1.18.2, 1.19.2, 1.20.1 (Fabric / Forge); 1.21.1, 1.21.11, 26.1.2, 26.2, 26.3 (Fabric / NeoForge).
- **The Java 8 trees carry the same feature set.** The v7 gate and its tests were downlevelled to Java 8, and the fork test builds its JSON entries through `JsonPrimitive` where the older Gson has no `add(JsonElement)` overload.
- **Pre-1.13 versions were shipping the `.lang` file 109 keys short**; those keys are in the jar now.
- **Dependencies:** `cfx-api` **0.9.2.2** (screen handlers, binding queries and cursor warp in 0.9.2.1; native action registration in 0.9.2.2); `cfx-gamepad-jni` **0.9.4 → 0.9.6.2** — see §9 for what that buys.
- **The jar's bundled-library section** in the description source now lists cfx-gamepad-jni 0.9.6.2 and the SDL3 shared libraries with source and release links and the platforms each one covers — the origin of every native file is answerable.

---

## 11. Fixes

- **macOS: the cursor stayed invisible** after switching from the controller to the keyboard/mouse in a menu. Two defects stacked. `restoreSystemCursor()` returned early whenever no Screen was open — true for the cursor *mode*, false for the *image*: on macOS/Linux the OS cursor is hidden by a transparent GLFW cursor texture that vanilla never swaps back, so it survived the GUI close and the next `releaseMouse()` painted an invisible cursor. And the restore ran one tick after the real event, when GLFW's cocoa backend only applies `glfwSetInputMode()` / `glfwSetCursor()` while it believes the pointer is inside the content area — so the deferred restore could be a silent no-op. The restore is now one pure plan (image / mode / forced refresh): the image always goes back to the arrow, the mode goes to NORMAL unless the in-game grab is held, and on non-Windows focused windows a same-position `glfwSetCursorPos()` forces `updateCursorImage()` without moving the pointer. `reset()`, `ensureActivated()`, `applyCursorMode()` and the real-mouse mixin share the plan, so real mouse input also clears a stale transparent texture. Diagnostics appear only with `"bugReporting": true`.
- **Fabric: per-screen compat was dead on vanilla screens.** Config keys are Mojmap class names while `getClass().getName()` returns the intermediary name (`net.minecraft.class_490`), so screen menus, layer mapping, stick mode, cursor style, per-screen wheel speed and per-screen overrides all matched nothing — and it showed as "the config is written but has no effect". `ScreenFqns` translates the runtime class name to the config identity from an alias table built out of class literals (loom remaps them per version, so there is no hand-kept `class_XXXX` table), and all six call sites go through it, including the screen-menu session identity — open and tick must agree or the menu closes itself on the next tick. `ScreenFqnsTest` fails when a screen key shipped in `minecraft.json` has no runtime alias. A configured menu whose slots are all filtered out now logs instead of staying silent.
- **The first edit in a compat config wiped everything inherited.** Layers override whole files, so adding one Screen adaptation to JEI wrote an empty skeleton and dropped its 22 `ignoreKeys` and 9 `screenKeys`, taking every JEI action out of the screen menus. `ensureUserFile` now forks the currently effective config into `user/` before applying the edit, read verbatim from disk so `mod_name`, `home_page`, `translations` and fields this build does not know survive. An existing user file is still used as-is; the fork happens once, after which the file is the player's asset. `exportUserJson` exports the same fork.
- **Chords on `delete_text` (RT by default) were dropped while a text field had focus.** `delete_text` captures its button so one press cannot also fire another action — but the capture was decided per *button*, so any binding that merely shared a captured button lost GUI candidacy as a whole. With the shipped profile that silently killed every chord built on RT, JEI's Show Recipe / Show Uses (RT+dpadLeft / RT+dpadRight) among them, and only while a field was focused. `DeleteTextCapture.captures()` is now `swallows()`: a binding yields only when the captured set covers **all** of its buttons; a longer chord is a different, more specific press, and the combo engine's existing UPGRADE destroys the RT-sized victims. A single-button action on a captured button still yields — the X = clear keycap case is why the capture exists. Trade-offs, all already true with no focused box: the RT press still deletes one character before the chord completes, and once a chord has destroyed the delete combo, holding RT no longer repeats until it is pressed again. While the on-screen keyboard is open, the older keycap-ownership rule still drops chords on keycap buttons — B closes the keyboard and keeps the focus, and the chord works from there.
- **Tier sliders disagreed with their own bounds.** The tier rows painted red the narrow band between a value and its neighbour and grey the part that is actually unreachable, the wheel panel had no red at all, and the three threshold cards repeated the same inverted red with two wrong bounds. All of them now go through one helper; the wheel tiers mirror their bounds because a larger interval is slower, and the threshold bounds follow `tap ≤ delay − step` and `delay + step ≤ long`.

---

## 12. Defaults / Template Tuning

- Cursor tiers **on** by default for new installs, at **2 / 5 / 8 / 20** px/tick with splits **32 / 63 / 95**. Existing installs migrate with tiers **off** (v7).
- Virtual wheel tiers **on** by default for new installs, at **300 / 200 / 100 / 50** ms per notch.
- `screen_menu_open_1` = **Back / View, PRESS**; `screen_menu_open_2..5` unbound. `hud_toggle` is declared and deliberately unbound — without the empty entry the GUI candidate table never iterates it, and a per-screen binding would be stored and shown but never dispatched.
- All three templates are still **profile version 6**, and every one of them now carries explicit `hud_toggle` entries in each layer with a shift layout; the conformance test requires every shift-relevant action to be listed.
- Built-in compat sources pin to the **0.9.0** tag — the release tag is `0.9.0`, not `0.9`, because jsDelivr and raw.githubusercontent both 404 on the short form. Existing `sources.json` files are re-pinned on the next client init, with a backup and without touching user sources.
