> [中文版](release-notes.zh.md)

# Control Flex 0.9.0-beta.1

**Features:**

- Four-tier cursor and virtual wheel speed — slow / medium / fast / full by stick tilt, with draggable split points (off for existing installs until enabled in settings, on by default for new ones)
- Per-screen action menus — up to 5 menus × 12 actions, drawn as an overlay, no extra keymap
- Radial menu — 12 slots, live item counts, missing / unknown state, cooldown fill
- Per-vehicle input modes — analog / eight-way / WASD, declared in compat config
- Bridge API 0.9.2.2 — native action registration, screen handlers, binding queries

**Fixes:**

- Windows: SDL3 is reachable through both JNI and JNA, so a controller is still recognised after Windows 11 SAC blocks gamepadjni.dll while it lacks reputation
- Linux: hot-plugged controllers are recognised, no MC restart needed
- macOS: the cursor no longer stays invisible after leaving the controller for the mouse in a menu
- The first edit in a compat config no longer drops the keys it inherited
