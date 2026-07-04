# ControlFlex

**Minecraft Java 版灵活手柄映射模组**

[![CurseForge](https://img.shields.io/badge/CurseForge-下载-orange?logo=curseforge)](https://www.curseforge.com/minecraft/mc-mods/control-flex)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.20.1-blue)](https://www.minecraft.net/)

[English](README.md)

ControlFlex 是一款专为中大型整合包设计的手柄控制模组。名字即理念：**Control + Flex** —— 灵活、可扩展的手柄输入。通过 6 层绑定架构、5 种触发模式、组合键、径向菜单和跨层映射，让有限的按钮覆盖更多操作。

> ⚠️ **源码说明：** ControlFlex 计划开源，源代码将在未来几个月内发布到此仓库。在此期间，本仓库作为**问题跟踪、功能请求和文档**的官方主页。

## 支持的版本

从 **[CurseForge](https://www.curseforge.com/minecraft/mc-mods/control-flex)** 下载最新版本。

| Minecraft | Forge | NeoForge | Fabric |
| --------- | ----- | -------- | ------ |
| 1.20.1    | ✅     | —        | ✅      |
| 1.21.1    | —     | ✅        | ✅      |
| 1.21.11   | —     | ✅        | ✅      |
| 26.1.2    | —     | ✅        | ✅      |
| 26.2      | —     | ✅        | ✅      |



## 核心特性

- **6 层绑定架构** — Main / Shift 1–4 / GUI / 跨层，成倍扩展可用绑定
- **5 种触发模式** — Press / Release / Hold / Tap / Long Press，精细控制输入
- **组合键引擎** — 多按钮同时按下检测，优先级升级规则
- **径向菜单系统** — 最多 5 个菜单 × 8 个格子；支持按键绑定、指令、使用物品
- **震动反馈** — 7 种振动波形模式，按伤害类型独立配置
- **视角与光标控制** — 右摇杆视角控制（灵敏度/Y轴反转）；左摇杆虚拟鼠标（吸附效果）
- **死区校准** — 按轴自动校准摇杆和扳机，实时可视化
- **模版系统** — 内置多种预设（Default/Bedrock/TaCz/Epic Fight 等），用户配置管理
- **模组兼容** — 自动检测并绑定其他模组的 KeyMapping，JSON 兼容配置
- **多手柄支持** — 热插拔检测、自动选择、按手柄隔离配置
- **多加载器** — 同时支持 Forge、NeoForge 和 Fabric，覆盖多个 Minecraft 版本
- **拼音搜索** — 支持拼音首字母筛选绑定和物品

## 环境要求

| 组件            | 版本                          |
| ------------- | --------------------------- |
| Minecraft     | 1.20.1 / 1.21.1 / 1.21.11   |
| Forge         | 47.4.4+ (1.20.1)            |
| NeoForge      | 21.1.233+                   |
| Fabric Loader | 0.15.11+                    |
| Java          | 17+（1.20.1）/ 21+（1.21+）     |
| SDL3          | 内置（Windows / Linux / macOS） |

## 安装方法

1. 从 [CurseForge](https://www.curseforge.com/minecraft/mc-mods/control-flex) 下载对应 Minecraft 版本和加载器（Forge / NeoForge / Fabric）的最新版 JAR 文件
2. 放入 Minecraft 的 `mods/` 文件夹
3. 启动 Minecraft
4. 连接手柄 — ControlFlex 通过 SDL3 自动检测

## 问题与反馈

🐛 **发现 Bug？** [提交 Issue](../../issues/new?template=bug_report.md)

💡 **有功能建议？** [分享你的想法](../../issues/new?template=feature_request.md)

所有 Bug 报告、功能请求和反馈都通过 **GitHub Issues** 跟踪。请尽量避免在 CurseForge 评论区提交问题 — 评论不便于跟踪和后续处理。

提交前请注意：

- 先搜索[已有 Issues](../../issues)，避免重复提交
- 使用对应的问题模版
- 尽可能提供详细信息（Minecraft 版本、加载器、手柄型号、复现步骤）

## 配置文件

所有配置文件存储在 `config/controlflex/`：

```
config/controlflex/
├── templates/          # 内置和自定义绑定模版
├── profiles/           # 用户修改配置
├── compat/             # 按模组兼容 JSON 配置
├── radial_menu/        # 径向菜单配置和图标
└── cfx-client.json     # 全局客户端状态
```

## 支持的手柄

已测试：

- Xbox One 手柄
- Xbox Elite 2 手柄（支持背键/拨片）

ControlFlex 使用 SDL3 进行手柄输入，理论上支持广泛的游戏手柄。但目前仅上述型号经过实际验证。如果你在其他手柄上测试成功，欢迎[分享你的经验](../../issues)，帮助扩展已知兼容列表。

## 许可证

本项目使用 [MIT 许可证](LICENSE)。SDL3 以 [zlib 许可证](LICENSE_SDL3) 内置分发。

## 致谢

- **[SDL3 库](https://github.com/libsdl-org/SDL)** — 跨平台输入基础
- **[gamepad-jni](https://github.com/ifels/gamepad-jni)** — SDL3 手柄 API 的 JNI 桥接
- **[TinyPinyin](https://github.com/promeG/TinyPinyin)** — 中文拼音转换（搜索功能）
- **[Controlify](https://github.com/isXander/Controlify)** — 设计灵感
- **[Controllable](https://github.com/MrCrayfish/Controllable)** — 设计灵感

---

*ControlFlex — 灵活操控，掌控每一个模组。*
