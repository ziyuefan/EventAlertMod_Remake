# Architecture

## Current File Map

Root:

- `EventAlertMod_Mainline.toc`: Retail/Mainline TOC, currently interface
  `120000`, version `TWW_11.2.5_20251111`.
- `EventAlertMod_Cata.toc`, `EventAlertMod_Mists.toc`,
  `EventAlertMod_TBC.toc`, `EventAlertMod_Wrath.toc`: unsupported legacy TOCs.
- `embeds.xml`: loads bundled libraries.
- `README.md`, `changelog.txt`: historical behavior and command context.
- `libs/`: bundled `LibCustomGlow-1.0`, `LibDebug`, `LibStub`.
- `locale/`: `localization.comm.lua`, `.en.lua`, `.tw.lua`, `.cn.lua`,
  `.kr.lua`, `.ru.lua`.
- `Images/`, `Music/`: media assets.
- `DevDocument/`: reference URLs and prior ChatGPT context.
- `Classic/`, `TBC/`, `Wrath/`: unsupported legacy source roots.
- `Main/`: current Mainline implementation.

Current Mainline load anchor:

- `Main/EventAlertMod.xml`: loads Mainline Lua modules and creates
  `EA_Main_Frame` / `EA_Version_Frame`.
- XML option panels:
  - `Main/EventAlert_Options.xml`
  - `Main/EventAlert_IconOptions.xml`
  - `Main/EventAlert_ClassAlerts.xml`
  - `Main/EventAlert_OtherAlerts.xml`
  - `Main/EventAlert_TargetAlerts.xml`
  - `Main/EventAlert_SCDAlerts.xml`
  - `Main/EventAlert_GroupAlerts.xml`

Current Mainline Lua modules:

- `EventAlert_LoadDefault.lua`: default `EA_Config2` values.
- `EventAlert_InitVar.lua`: initializes `EA_Config`, `EA_Position`, namespace
  runtime tables, debug flags, class/spec globals.
- `EventAlert_InitVar_DK.lua`: death knight rune constants/textures.
- `EventAlert_SpellItem.lua`: large spell/item data table.
- `EventAlert_CreateFrames.lua`: creates icons, anchors, scroll lists,
  minimap button, group frames, and special resource frames.
- `EventAlert_SpellArray.lua`: class/default spell arrays and data loading.
- `EventAlert_Animation.lua`: visual animation/backdrop helpers.
- `EventAlert_Util.lua`: print helpers, tooltip helpers, aura lookup,
  buff-list mutation, glow helpers, spell/talent checks.
- `EventAlert_EAFun.lua`: compatibility facade for scroll/debug, migration,
  tooltip, condition, timer text, group result, layout, and tip binding.
- `EventAlert_SlashCommand.lua`: `/eam` command handling.
- `EventAlert_GroupEvent.lua`: user-defined condition/group alert checks.
- `EventAlert_Core.lua`: addon load, event registration/dispatch, most
  top-level event handlers, lookup, version checks, update loop.
- `EventAlert_ItemSpellCache.lua`: item-to-spell cache builders and large item
  scans.
- `EventAlert_Aura_Core.lua`: full/incremental aura cache helpers.
- `EventAlert_Aura_Self.lua`: player/pet aura alerts and self icon layout.
- `EventAlert_Aura_Target.lua`: target aura alerts and target icon layout.
- `EventAlert_Cooldown.lua`: spell/item cooldown alerts and SCD layout.
- `EventAlert_SpecialPower.lua`: runes, combo points, class resources,
  lifebloom, vigor, and other special power frames.
- `EventAlert_API.lua`: API alias layer, currently not in the XML load list.
- `EventAlert_Options.lua`: option UI logic and group event editor.
- `EventAlert_IconOptions.lua`: icon option UI, anchor movement, font/position
  settings.
- `EventAlert_ImportExport.lua`: import/export prototype, currently commented
  out in XML.

## Current XML / UI Template Usage

Static XML panels use these template families:

- `UIPanelButtonTemplate`
- `UICheckButtonTemplate`
- `OptionsSliderTemplate`
- `UIDropDownMenuTemplate`
- `UIPanelScrollFrameTemplate`
- `InputBoxTemplate`
- `BackdropTemplate`
- `GameFontNormal`
- `GameFontHighlight`
- `EA_SpellEditTextTemplate`

Dynamic Lua frame creation uses:

- `CreateFrame("Frame", ...)` for alert icons, anchors, list containers, group
  frames, and minimap button.
- `CreateFrame("Cooldown", ..., "CooldownFrameTemplate")` for cooldown swipe
  frames.
- `CreateFrame("ScrollFrame", ..., "UIPanelScrollFrameTemplate")` for spell
  lists and import/export panels.
- `CreateFrame("EditBox", ..., "InputBoxTemplate")` and XML edit-box
  templates for spell IDs and import/export text.
- `CreateFrame("Button", ..., "UIPanelButtonTemplate")` and XML option
  buttons.
- `CreateFontString(..., "GameFontNormal")` and related game fonts.
- Backdrop calls through `Lib_ZYF:SetBackdrop` and direct `BackdropTemplate`
  usage in prototype import/export code.

Rewrite rule: UI templates belong in `UI/IconPool`, `UI/Renderer`, and
`UI/Options`. Services must not create frames or mutate frame layout directly.

## Current Responsibilities

Current code responsibilities are mixed:

- `Core.lua` owns load order, event registration, event routing, feature
  handlers, lookup scanning, version checks, and fallback update scheduling.
- Aura services are split across `Aura_Core`, `Aura_Self`, and `Aura_Target`,
  but still render and schedule directly.
- Cooldown service performs spell cooldown queries, item cooldown queries,
  rendered frame mutation, and delayed updates in one module.
- Frame creation and renderer behavior are spread across `CreateFrames`,
  `EAFun`, `Aura_*`, `Cooldown`, `SpecialPower`, and option modules.
- SavedVariables are initialized directly in global tables without schema
  versioning or validation boundaries.
- Localization uses global string constants and is mixed into UI setup.

## Target Module Map

Core:

- `Env`: addon namespace, local API aliases, build/flavor guard, Retail-only
  guard.
- `Util`: allocation helpers, pools, fallback table APIs, enum helpers,
  assertions.
- `Constants`: frozen enums, event names, status codes, schema versions.
- `EventRouter`: one frame, one `OnEvent`, event-to-module dispatch table.
- `Scheduler`: one `OnUpdate`, due-time queue, low-frequency fallback, no
  per-icon timers.
- `SavedVariables`: defaults, migration, validation, versioned schema.
- `Performance`: FPS/combat throttling, optional profiling, shared pools.

Services:

- `AuraService`: safe player/target aura adapter and cache owner.
- `CooldownService`: spell cooldown adapter and normalized cooldown state.
- `ItemCooldownService`: item cooldown adapter and optional incremental cache.
- `SpellInfoService`: spell name/icon/link cache.
- `ClassPowerService`: player class special power (Holy power, Shards, Combo points, Chi, Arcane charges) adapter and central stack numbers.
- `GroundEffectService`: ground effect spells monitor (SPELL_CAST_SUCCESS) with dual-duration (dynamic Tooltip scraping vs manual inputs) timer tracking.
- `TotemService`: Shaman totem slots monitor using C_Totems.GetTotemInfo.

UI:

- `IconPool`: pooled buttons, textures, cooldown regions, and FontStrings.
- `Renderer`: consumes normalized render state only; no data fetching.
- `Options`: simple config panels.
- `Slash`: `/eam` command parser and debug export commands.

Debug:

- `DebugState`: compact runtime snapshot split into facts, derived state,
  human notes, boundary warnings, and environment.
- `PromptExport`: on-demand compact JSON-like output.

## Data Flow

1. Blizzard event enters `EventRouter`.
2. Router dispatches to one or more services.
3. Service reads safe Retail APIs and updates owned runtime state.
4. Service emits or marks dirty `AlertState` records.
5. `Renderer` receives dirty alert states and updates pooled icons.
6. `Scheduler` handles only due refreshes, fallback sampling, and debug bursts.
7. SavedVariables are read/migrated on load and written only by config changes.

## Event Flow

Primary events should include only necessary Retail events such as:

- `PLAYER_LOGIN`
- `PLAYER_ENTERING_WORLD`
- `PLAYER_REGEN_ENABLED`
- `PLAYER_REGEN_DISABLED`
- `PLAYER_TARGET_CHANGED`
- `UNIT_AURA`
- `SPELL_UPDATE_COOLDOWN`
- `SPELL_UPDATE_CHARGES`
- `BAG_UPDATE_COOLDOWN`
- `UNIT_SPELLCAST_SUCCEEDED`
- power/resource events only when special-resource UI is enabled

No `RegisterAllEvents`.

## UI Render Flow

Renderer input is `IconRenderState`, not raw aura/cooldown API data. Renderer:

- acquires icons from `IconPool`;
- writes changed texture, stack, timer, name, cooldown, glow, and alpha only;
- batches layout changes with parent hidden, then shows once;
- avoids `ClearAllPoints` and `SetPoint` unless layout keys changed;
- never queries C_* APIs.

## Scheduler Flow

One scheduler frame tracks due jobs by numeric time. Jobs are reusable records,
not closure allocation points. Fallback polling must be low frequency and
disabled or throttled in combat/low FPS unless it protects correctness.

## Retail-Only Rewrite Plan

1. Introduce new module skeleton and load order under `Core/`, `Services/`,
   `UI/`, and `Debug/`.
2. Keep old `Main/` tables as migration/reference only while building a new
   schema.
3. Migrate SavedVariables into a versioned profile and alert list model.
4. Port localization strings into an isolated localization module.
5. Implement `EventRouter` and `Scheduler` before porting services.
6. Port player aura, target aura, spell cooldown, and item cooldown services.
7. Implement pooled renderer and move frame creation out of service modules.
8. Rebuild slash commands against the new services and debug exporter.
9. Remove legacy TOCs and Classic/MOP compatibility branches from active load.
10. Perform static checks, then live Retail validation.
