# Retail API 邊界

## Retail 12.x 假設

本重寫目標為 Retail 12.x / Midnight-era API。除非已在 WoW Retail 實機載入測試，否則本文件所有 API 筆記都視為文件假設。

優先使用命名空間：

- `C_AddOns`
- `C_Spell`
- `C_Item`
- `C_UnitAuras`
- `C_TooltipInfo`
- `AuraUtil`
- `C_Timer` only through the central scheduler or explicit non-hot setup

除非有明確、狹窄且已文件化的 Retail-safe fallback，不保留舊式 unpacked return 相容層。

## Taint 控制政策

Warcraft Wiki 的 secure execution / taint 文件指出，AddOn 與 `/script` 屬於不受信任來源；一旦 taint 進入 protected/secure 路徑，戰鬥中可能導致 Blizzard UI 動作被阻擋。EAM 必須把避免 taint 污染視為架構邊界，不只視為 bug 修正。

實作規則：

- 不 hook、覆寫、重定義或 monkey patch Blizzard secure/protected 函式、FrameXML 核心函式、action button、unit frame、nameplate、spell cast、targeting、item use 相關路徑。
- 不在戰鬥中修改 protected frame 的 attribute、parent、anchor、size、visibility、template 或 click 行為。
- 不把 secret/protected value、runtime cache、debug object 或 addon callback 傳入可能污染 secure chain 的 Blizzard frame。
- EventRouter 使用孤兒 frame；Renderer frame 僅作顯示，不承擔 secure action 或 protected interaction。
- 需要 UIParent frame 時，限定為非 protected 顯示用途；若 `InCombatLockdown()` 為 true，延後結構性 UI 變更。
- 不使用 `forceinsecure`，不嘗試繞過 taint，也不加入壓制 Blizzard blocked action 的 workaround。
- 發現 taint、blocked action、combat lockdown 錯誤時，需記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。

## Current Aura API Usage Audit

Current Mainline references:

- `C_UnitAuras.GetBuffDataByIndex`
- `C_UnitAuras.GetDebuffDataByIndex`
- `C_UnitAuras.GetAuraDataByIndex`
- `C_UnitAuras.GetAuraDataByAuraInstanceID`
- `C_UnitAuras.GetAuraDuration`
- `C_UnitAuras.GetAuraBaseDuration`
- `C_UnitAuras.GetRefreshExtendedDuration`
- `C_UnitAuras.GetUnitAuraInstanceIDs`
- `C_UnitAuras.AddBlockedAura` / `C_UnitAuras.ClearBlockedAuras`
- `C_TooltipInfo.GetUnitBuffByAuraInstanceID`
- `C_TooltipInfo.GetUnitDebuffByAuraInstanceID`
- `AuraUtil.ForEachAura`
- `AuraUtil.FindAuraByName`
- `GameTooltip:SetUnitAura`
- legacy `UnitAura` / `select(10, UnitAura(...))` fallback paths

Rewrite rule:

- Aura facts must come from safe structured Retail aura data, anchored by the stable, `NeverSecret` `AuraInstanceID`.
- **Blocked Aura Integration**: For unwanted or spammy auras, utilize the native `C_UnitAuras.AddBlockedAura(unit, auraInstanceID)` to delegate filtration to the C++ engine. This must only be called when the addon's execution path is completely untainted (`AllowedWhenUntainted`).
- **Native Dual-Pipeline Duration**: Prefer retrieving the C++ blackbox `DurationObject` via `C_UnitAuras.GetAuraDuration` and feeding it directly to native widgets (`CooldownFrame:SetCooldownFromDurationObject` and `C_DurationUtil.CreateDurationTextBinding`).
- **Pandemic Prediction**: DoT refresh checks must compare `C_UnitAuras.GetRefreshExtendedDuration(unit, auraInstanceID)` against `GetAuraBaseDuration * 1.3` in combat to bypass restricted numeric `timeLeft` checks.
- If a value is secret/protected/display-only, mark `boundaryLimited` and do not force it through normal Lua comparisons or table-key logic.
- Do not retain broad legacy UnitAura unpack mapping as architecture.

## Current Cooldown API Usage Audit

Current Mainline references:

- `C_Spell.GetSpellCooldown`
- `C_Spell.GetSpellBaseCooldown`
- `C_Spell.GetSpellCharges`
- `C_Spell.GetSpellInfo`
- `C_Spell.GetSpellTexture`
- `C_Spell.GetSpellLink`
- `C_Spell.IsSpellUsable`
- `C_Spell.DoesSpellExist`
- legacy global `GetSpellCooldown`, `GetSpellInfo`, `GetSpellTexture`,
  `GetSpellLink`, `GetSpellCharges`, `IsUsableSpell`
- `C_Secrets.ShouldSpellCooldownBeSecret`
- GCD spell ID `61304`

Rewrite rule:

- Prefer structured `C_Spell` returns.
- Treat cooldown facts as unavailable when secret/protected.
- Do not fabricate cooldown start, duration, or expiration.
- Avoid repeated cooldown queries every frame.

## Current Item Cooldown API Usage Audit

Current Mainline references:

- `C_Item.GetItemCooldown`
- `C_Item.GetItemSpell`
- `C_Item.DoesItemExistByID`
- `C_Container.GetItemCooldown` as a fallback in one alias layer
- legacy global `GetItemCooldown`, `GetItemSpell`
- `GetInventoryItemCooldown`
- `GetInventoryItemID`
- optional `HeroDBC.DBC.ItemSpell`
- large item range scanning in `EventAlert_ItemSpellCache.lua`

Rewrite rule:

- Support direct itemID cooldown monitoring first.
- Do not scan large item ranges in normal runtime.
- Any item-spell relation cache must be opt-in, idle-only, interruptible,
  FPS-aware, and combat-aware.

## Current Specialization & Localization API Audit

Current Mainline references:

- `GetSpecializationInfoForClassID`
- `GetClassInfo`
- `GetSpecializationInfo`

Rewrite rule:

- **Dynamic Localization**: Instead of hardcoding localized specialization or class names in the configuration UI, use native APIs to query matching strings dynamically aligned with the client's current language setting.
- **Spec Dropdown Filtering**: Map class tokens to class IDs (using static enum mappings such as `CLASS_TOKEN_TO_ID` matching WoW class IDs). Retrieve spec names dynamically via `GetSpecializationInfoForClassID(classID, specIndex)` (where `classID` is a number from 1 to 13 and `specIndex` is from 1 to 4).
- **Dual-Path Fallback**: Implement a solid fallback map when native localization APIs return `nil` or empty values, using static localized tables (`EAM.L`) to ensure UI components always have a readable name.

## Secret / Protected Value Policy

When data is unsafe or unavailable:

- **Four Safety Check APIs**:
  - `issecretvalue(value)`: Checks if a value is classified as a secret.
  - `canaccessvalue(value)`: Determines if the current context has rights to read a value.
  - `canaccesstable(table)`: Evaluates if a table's keys and values are readable.
  - `issecrettable(table)` / `hasanysecretvalues(table)`: Checks if the table structure is restricted or contains secrets.
- **Table Indexing Protection (Critical)**:
  - AddOns must never index standard Lua tables using an unverified key that might be a `Secret Value` (e.g. `spellId` or `text` returned during combat restrictions).
  - Attempting to index a table with a secret key yields a fatal error: `attempted to index a table that cannot be indexed with secret keys`.
  - Always guard table lookups with `if not issecretvalue(key) and canaccesstable(tbl) then ... end`.
- **Data-Driven Tooltip & Secrecy Defense**:
  - Direct `C_TooltipInfo` queries (`GetUnitBuffByAuraInstanceID`) in combat return structured `TooltipData` which may be flagged as `Secret Table`.
  - When parsing static values from `line.leftText`, always defend against secret propagation using `if text and not issecretvalue(text) and canaccessvalue(text) then ... end`.
  - **No `TooltipUtil.SurfaceArgs`**: In 12.x / Midnight, tooltip tables are natively surfaced. The `TooltipUtil.SurfaceArgs` helper is **entirely removed**; attempting to call it will throw a fatal `nil value` Lua error.
- Continue rendering safe state such as icon/name if available.
- Use timer mode `protected`, `displayOnly`, or `unknown`.
- Add a boundary warning to debug state.
- Schedule an out-of-combat refresh only if it is safe.
- Never mix guessed values into facts.
- Never pass unsafe values into secure/protected UI chains.

## Intentionally Avoided APIs / Patterns

- Classic API branches.
- MOP/Cata/Wrath/TBC API return mappings.
- `RegisterAllEvents`.
- Tooltip scanning as a normal data source (use it only for low-frequency static duration scrape fallbacks).
- `TooltipUtil.SurfaceArgs` usage (always let the native engine surface the arguments).
- Huge item ID scans during login/combat.
- Per-icon `SetScript("OnUpdate")`.
- Repeated `C_Timer.After(function() ...)` chains in hot paths.
- External framework dependencies for configuration.
- `forceinsecure` 或任何 taint 繞過、壓制 blocked action 的 workaround。
