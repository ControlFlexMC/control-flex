> [中文版](release-notes.zh.md)

## Control Flex 0.8.7

This version represents a major effort to make Control Flex more adaptable to a wider variety of mods. Although I've done my best to keep existing local configurations working, there is still a chance that some settings from previous versions may break. If that happens, I apologize in advance — most issues can be resolved by reconfiguring the affected bindings.

### Features

*   Overlay layer — dedicated controller bindings while interactive HUDs are open (spell wheels, radial menus, and similar overlays), separate from both gameplay and inventory screens.
*   Mod Adaptation center — per-mod Screen and Overlay rules, including stick modes such as radial path, cursor speed, and show/hide cursor.
*   Community config repo — add remote sources, then sync, browse, preview, and apply shared compatibility configs. Local configs can also be imported and exported.
*   Virtual keyboard & mouse — map controller buttons to real keyboard and mouse keys (including Shift, Page Up/Down, Escape, and the scroll wheel) on any layer.
*   Container slot navigation — D-Pad jumps the cursor between inventory and container slots. The left stick still moves the cursor freely.
*   Key Mapping overview redesigned around seven layers (Main, Shift 1–4, Screen, Overlay) plus a keyboard/mouse column.
*   Open Settings from the controller (Back + Start) or keyboard (F9). Radial menus 1–5 are registered as Control Flex key mappings.
*   Existing 0.8.6.x configs are migrated automatically on first launch (profiles, compat files, and client settings). Originals are copied under `config/controlflex/backup/`.

### Fixes

*   JEI Show Recipe / Show Uses now fire from the controller on Fabric.
*   Fixed a crash when loaded together with simplyusekey (`releaseUsingItem` mixin conflict).
*   Fixed an instant crash when cycling the hotbar with L1/R1 on NeoForge (`MouseScrollingEvent` constructor mismatch).
*   Fixed controllers not being recognized after a disconnect or unplug (including Xbox wireless adapter / dongle reconnect).



### Tuning

*   Overlay defaults now follow the in-game layout (move, look, attack, use, jump, scroll), so opening an overlay feels like playing rather than opening a chest.
*   The mouse wheel can be bound on every layer. Tap scrolls one notch; Hold repeats every 100 ms (`virtualWheelRepeatMs`).
*   Slot navigation is bound to the D-Pad by default. JEI Show Recipe / Show Uses moved to RT + D-Pad so they no longer fight slot jump.
