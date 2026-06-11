# Retail Test Plan

No live Retail validation has been performed by this documentation pass.

## Static Checks

- Confirm only the Retail TOC is active for the rewrite.
- Confirm TOC Interface is `120007` when targeting Retail 12.0.7.
- Confirm no Classic/MOP/Cata/Wrath/TBC source roots are loaded.
- Search for accidental globals.
- Search for `C_Timer.After(function`.
- Search for per-frame/per-icon `SetScript("OnUpdate")`.
- Search for large item ID scan loops.
- Search for `table.freeze` applied to SavedVariables or runtime state.
- Search for legacy `UnitAura` unpack paths.
- Search for old global `GetSpellCooldown` unpack assumptions.
- Search for unsafe aura `spellID` comparison before secret checks.
- Search for Cooldown widget getter readback used as facts.
- Search for combat-time frame creation or layout mutation.

## Login / ReloadUI

- Load addon in Retail 12.x.
- Confirm no Lua errors on login.
- Confirm SavedVariables migrate once and remain writable.
- Confirm `/reload` preserves profile and positions.
- Confirm disabled alerts stay disabled.

## Slash Commands

- `/eam opt` opens options.
- `/eam opt` called in combat before the frame exists should not create protected-action or taint errors.
- `/eam help` prints command summary.
- `/eam add <spellID>` adds a player aura alert.
- `/eam add target <spellID>` adds a target aura alert.
- `/eam add cd <spellID>` adds a spell cooldown alert.
- `/eam add item <itemID>` adds an item cooldown alert.
- `/eam remove <spellID>` removes a player aura alert.
- `/eam remove target <spellID>` removes a target aura alert.
- `/eam remove cd <spellID>` removes a spell cooldown alert.
- `/eam remove item <itemID>` removes an item cooldown alert.
- `/eam export` prints compact prompt/debug export.
- `/eam show` toggles self aura spellID detection.
- `/eam showt` toggles target aura spellID detection.
- `/eam showc` toggles cast spellID detection.
- `/eam showa` is opt-in and clearly stoppable.
- `/eam MiniMap` toggles minimap option button.
- `/eam MiniMap reset` resets minimap position.
- `/eam SCDRemoveWhenCooldown`
- `/eam SCDNocombatStillKeep`
- `/eam SCDGlowWhenUsable`
- `/eam IconAppenSpellTip`
- `/eam ShowRunesBar`
- font-size commands for name/timer/stack text.
- new debug export commands produce compact output only on demand.

## Options UI Tests

- Open the options panel out of combat with `/eam opt`.
- Confirm the numeric ID edit box accepts only numbers.
- Add/remove player aura, target aura, spell cooldown, and item cooldown entries from the panel.
- Confirm each successful button action increments SavedVariables revision and refreshes the matching service.
- Confirm invalid or empty IDs show a short status message without throwing Lua errors.
- Confirm closing and reopening the panel does not recreate widgets repeatedly.
- Open `/eam opt` in combat before the panel has ever been created and confirm EAM prints a delay message instead of constructing frames.
- Open `/eam opt` in combat after the panel already exists and confirm show/hide does not taint secure UI paths.

## Player Aura Tests

- Add a player buff by spellID and confirm icon appears.
- Add a player buff by `/eam add <spellID>`, `/reload`, and confirm it persists.
- Remove that buff by `/eam remove <spellID>` and confirm icon hides.
- Add a player debuff by spellID and confirm icon appears.
- Confirm stack count updates.
- Confirm timer text appears only when safe.
- Confirm icon remains stable when duration/expiration is unavailable.
- Confirm player/pet matching behaves as configured.
- Confirm no high-frequency full scan while idle.
- Confirm `UNIT_AURA` incremental updates process `addedAuras`, `updatedAuraInstanceIDs`, and `removedAuraInstanceIDs`.
- Confirm full update fallback still works when `updateInfo` is nil or marked full update.
- Confirm full update fallback scans the unit once per relevant filter and does not scan once per configured alert.
- Confirm configured aura alerts absent from a full scan are marked inactive.

## Target Aura Tests

- Add target buff/debuff by spellID.
- Add/remove target aura by `/eam add target <spellID>` and `/eam remove target <spellID>`.
- Change targets rapidly.
- Clear target.
- Confirm target clear marks all configured target aura alerts inactive.
- Enter/leave combat with target alerts active.
- Confirm stale target icons are removed or marked inactive.
- Confirm own-debuff filtering works.

## Spell Cooldown Tests

- Add spell cooldown by spellID.
- Cast spell and confirm cooldown icon/timer.
- Confirm charges update for charge-based spells.
- Confirm GCD-only cooldown does not falsely show as real cooldown.
- Confirm usable glow respects `C_Spell.IsSpellUsable` when safe.
- Confirm no per-spell timer churn.

## Item Cooldown Tests

- Add direct itemID cooldown.
- Use equipped item and inventory item if supported.
- Confirm item cooldown event refresh.
- Confirm item-spell cache is not built by default.
- Start optional cache build out of combat.
- Confirm cache pauses in combat and under low FPS.

## Combat Tests

- Enter combat with active self/target/cooldown alerts.
- Confirm no protected action errors.
- Confirm no taint / blocked action errors are produced by EAM frame updates.
- Confirm unsafe data degrades instead of crashing.
- Confirm first-time icon creation is deferred if the pool is exhausted in combat.
- Confirm deferred layout flushes after `PLAYER_REGEN_ENABLED`.
- Confirm no heavy cache build starts in combat.
- Confirm out-of-combat refresh runs after combat ends.

## Retail 12.0.7 / Midnight API Tests

- Confirm `C_DurationUtil.CreateDurationTextBinding` exists and decide whether it benefits EAM timer labels.
- 2026-05-29 PTR note: user confirmed a minimal `C_DurationUtil.CreateDurationTextBinding` sample displays normally in the 12.0.7 PTR client.
- Confirm `C_DurationUtil.CreateManualClock` exists and does not require unsafe Lua countdown usage.
- Confirm EAM does not call removed `C_DurationUtil.GetCurrentTime`.
- Confirm `GetEventCPUUsage`, `GetFunctionCPUUsage`, and `GetScriptCPUUsage` are available only for debug/profiling commands, not runtime hot path.
- Confirm `table.freeze` / `table.isfrozen` behavior on static tables and verify no SavedVariables/runtime state is frozen.
- Confirm `Cooldown:SetCooldownFromDurationObject()` works with EAM display-only timer state.
- Confirm `FontString:ClearText()` clears text without taint or stale secret text issues.
- Confirm a future EAM `DurationTextBinding` adapter keeps a binding reference, disables/releases it when an icon is recycled, and falls back safely when the API is unavailable.

## Localization Tests

- enUS loads.
- zhTW loads and contains Traditional Chinese strings only.
- zhCN/koKR/ruRU legacy strings remain isolated if preserved.
- Missing locale strings fall back safely.

## Debug Export Tests

- `debug-min` output includes environment, facts, derived counts, and warnings.
- `analysis-full` output includes compact per-alert state.
- `github-issue` output excludes huge logs and sensitive local-only clutter.
- Export does not run automatically.
- `/eam export` includes DB revision, aura cache counts, renderer visible/deferred counts, and boundary warning count.
