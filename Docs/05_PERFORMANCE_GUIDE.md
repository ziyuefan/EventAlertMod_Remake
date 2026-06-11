# Performance Guide

## Hot Path Candidates

Current Mainline hot path candidates:

- `Main/EventAlert_Core.lua`
  - event dispatch and handlers
  - `COMBAT_LOG_EVENT_UNFILTERED`
  - `UNIT_AURA`
  - `BAG_UPDATE_COOLDOWN`
  - `SPELL_UPDATE_COOLDOWN`
  - `SPELL_UPDATE_CHARGES`
  - `SPELL_UPDATE_USABLE`
  - `ACTIONBAR_UPDATE_COOLDOWN`
  - lookup scanning with ticker/coroutine
- `Main/EventAlert_Aura_Self.lua`
  - `Buffs_Update`
  - `OnUpdate`
  - `PositionFrames`
- `Main/EventAlert_Aura_Target.lua`
  - `TarBuffs_Update`
  - `OnTarUpdate`
  - `TarPositionFrames`
- `Main/EventAlert_Cooldown.lua`
  - `OnSCDUpdate`
  - `ScdBuffs_Update`
  - `UpdateScdFrame`
  - `ScdPositionFrames`
- `Main/EventAlert_ItemSpellCache.lua`
  - item range scan builders
- `Main/EventAlert_SpecialPower.lua`
  - resource/power updates
  - rune OnUpdate scripts
- `Main/EventAlert_CreateFrames.lua`
  - frame creation and scroll-list generation
- `Main/EventAlert_EAFun.lua`
  - layout, tooltip, timer text, debug label helpers

## Current OnUpdate / C_Timer Usage

Observed Mainline usage:

- `EventAlert_Core.lua`
  - recursive `C_Timer.After(tempInterval, RecurringFrameUpdate)`
  - FPS-adjusted cadence for position/special frame updates
  - `C_Timer.NewTicker(1 / GetFramerate(), function() ...)` for lookup
- `EventAlert_Aura_Self.lua`
  - `G:OnUpdate(spellId)` for aura timer refresh
  - allocates `tempFunc = function() G.OnUpdate(spellId) end` before
    `C_Timer.After(delay, tempFunc)`
- `EventAlert_Aura_Target.lua`
  - `C_Timer.After(delay, G.OnTarUpdate, G, spellId)`
- `EventAlert_Cooldown.lua`
  - `C_Timer.After(nextInterval, G.OnSCDUpdate, G, sid)`
- `EventAlert_ItemSpellCache.lua`
  - `C_Timer.NewTicker(0.01, function() ...)`
  - `C_Timer.After(1, ProcessBatch)` for batch scan continuation
- `EventAlert_SpecialPower.lua`
  - per-rune `SetScript("OnUpdate", function(self, elapsedTime) ...)`
  - `C_Timer.After` for lifebloom refresh
- `EventAlert_Util.lua`
  - `Lib_ZYF:StopOnUpdate(eaf)` calls in frame cleanup

Rewrite rule:

- Replace these with one central scheduler.
- Scheduler callback records should be reusable and keyed by alert/service ID.
- No per-icon timers and no closure allocation in repeated refresh paths.

## Allocation Policy

Use `table.create` for:

- configured alert arrays
- active state arrays
- dirty queues
- icon pool records
- scheduler job records
- debug ring buffers
- default profile templates

Avoid in hot paths:

- transient tables per aura
- `table.insert` when direct numeric index assignment is enough
- `pairs`/`ipairs` where a deterministic numeric loop is available
- ad hoc string building
- anonymous callback functions

## table.freeze Policy

Freeze only:

- constants
- enums
- status names
- schema descriptions
- immutable default field profiles
- static module contracts

Never freeze:

- SavedVariables
- runtime aura/cooldown state
- icon render state
- UI frame records
- scheduler queues
- pool objects
- debug snapshots

## UI Write Policy

Renderer must cache last-rendered values and skip no-op writes:

- `SetText`
- `SetTexture`
- `SetAlpha`
- `SetCooldown`
- `SetPoint`
- `SetSize`
- `Show` / `Hide`

Layout should be batched:

1. Collect dirty layout keys.
2. Hide parent frame.
3. Apply only changed positions/sizes.
4. Show parent frame once.

## Combat / Low-FPS Throttling

Heavy work must be blocked, delayed, or degraded when:

- `InCombatLockdown()` is true;
- FPS is below the configured threshold;
- the work requires large scans;
- a protected/secret boundary is reached.

Allowed degraded behavior:

- show safe icon/name only;
- mark timer as `unknown`, `protected`, or `displayOnly`;
- skip optional item cache progression;
- schedule out-of-combat refresh.

## Current Allocation Risks

First-pass audit found these likely sources:

- repeated aura scan loops over 1..40 helpful and harmful indices;
- `AuraUtil.ForEachAura` callback use;
- tooltip post-call hooks and tooltip parsing paths;
- `C_Timer.After(function() ...)` closure allocation in aura update;
- dynamic frame creation in cooldown update fallback;
- item range scanning with ticker callbacks;
- string formatting in debug labels and lookup output;
- global accidental variables causing unclear lifetime and GC behavior.
