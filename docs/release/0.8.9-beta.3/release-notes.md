> [中文版](release-notes.zh.md)

# Control Flex 0.8.9-beta.3

**Features:**

- Delay and long-hold trigger tiers — DELAY_PRESS / DELAY_HOLD / LONG_HOLD on a new global `delayPressMs` boundary (tap = dodge, hold = crawl, no flicker on a short tap)
- `delete_text` action replaces the virtual backspace key — deletes from the focused field without tripping mods bound to Backspace; profiles migrate to v6

**Fixes:**

- hold-to-open mod menus (Effortless Building, MineMenu) no longer flicker shut when a GUI opens
- 1.12.2: mixin tolerance restored — packs with another MixinTweaker (All the Mods 3, Enigmatica 2, Omnifactory) boot again; the mod no longer goes silently unmixed
- OSK: keycap labels sized from the keycap cell (legible on phone landscape); the card draws above modal hosts like the radial Edit Slot
