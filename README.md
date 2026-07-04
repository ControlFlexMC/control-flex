# ControlFlex

**Flexible Controller Mapping for Minecraft Java Edition**

[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange?logo=curseforge)](https://www.curseforge.com/minecraft/mc-mods/control-flex)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.20.1-blue)](https://www.minecraft.net/)

[中文文档](README_zh.md)

ControlFlex is a controller mod designed for mid-to-large modpacks. The name says it all: **Control + Flex** — flexible, extensible controller input. Through a 6-layer binding architecture, 5 trigger modes, combo keys, radial menus, and cross-layer mappings, it turns a limited set of buttons into broader coverage of actions.

> ⚠️ **Source Code Notice:** ControlFlex is planned to be open-source. The source code will be published in this repository in the coming months. In the meantime, this repo serves as the official home for **issue tracking, feature requests, and documentation**.

## Supported Versions

Download the latest release from **[CurseForge](https://www.curseforge.com/minecraft/mc-mods/control-flex)**.

| Minecraft | Forge | NeoForge | Fabric |
| --------- | ----- | -------- | ------ |
| 1.20.1    | ✅     | —        | ✅      |
| 1.21.1    | —     | ✅        | ✅      |
| 1.21.11   | —     | ✅        | ✅      |
| 26.1.2    | —     | ✅        | ✅      |
| 26.2      | —     | ✅        | ✅      |

## Features

- **6-Layer Binding Architecture** — Main / Shift 1–4 / GUI / Cross-layer, multiplying available bindings
- **5 Trigger Modes** — Press, Release, Hold, Tap, Long Press for fine-grained input control
- **Combo Key Engine** — Simultaneous multi-button press detection with priority-based upgrade rules
- **Radial Menu System** — Up to 5 menus × 8 slots; supports key bindings, commands, and use-item actions
- **Rumble Feedback** — 7 vibration waveform modes with per-damage-type configuration
- **Camera & Cursor Control** — Right stick camera with sensitivity/Y-invert; left stick virtual mouse with slot snapping
- **Deadzone Calibration** — Per-axis auto-calibration for sticks and triggers with real-time visualization
- **Template System** — Built-in presets (Default, Bedrock, TaCz, Epic Fight, etc.) with user profile management
- **Mod Compatibility** — Automatic detection and binding of modded KeyMappings via JSON compat configs
- **Multi-Controller Support** — Hotplug detection, auto-selection, per-controller profiles
- **Multi-Loader** — Supports Forge, NeoForge, and Fabric across multiple Minecraft versions
- **Pinyin Search** — Filter bindings and items by Chinese pinyin input

## Requirements

| Component       | Version                                    |
| --------------- | ------------------------------------------ |
| Minecraft       | 1.20.1 / 1.21.1 / 1.21.11 / 26.1.2 / 26.2  |
| Forge Loader    | 47.4.4+ (1.20.1)                           |
| NeoForge Loader | 21.1.233+                                  |
| Fabric Loader   | 0.16.10+                                   |
| Java            | 17+ (1.20.1) / 21+ (1.21+) / 25+(1.21.11+) |
| SDL3            | Bundled (Windows / Linux / macOS)          |

## Installation

1. Download the latest release JAR for your Minecraft version and loader (Forge / NeoForge / Fabric) from [CurseForge](https://www.curseforge.com/minecraft/mc-mods/control-flex)
2. Place it in your Minecraft `mods/` folder
3. Launch Minecraft
4. Connect your controller — ControlFlex auto-detects it via SDL3

## Issues & Feedback

🐛 **Found a bug?** [Open an issue](../../issues/new?template=bug_report.md)

💡 **Have a feature request?** [Share your idea](../../issues/new?template=feature_request.md)

All bug reports, feature requests, and feedback are tracked through **GitHub Issues**. Please avoid using CurseForge comments for issue reporting — they are difficult to track and follow up on.

Before submitting, please:

- Search [existing issues](../../issues) to avoid duplicates
- Use the issue template that matches your report
- Provide as much detail as possible (Minecraft version, loader, controller model, steps to reproduce)

## Configuration

All configuration files are stored in `config/controlflex/`:

```
config/controlflex/
├── templates/          # Built-in and custom binding templates
├── profiles/           # User modification profiles
├── compat/             # Per-mod compatibility JSON configs
├── radial_menu/        # Radial menu configurations and icons
└── cfx-client.json     # Global client state
```

## Supported Controllers

Tested with:

- Xbox One Controller
- Xbox Elite 2 Controller (with paddle/back button support)

ControlFlex uses SDL3 for gamepad input, which supports a wide range of controllers in theory. However, only the above models have been verified. If you have tested other controllers successfully, please [share your experience](../../issues) — it helps expand the known-compatible list.

## License

This project is licensed under the [MIT License](LICENSE). SDL3 is bundled under the [zlib License](LICENSE_SDL3).

## Credits

- **[SDL3 Library](https://github.com/libsdl-org/SDL)** — Cross-platform input foundation
- **[gamepad-jni](https://github.com/ifels/gamepad-jni)** — JNI bridge for SDL3 gamepad API
- **[TinyPinyin](https://github.com/promeG/TinyPinyin)** — Chinese pinyin conversion for search
- **[Controlify](https://github.com/isXander/Controlify)** — Design inspiration
- **[Controllable](https://github.com/MrCrayfish/Controllable)** — Design inspiration

---

*ControlFlex — Flex your controller, master every mod.*
