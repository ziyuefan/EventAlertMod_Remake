# EventAlertMod Retail Rewrite: AI Context

## Project Summary

EventAlertMod (EAM) is a World of Warcraft addon for lightweight aura,
cooldown, and item cooldown alerts. Its identity is simple: show important
spell and item states as readable icons without becoming a WeakAuras clone.

This rewrite targets World of Warcraft Retail only, with Retail 12.x /
Midnight-era APIs as the intended generation. Existing Classic, Mists Classic,
Cata Classic, Wrath Classic, TBC, Era, and region-specific Classic branches are
behavior history only and must not shape the new architecture.

## Rewrite Direction

The current source tree preserves years of behavior but mixes compatibility
branches, UI construction, aura scanning, cooldown logic, item-cache generation,
special resources, slash commands, globals, localization, and frame layout in
the same runtime surface. The rewrite should keep useful data and user-facing
semantics while replacing the internals with explicit modules.

Required target modules:

- `Core/Env.lua`
- `Core/Util.lua`
- `Core/Constants.lua`
- `Core/EventRouter.lua`
- `Core/Scheduler.lua`
- `Core/SavedVariables.lua`
- `Core/Performance.lua`
- `Services/AuraService.lua`
- `Services/CooldownService.lua`
- `Services/ItemCooldownService.lua`
- `Services/SpellInfoService.lua`
- `UI/IconPool.lua`
- `UI/Renderer.lua`
- `UI/Options.lua`
- `UI/Slash.lua`
- `Debug/DebugState.lua`
- `Debug/PromptExport.lua`

## Non-Negotiable Boundaries

- No secret value bypass.
- No protected data bypass.
- No combat automation.
- No external dependencies.
- No complex user scripting engine.
- No heavy always-on scanning.
- No timer-per-icon, timer-per-spell, or timer-per-project architecture.

## Simplicity Principle

EAM should remain easy for normal users: add spell IDs, enable alerts, see
icons, adjust a small set of display options, and export a compact debug state
only on demand.

## Existing Discussion Anchor

Prior ChatGPT discussion context exists at:

- `DevDocument/ChatGPT/EventAlertMod_ChatGPT_Discussion_Context.md`

Important historical points from that file:

- EAM is not Ace3 based.
- Current TOC uses `RequiredDeps: !Lib_ZYF`, but the rewrite goal is no new
  external dependency.
- `/eam opt` is the documented settings command.
- Existing behavior includes self aura, target aura, spell cooldown, item
  cooldown, tooltip spell/item IDs, localization, and optional debug helpers.
- Older work already touched `Main/EventAlert_EAFun.lua` as a compatibility
  facade. Future agents must not assume that file is the final architecture.

## First-Pass Audit Result

`Docs/01_ARCHITECTURE.md` contains the current file map and module
responsibilities. `Docs/03_STATE_SCHEMA.md` contains SavedVariables and global
state anchors. `Docs/05_PERFORMANCE_GUIDE.md` contains hot path candidates,
OnUpdate/C_Timer usage, and allocation risks. `Docs/07_MIGRATION_NOTES.md`
contains behavior migration notes.
