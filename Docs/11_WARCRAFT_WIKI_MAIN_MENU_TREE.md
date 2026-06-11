# Warcraft Wiki Main Menu 三層遍歷筆記

本文件補足 `API_change_summaries` 頁面左側 `Main Menu` 的樹狀遍歷。

目標不是複製整站內容，而是建立 EAM Retail rewrite 需要的導覽索引：

- 第一層：`Main Menu` 入口。
- 第二層：入口頁的主要分類或索引方向。
- 第三層：代表性 API / 文件頁。
- 第四層：與 EAM rewrite 的實作結論。

## 來源入口

- https://warcraft.wiki.gg/wiki/WoW_API
- https://warcraft.wiki.gg/wiki/Lua_functions
- https://warcraft.wiki.gg/wiki/FrameXML_functions
- https://warcraft.wiki.gg/wiki/Widget_API
- https://warcraft.wiki.gg/wiki/Widget_script_handlers
- https://warcraft.wiki.gg/wiki/XML_schema
- https://warcraft.wiki.gg/wiki/Events
- https://warcraft.wiki.gg/wiki/Console_variables
- https://warcraft.wiki.gg/wiki/Macro_commands
- https://warcraft.wiki.gg/wiki/Combat_Log
- https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT_UNFILTERED
- https://warcraft.wiki.gg/wiki/UI_escape_sequences
- https://warcraft.wiki.gg/wiki/Hyperlinks
- https://warcraft.wiki.gg/wiki/API_change_summaries
- https://warcraft.wiki.gg/wiki/HOWTOs

## Tree Overview

```text
Warcraft Wiki Main Menu
├─ WoW API
│  ├─ API systems
│  │  ├─ C_UnitAuras
│  │  ├─ C_Spell
│  │  ├─ C_Item / C_CVar / C_TooltipInfo
│  │  └─ C_Secrets
│  ├─ API categories
│  │  ├─ API functions
│  │  ├─ API events
│  │  ├─ API types
│  │  └─ API systems
│  └─ EAM relevance
│     ├─ AuraService
│     ├─ CooldownService
│     ├─ ItemCooldownService
│     └─ Debug boundary checks
├─ Lua API
│  ├─ Lua 5.1 subset
│  │  ├─ basic functions
│  │  ├─ string
│  │  ├─ table
│  │  └─ coroutine
│  ├─ WoW custom Lua helpers
│  │  ├─ table.create
│  │  ├─ table.wipe
│  │  ├─ table.freeze
│  │  └─ table.isfrozen
│  └─ EAM relevance
│     ├─ low-GC policy
│     ├─ no secret tostring/string.match
│     └─ no hot-path transient tables
├─ FrameXML API
│  ├─ UIParent / panel helpers
│  ├─ Mixins and pools
│  │  ├─ CreateFramePool
│  │  ├─ CreateTexturePool
│  │  └─ CreateFontStringPool
│  ├─ SharedXML utilities
│  │  ├─ EventUtil
│  │  ├─ FrameUtil
│  │  ├─ TooltipUtil
│  │  └─ LinkUtil
│  └─ EAM relevance
│     ├─ IconPool
│     ├─ EventRouter
│     └─ Tooltip fallback isolation
├─ Widget API
│  ├─ Widget objects
│  │  ├─ Frame
│  │  ├─ Button
│  │  ├─ Cooldown
│  │  ├─ FontString
│  │  └─ Texture
│  ├─ Widget methods
│  │  ├─ ScriptObject:SetScript
│  │  ├─ Frame:RegisterEvent
│  │  ├─ Frame:RegisterAllEvents
│  │  ├─ Cooldown:SetCooldownFromDurationObject
│  │  └─ FontString:ClearText
│  └─ EAM relevance
│     ├─ Renderer
│     ├─ no RegisterAllEvents
│     ├─ no per-icon OnUpdate
│     └─ DurationObject display
├─ Widget scripts
│  ├─ Frame scripts
│  │  ├─ OnEvent
│  │  ├─ OnUpdate
│  │  ├─ OnShow / OnHide
│  │  └─ OnDragStart / OnDragStop
│  ├─ Button scripts
│  │  ├─ OnClick
│  │  ├─ PreClick
│  │  └─ PostClick
│  └─ EAM relevance
│     ├─ single EventRouter OnEvent
│     ├─ single Scheduler OnUpdate
│     └─ Options drag handling only outside hot path
├─ XML schema
│  ├─ Ui
│  │  ├─ Include
│  │  └─ Script
│  ├─ LayoutFrame
│  │  ├─ Size
│  │  ├─ Anchors
│  │  └─ Animations
│  ├─ Frame
│  │  ├─ Layers
│  │  ├─ Frames
│  │  └─ Scripts
│  └─ EAM relevance
│     ├─ reduce large XML option surface
│     ├─ avoid XML OnUpdate
│     └─ keep UI templates isolated
├─ Events
│  ├─ API events category
│  │  ├─ UNIT_AURA
│  │  ├─ SPELL_UPDATE_COOLDOWN
│  │  ├─ BAG_UPDATE_COOLDOWN
│  │  └─ PLAYER_REGEN_ENABLED
│  ├─ Event docs
│  │  ├─ payload tables
│  │  ├─ predicates
│  │  └─ restrictions
│  └─ EAM relevance
│     ├─ event-driven first
│     ├─ incremental aura handling
│     └─ out-of-combat refresh
├─ CVars
│  ├─ Console variables
│  │  ├─ GetCVar / SetCVar
│  │  ├─ C_CVar.GetCVarInfo
│  │  └─ C_CVar.RegisterCVar
│  ├─ Console commands
│  │  ├─ cvar_default
│  │  ├─ cvar_reset
│  │  └─ cvarlist
│  └─ EAM relevance
│     ├─ do not depend on user CVars for core logic
│     ├─ secret forced CVars only for live validation
│     └─ avoid protected CVar mutation in combat
├─ Macro commands
│  ├─ Character commands
│  ├─ Combat commands
│  │  ├─ cast / use
│  │  ├─ cancelaura
│  │  └─ startattack / stopattack
│  └─ EAM relevance
│     ├─ no combat automation
│     └─ slash commands are config/debug only
├─ Combat Log
│  ├─ Combat Log page
│  │  ├─ chat combat log
│  │  └─ file logging
│  ├─ COMBAT_LOG_EVENT / CLEU
│  │  ├─ payload
│  │  ├─ prefixes
│  │  └─ suffixes
│  └─ EAM relevance
│     ├─ do not use CLEU as primary 12.x data source
│     ├─ avoid blind combat parsing
│     └─ prefer UNIT_AURA / cooldown events
├─ Escape sequences
│  ├─ UI text sequences
│  │  ├─ color
│  │  ├─ texture
│  │  └─ reset
│  └─ EAM relevance
│     ├─ debug export escaping
│     ├─ tooltip text safety
│     └─ no secret string formatting
├─ Hyperlinks
│  ├─ link format
│  │  ├─ color
│  │  ├─ type:payload
│  │  └─ display text
│  ├─ inspecting
│  │  ├─ SetItemRef
│  │  └─ ExtractHyperlinkString
│  └─ EAM relevance
│     ├─ spell/item ID tooltip debug
│     ├─ import/export text safety
│     └─ no unsafe parsing of secret-derived text
├─ API changes
│  ├─ API change summaries
│  │  ├─ 12.0.0
│  │  ├─ 12.0.1
│  │  ├─ 12.0.5
│  │  └─ 12.0.7
│  └─ EAM relevance
│     ├─ target TOC/API generation
│     ├─ removed API cleanup
│     └─ live validation list
├─ HOWTOs
│  ├─ Getting Started
│  │  ├─ Introduction to Lua
│  │  └─ Create a WoW AddOn
│  ├─ UI HOWTOs
│  │  ├─ Making draggable frames
│  │  └─ frame examples
│  └─ EAM relevance
│     ├─ options UI behavior reference
│     ├─ draggable anchor handling
│     └─ avoid copying example closures into hot paths
└─ wowuidev
   ├─ historical / community API discussion entry
   ├─ related API docs / /api command references
   └─ EAM relevance
      ├─ useful as background only
      └─ not an authoritative Retail 12.x runtime contract
```

## EAM 實作導向摘要

### WoW API

`WoW API` 是主要 runtime API 入口。EAM rewrite 應優先從 API system 找到對應 namespace，而不是保留舊 global wrapper。

重要三層：

```text
WoW API
├─ API systems
│  ├─ C_UnitAuras
│  │  └─ AuraService
│  ├─ C_Spell
│  │  └─ CooldownService / SpellInfoService
│  ├─ C_Item
│  │  └─ ItemCooldownService
│  ├─ C_TooltipInfo
│  │  └─ low-frequency fallback only
│  └─ C_Secrets
│     └─ boundary checks
```

結論：

- 12.x 只用 Retail `C_*` namespace。
- `C_Secrets` 應集中封裝，不要散落在每個 UI function。
- `C_TooltipInfo` 是 fallback 資料來源，不是 hot path 事實來源。

### Lua API

`Lua API` 說明 WoW 使用 Lua 5.1 子集，且缺少 OS / file I/O library。

重要三層：

```text
Lua API
├─ basic functions
│  ├─ pcall / xpcall
│  └─ type / select
├─ string
│  ├─ string.match / gsub / format
│  └─ WoW custom string helpers
├─ table
│  ├─ table.create
│  ├─ table.wipe
│  ├─ table.freeze
│  └─ table.isfrozen
```

結論：

- `string.match` 不可用在未確認安全的 secret-derived tooltip text。
- hot path 避免 transient table、`table.insert`、大量 `pairs`。
- `table.freeze` 只用於 immutable constants。

### FrameXML API

`FrameXML functions` 包含 UI helper、pool、EventUtil、TooltipUtil、LinkUtil 等。

重要三層：

```text
FrameXML API
├─ Mixins / pools
│  ├─ CreateFramePool
│  ├─ CreateTexturePool
│  └─ CreateFontStringPool
├─ SharedXML
│  ├─ EventUtil
│  ├─ FrameUtil
│  └─ TooltipUtil
└─ UIParent / panels
   ├─ ShowUIPanel
   └─ Toggle*Frame
```

結論：

- EAM 的 `UI/IconPool.lua` 可以參考 Blizzard pool pattern。
- 不要在 combat 中呼叫會開關 protected panel 的函式。
- TooltipUtil 可作參考，但 tooltip parsing 必須低頻且 secret-safe。

### Widget API / Widget Scripts

`Widget API` 與 `Widget script handlers` 是 EAM Renderer、EventRouter、Scheduler 的基礎。

重要三層：

```text
Widget API
├─ Frame
│  ├─ RegisterEvent
│  ├─ RegisterAllEvents
│  └─ SetScript
├─ Cooldown
│  ├─ SetCooldownFromDurationObject
│  ├─ SetCountdownFormatter
│  └─ SetCountdownMillisecondsThreshold
└─ FontString
   ├─ SetText
   └─ ClearText
```

```text
Widget scripts
├─ Frame
│  ├─ OnEvent
│  └─ OnUpdate
├─ Button
│  ├─ OnClick
│  └─ PreClick / PostClick
└─ EditBox
   ├─ OnTextChanged
   └─ OnEnterPressed / OnEscapePressed
```

結論：

- `RegisterAllEvents` 只適合 debug/datamining，不適合 EAM runtime。
- EAM 只應有一個 EventRouter `OnEvent`。
- EAM 只應有一個 Scheduler `OnUpdate`。
- `Cooldown` 應承接 `DurationObject`，不要讓 Lua 每幀算秒。

### XML schema

`XML schema` 說明 XML 可以建立 UI，但 Lua Widget API 也能做多數事情。

重要三層：

```text
XML schema
├─ Ui
│  ├─ Include
│  └─ Script
├─ LayoutFrame
│  ├─ Size
│  ├─ Anchors
│  └─ Animations
└─ Frame
   ├─ Layers
   ├─ Frames
   └─ Scripts
```

結論：

- 新架構可保留簡單 XML loader，但 runtime icons 應交給 `IconPool`。
- 避免 XML 內建立大量 global frame name。
- 避免 XML `OnUpdate`。

### Events

`Events` / `Category:API events` 是 EventRouter 的事件來源。

重要三層：

```text
Events
├─ UNIT_AURA
│  ├─ unitTarget
│  ├─ updateInfo.addedAuras
│  ├─ updateInfo.updatedAuraInstanceIDs
│  └─ updateInfo.removedAuraInstanceIDs
├─ cooldown events
│  ├─ SPELL_UPDATE_COOLDOWN
│  ├─ SPELL_UPDATE_CHARGES
│  └─ BAG_UPDATE_COOLDOWN
└─ combat boundary
   ├─ PLAYER_REGEN_DISABLED
   └─ PLAYER_REGEN_ENABLED
```

結論：

- `UNIT_AURA` 增量資料是 AuraService 核心入口。
- removed aura instance ID 無法再查完整 aura，服務要先 cache 安全摘要。
- 脫戰刷新是 boundary-limited state 的校準點。

### CVars

`Console variables` 說明 CVar 可以用 `GetCVar` / `SetCVar` / `/console` 管理，部分 secure CVar 不能在 combat 改。

重要三層：

```text
CVars
├─ query
│  ├─ GetCVar
│  ├─ GetCVarDefault
│  └─ C_CVar.GetCVarInfo
├─ mutation
│  ├─ SetCVar
│  └─ /console
└─ reset
   ├─ cvar_default
   └─ cvar_reset
```

結論：

- EAM 不應依賴改 CVar 達成功能。
- secret forced CVars 只應放 live validation checklist。
- 不在 combat 中修改 secure CVar。

### Macro Commands

`Macro commands` 分為 character、combat 等指令。

重要三層：

```text
Macro commands
├─ character commands
├─ combat commands
│  ├─ cast / use
│  ├─ cancelaura
│  └─ startattack / stopattack
└─ addon slash commands
   ├─ /eam opt
   ├─ /eam debug
   └─ /eam export
```

結論：

- EAM slash commands 只能做設定、偵測、debug、匯出。
- 不新增 combat automation。
- 不產生 cast/use/cancelaura 類行為。

### Combat Log

`Combat Log` / `COMBAT_LOG_EVENT_UNFILTERED` 是歷史上常見 AddOn 資料來源，但 12.x 目標與 EAM rewrite 不應依賴盲掃。

重要三層：

```text
Combat Log
├─ Combat Log window / file
├─ COMBAT_LOG_EVENT_UNFILTERED
│  ├─ source
│  ├─ destination
│  ├─ prefix
│  └─ suffix
└─ EAM boundary
   ├─ not primary source
   ├─ no heavy parsing
   └─ use event services instead
```

結論：

- 12.x 的 EAM 不以 CLEU 作為 aura/cooldown 主要來源。
- 只在必要 debug 或非 hot path 檢查時參考。
- 不建立 WeakAura-like combat parser。

### Escape Sequences / Hyperlinks

`UI escape sequences` 和 `Hyperlinks` 是 debug text、tooltip、import/export 的風險區。

重要三層：

```text
Escape sequences
├─ color
├─ texture
└─ reset
```

```text
Hyperlinks
├─ link format
│  ├─ color prefix
│  ├─ type:payload
│  └─ display text
├─ inspection
│  ├─ SetItemRef
│  └─ ExtractHyperlinkString
└─ EAM use
   ├─ spell link display
   ├─ item link display
   └─ debug-safe export
```

結論：

- import/export 不應解析 secret-derived hyperlink text。
- tooltip spellID/itemID 顯示可以保留，但必須和 runtime facts 分開。
- debug export 要 escape pipe / hyperlink 類文字。

### API Changes

`API change summaries` 是版本追蹤入口。

重要三層：

```text
API changes
├─ Retail
│  ├─ 12.0.0
│  ├─ 12.0.1
│  ├─ 12.0.5
│  └─ 12.0.7
├─ change categories
│  ├─ Global API
│  ├─ ScriptObjects
│  ├─ Widgets
│  ├─ Events
│  └─ Structures
└─ EAM use
   ├─ removed API cleanup
   ├─ C_* migration
   └─ live validation targets
```

結論：

- 每次 Retail patch 都要重新檢查 12.x API changes。
- 12.0.7 API summary 已發布；仍需以實機驗證確認 EAM 行為。
- 12.0.5 的 formatter / duration / table.freeze 已寫入 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md`。

### HOWTOs

`HOWTOs` 是教學頁索引，適合作為 UI 操作參考，但不是 Retail 12.x API contract。

重要三層：

```text
HOWTOs
├─ Getting Started
│  ├─ Introduction to Lua
│  └─ Create a WoW AddOn
├─ UI examples
│  ├─ Making draggable frames
│  └─ frame examples
└─ EAM use
   ├─ options UI reference
   ├─ anchor movement
   └─ avoid example-grade hot path code
```

結論：

- 可參考拖曳 frame 實作。
- 不要直接複製 closure-heavy example 到 runtime hot path。
- Options UI 可以保留簡單，避免 WeakAura-like system。

## 對 EAM Docs 的後續建議

- `Docs/01_ARCHITECTURE.md` 可加入本文件作為 API 導覽。
- `Docs/02_RETAIL_API_BOUNDARIES.md` 應引用 `WoW API`、`C_Secrets`、`Events`、`Widget API`。
- `Docs/05_PERFORMANCE_GUIDE.md` 應引用 `Widget scripts`、`Lua API`、`Frame:RegisterAllEvents`。
- `Docs/06_TEST_PLAN_RETAIL.md` 應加入 `CVar` forced-secret 測試與 `API changes` 版本追蹤。

## 遍歷限制

- 本次是靜態文件遍歷，不是全站鏡像。
- `wowuidev` 在 Main Menu 中作為入口出現，但本次查詢未找到獨立、可作為 Retail 12.x runtime contract 的新版頁面；只保留為背景入口。
- `12.0.7/API_changes` 已找到；本文件只作導覽索引，不取代 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md` 的詳細整理。
