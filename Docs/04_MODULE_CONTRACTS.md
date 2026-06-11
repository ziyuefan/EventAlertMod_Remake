# Module Contracts

## Ownership Rules

- `SavedVariables` owns persistent config tables and migration.
- Services own runtime facts.
- `Renderer` owns rendered UI state.
- `IconPool` owns frame objects.
- `Scheduler` owns due jobs.
- `DebugState` owns debug/session snapshots.
- Static constants may be frozen. Runtime state and SavedVariables must never
  be frozen.
- Every actively loaded source file must begin with a module commentary block
  that records purpose, design philosophy, ownership, mutation boundary, and
  maintenance notes. Keep this commentary current when module contracts change.
  See `Docs/12_CODE_COMMENTARY_GUIDE.md`.

## Core/Env

Inputs:

- addon name and namespace
- Retail build/flavor APIs

Outputs:

- addon namespace
- local API alias table
- Retail-only guard result

Mutation:

- may initialize the addon namespace once
- must not mutate SavedVariables

## Core/Util

Inputs:

- raw Lua/WoW table APIs

Outputs:

- `CreateTable`, `FreezeTable`, `IsFrozen`, pool helpers, safe wipe/release,
  stable enum helpers, debug assertions
- secret/protected value safe-read helpers:
  - `readSafeField`
  - `readSafeScalar`
  - `markBoundary`
  - `appendBoundaryWarning`
  - `clearTimer`

Mutation:

- owns helper-local pools only

## Core/Constants

Inputs:

- none after module load

Outputs:

- frozen enum tables, module names, event names, status constants, schema
  versions, sentinel constants such as `UNKNOWN` and `EMPTY`

Mutation:

- none after freeze

## Core/EventRouter

Inputs:

- module event subscriptions
- Blizzard events

Outputs:

- dispatch calls to registered module handlers with parameterized `pcall` error isolation, ensuring a failure in one module's handler does not block other subscribers

Mutation:

- owns event frame and event subscription table
- no closure allocation per event registration

## Core/Scheduler

Inputs:

- due jobs requested by modules

Outputs:

- due callback dispatch under protective `pcall` isolation, ensuring job runtime failures are caught and don't break the global ticker frame
- safe queue cleanup and task record recycling regardless of callback success

Mutation:

- owns one OnUpdate frame, due queue, reusable job records, and task pool
- no per-icon scheduler tables

## Core/SavedVariables

Inputs:

- legacy globals: `EA_Config`, `EA_Position`, `EA_Items`, `EA_AltItems`,
  `EA_TarItems`, `EA_ScdItems`, `EA_GrpItems`, `EA_Pos`

Outputs:

- versioned active profile
- migration report
- validation warnings
- user-triggered alert add/remove APIs for aura, spell cooldown, and item cooldown

Mutation:

- may mutate SavedVariables during load/migration/config changes
- must not write high-frequency runtime state
- must not freeze SavedVariables
- increments `EAM_DB.revision` after user-triggered config mutation

## Core/Performance

Inputs:

- `GetFramerate`, combat lockdown state, optional `debugprofilestop`

Outputs:

- throttle decisions, profiling samples, shared table pools

Mutation:

- owns profiling/session counters only

## Services/AuraService

Inputs:

- configured player/target aura alerts
- `UNIT_AURA`, `PLAYER_TARGET_CHANGED`, login/world events

Outputs:

- `EAM_AURA_STATE_CHANGED` events fired to EventRouter with parameterized state and frameName
- normalized `AuraState` and `AlertState` allocated from `AuraStatePool`
- boundary warnings
- delta-aware aura cache keyed by unit and `auraInstanceID`
- config revision aware alert index keyed by unit and configured spellID
- full update fallback scans each tracked unit/filter once, rebuilds the unit aura cache, and marks unmatched configured alerts inactive

Mutation:

- owns aura runtime cache and `AuraStatePool` only
- must not create UI frames
- must not write SavedVariables
- may rebuild alert index when SavedVariables revision changes

## Managers/AlertManager

Inputs:

- `EAM_AURA_STATE_CHANGED`, `EAM_COOLDOWN_STATE_CHANGED`, `EAM_ITEM_COOLDOWN_STATE_CHANGED`, `EAM_GROUND_EFFECT_STATE_CHANGED`, and `EAM_TOTEM_STATE_CHANGED` events from EventRouter
- configured alert lists

Outputs:

- batch/throttled calls to `Renderer.render` wrapped in layout batch control (`Renderer.BeginBatch` / `Renderer.EndBatch`)
- multi-type state table recycling via `state.releaseFunc(state)` to recycle inactive states (Aura, Cooldown, Item, GroundEffect, Totem) after UI hide rendering completes

Mutation:

- owns pending updates queue and throttle scheduler status
- does not own AlertState, SavedVariables, or UI icons

## Services/CooldownService

Inputs:

- configured spell cooldown alerts
- cooldown-related events and scheduler fallback ticks

Outputs:

- normalized `CooldownState` and `AlertState`
- dirty alert IDs

Mutation:

- owns spell cooldown cache only

## Services/ShadowHostService

Inputs:

- Blizzard's native `EssentialCooldownViewer` and `Utility` frame pool states
- dynamic frame `Acquire` and `Release` hooks
- World entering and regeneration state events

Outputs:

- mapped active host icon frames per spellID
- zero-taint invisible setting (Alpha=0) to native frames in non-combat

Mutation:

- owns internal spellID-to-frame mapping registry only
- must not modify secure properties in combat

## Services/ItemCooldownService

Inputs:

- configured itemID alerts
- item cooldown events
- optional explicit cache-build command

Outputs:

- normalized `ItemCooldownState` and `AlertState`
- cache status

Mutation:

- owns item cooldown runtime cache
- any item-spell mapping cache must be incremental and interruptible

## Services/SpellInfoService

Inputs:

- spellID/itemID lookup requests

Outputs:

- safe name/icon/link facts where available
- bounded lookup cache that stores only safe fields and boundary warnings

Mutation:

- owns lookup cache
- must avoid heavy combat query loops

## Services/ClassPowerService

Inputs:

- configured class resource options
- player power events (UNIT_POWER_UPDATE, UNIT_MAXPOWER, PLAYER_TALENT_UPDATE)

Outputs:

- dynamic central stack numbers and AlertState for current class power type, protected by `pcall` isolation and `issecretvalue` checks during power updates to bypass restricted value/table runtime exceptions in combat
- direct layout rendering to classPower frame

Mutation:

- none except dispatching event state updates and defensive boundary logging

## Services/GroundEffectService

Inputs:

- configured ground effect items (dynamic/manual modes)
- combat log event unfiltered (SPELL_CAST_SUCCESS)
- low-frequency C_TooltipInfo.GetSpellByID lookups during spell cast successes

Outputs:

- `EAM_GROUND_EFFECT_STATE_CHANGED` events fired to EventRouter with state and frameName
- normalized `GroundEffectState` and `AlertState` allocated from `GroundEffectStatePool`
- scheduled release timers via Scheduler.after

Mutation:

- owns ground effect active timer table, activeStates cache, and `GroundEffectStatePool` only

## Services/TotemService

Inputs:

- Shaman totem events (PLAYER_TOTEM_UPDATE)
- native C_Totems.GetTotemInfo API updates

Outputs:

- `EAM_TOTEM_STATE_CHANGED` events fired to EventRouter with state and frameName
- normalized `TotemState` and `AlertState` allocated from `TotemStatePool`

Mutation:

- owns activeStates cache and `TotemStatePool` only

## UI/IconPool

Inputs:

- desired icon count/class

Outputs:

- acquired/released icon frame records
- prewarmed inactive icons to avoid combat-time frame creation

Mutation:

- owns frames, textures, cooldown regions, FontStrings
- frame creation should happen during initialization or controlled growth only
- must not create new icon frames in combat when pool is empty

## UI/Renderer

Inputs:

- `IconRenderState`

Outputs:

- visible UI state
- layout batch control endpoints (`Renderer.BeginBatch` / `Renderer.EndBatch`) to defer expensive X/Y layout calculations

Mutation:

- mutates UI frames only
- never fetches aura/cooldown data
- gates all expensive UI writes
- defers structural layout changes and first-time icon acquisition while in combat

## UI/Options

Inputs:

- active profile
- class token to class ID mapping table (`CLASS_TOKEN_TO_ID`)

Outputs:

- config mutations through `SavedVariables`
- dynamic, localized specialization drop-down filtering using native `GetSpecializationInfoForClassID(classID, specIndex)` with robust static fallback tables, ensuring 100% localized class/spec UI texts without hardcoding
- a minimal in-game panel for explicit add/remove actions:
  - player aura spellID
  - target aura spellID
  - spell cooldown spellID
  - item cooldown itemID
- immediate service refresh after successful user-triggered mutation

Mutation:

- UI widgets and explicit config values only
- first-time frame creation must be delayed in combat if Retail blocks or risks protected UI mutation

## UI/Slash

Inputs:

- `/eam` command text

Outputs:

- config actions, status text, debug export requests
- simple `/eam add` and `/eam remove` commands for player aura, target aura, spell cooldown, and item cooldown

Mutation:

- may call module APIs; must not directly edit service internals
- writes persistent alert config only through `Core/SavedVariables`

## Debug/DebugState

Inputs:

- module state snapshots

Outputs:

- compact `DebugSnapshot`
- aggregated boundary warnings from service state

Mutation:

- owns transient debug records only

## Debug/PromptExport

Inputs:

- `DebugSnapshot`
- export mode: `debug-min`, `analysis-full`, `github-issue`

Outputs:

- compact JSON-like text

Mutation:

- none except transient string builder buffers
