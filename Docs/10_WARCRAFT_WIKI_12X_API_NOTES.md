# Warcraft Wiki 12.x API 變更筆記

本文件整理自 Warcraft Wiki 的 `API change summaries` 與 Retail 12.x
相關頁面，作為 EventAlertMod / EAM Retail rewrite 的實作參考。

這不是完整 API 文件備份；這份筆記只保留與 EAM 的 aura、cooldown、
item cooldown、UI renderer、debug export、SavedVariables migration 直接
相關的重點。

## 來源

- https://warcraft.wiki.gg/wiki/API_change_summaries
- https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- https://warcraft.wiki.gg/wiki/Patch_12.0.1/API_changes
- https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes
- https://warcraft.wiki.gg/wiki/Patch_12.0.7/API_changes
- https://warcraft.wiki.gg/wiki/Patch_12.0.5
- https://warcraft.wiki.gg/wiki/Patch_12.0.7
- https://warcraft.wiki.gg/wiki/Public_client_builds
- https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes
- https://warcraft.wiki.gg/wiki/API_Cooldown_SetCooldownFromDurationObject
- https://warcraft.wiki.gg/wiki/API_FontString_ClearText
- https://warcraft.wiki.gg/wiki/Secret_Values
- https://warcraft.wiki.gg/wiki/ScriptObject_DurationObject
- https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCooldown
- https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCharges
- https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataByAuraInstanceID
- https://warcraft.wiki.gg/wiki/API_C_TooltipInfo.GetUnitBuffByAuraInstanceID
- https://warcraft.wiki.gg/wiki/API_C_TooltipInfo.GetUnitDebuffByAuraInstanceID
- https://warcraft.wiki.gg/wiki/Category:API_systems/TooltipInfo
- https://warcraft.wiki.gg/wiki/Category:API_systems/UnitAuras
- https://warcraft.wiki.gg/wiki/API_Cooldown_SetCooldown
- https://warcraft.wiki.gg/wiki/API_Cooldown_SetCooldownDuration
- https://warcraft.wiki.gg/wiki/API_Cooldown_GetCooldownDisplayDuration

## 2026-05-26 複查摘要

本次重新檢索 Warcraft Wiki 後，與 EAM 直接相關的結論如下：

- `API change summaries` 與搜尋索引目前可找到 `12.0.0`、`12.0.1`、`12.0.5`、`12.0.7` API change summary。
- `Patch 12.0.0/API changes` 是 Secret Values 與 AddOn 安全限制的核心起點。
- `Patch 12.0.1/API changes` 是 Midnight launch patch；對 EAM 的直接影響低於 12.0.0/12.0.5，但仍需追蹤新增 aura filter 與 tooltip/filter 行為。
- `Patch 12.0.5/API changes` 明確新增 `table.freeze`、`table.isfrozen`、API Predicates 文件、Cooldown countdown formatter、FontString smooth scaling，並補強 Secret / security 相關錯誤訊息。
- 12.x 引入了強大的 C 語言底層 Blocked Aura 引擎 `C_UnitAuras.AddBlockedAura(unit, auraInstanceID)` 與時間黑盒 `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)`，提供 0-GC 與 100% 安全的防 Taint 原生執行鏈。
- 12.x 引入了數據驅動型 Tooltip 系統，以 `C_TooltipInfo.GetUnitBuffByAuraInstanceID(unit, auraInstanceID)` 與 `GetUnitDebuffByAuraInstanceID` 取代了舊式的 `SetUnitBuff` 模擬渲染，將資料與 UI 徹底分離，並完美橋接了 `NeverSecret` 的 `AuraInstanceID`定位。
- `Secret_Values`、`ScriptObject_DurationObject`、`C_Spell.GetSpellCooldown`、`C_TooltipInfo.GetUnitBuffByAuraInstanceID` 這些單頁文件已足以支撐 EAM 的架構決策：資料來源層必須處理 secret boundary，Renderer 應盡量交給 Blizzard widget 顯示 duration。
- 12.0.7 的公開 API change summary 目前未顯示直接影響 EAM aura/cooldown/item cooldown 核心邏輯的大型 API 變更，但新增 `C_DurationUtil.CreateDurationTextBinding`、`C_DurationUtil.CreateManualClock`，並移除 `C_DurationUtil.GetCurrentTime`，需列入 DurationObject / timer 顯示追蹤項。

注意：以上是文件與搜尋索引交叉整理，尚未在 WoW Retail 12.x client 內實機驗證。

## 2026-05-29 使用者提供的 12.0.7 PTR / RC 備查摘要

本節來源為使用者貼上的 12.0.7 PTR / RC 變更內容。此輪公開網路搜尋尚未找到可直接引用的對應頁面，因此以下先作為「待公開來源複核、待 WoW Retail/PTR 實機驗證」的工作錨點；不得把它視為已驗證事實。

### 2026-05-29 PTR 實測更新：DurationTextBinding

- 使用者已於 WoW 12.0.7 PTR client 執行 `C_DurationUtil.CreateDurationTextBinding` 最小測試範例。
- 結果：FontString 可正常顯示由 `DurationTextBinding` 驅動的倒數文字。
- 驗證範圍：僅確認最小範例可顯示；尚未代表 EAM Renderer 已整合完成。
- 尚未驗證：戰鬥中行為、taint log、圖示重用後文字清除、locale 顯示、過期文字、zero duration、與既有 `Cooldown:SetCooldownFromDurationObject()` 的整合策略。
- EAM 實作規則：可把 `DurationTextBinding` 視為 12.0.7 PTR 已可用候選路徑，但正式整合仍需 feature detection 與 fallback。

### 與 EAM 直接相關

- Tooltip money：新增 `GameTooltip_AddMoneyLine`，改用 atlas / `MoneyFormatter` 顯示金錢；建議 AddOn 避免舊式 `SetTooltipMoney`，以降低 tooltip secret value 問題。
- Unit identity：部分限制 unit token 的 API，例如 `UnitGUID`、`UnitAura`、health/power 類 API，遇到不支援 token 時改為回傳 `nil` 或預設值，不再直接丟 Lua error。EAM 仍不得依賴錯誤作為控制流程。
- File asset：新增 `C_UIFileAsset`，可用 `GetFileID`、`IsKnownFile`、`IsLooseFile` 在使用字型與材質前驗證資源是否存在。EAM 可在 Options / Renderer 初始化時低頻使用，不得放 hot path。
- Profiling：`GetEventCPUUsage`、`GetFunctionCPUUsage`、`GetScriptCPUUsage` 重新開放給 AddOn。EAM 只可用於 on-demand debug/profiling，不可進入常態 runtime。
- Debug secret：`debugstack` 與 `debuglocals` 若目前函式或呼叫堆疊曾接觸 secret value，可能回傳 secret values。EAM debug export 不得把 stack/local 當作安全文字直接輸出。
- ScrollBox secret：官方修正 secret 出現在 scrollbox region 時造成的問題。EAM 若未來做設定列表，仍需避免把 secret/protected raw value 放入可捲動 UI。
- Chat gain events：currency、honor、loot、money、reputation、XP gains chat events 不再 secret。EAM 目前不以 chat event 作核心資料來源，僅列入後續 debug/通知參考。
- TOC per-directive conditionals：TOC 支援每個 directive 條件，例如 `## Dep: Addon_X [AllowLoadGameType classic]`。EAM 仍維持 Retail-only，不因這項能力重新引入 Classic 分支。
- `SetFont`：傳入無效 font flag 時錯誤訊息更明確。EAM Options 應避免讓使用者輸入未驗證 flag。
- Duration text：新增 `DurationTextBinding` script object，可把 `DurationObject` 直接綁到 `FontString`，由原生系統更新文字。EAM timer label 後續應優先評估這條路，而不是 Lua OnUpdate 自行倒數。
- AuraData：`isFromPlayerOrPlayerPet` 會在 player-controlled vehicle 施放的 aura 上設為 true。EAM 的「玩家或玩家寵物來源」判斷需把 vehicle 情境列入實機測試。
- Private aura sound：非戰鬥中，active M+ 期間可呼叫 `C_UnitAuras.AddPrivateAuraAppliedSound`。EAM 暫不把 private aura sound 納入核心功能。
- Aura refactor timeline：官方目標把 aura exposure refactor 放在 12.1.0。EAM 的 AuraService 應保持 adapter 邊界清楚，避免把 12.0.x aura 表結構寫死到 UI/Renderer。

### 與 EAM 關聯較低但需留意

- `ENCOUNTER_END` 新增 boss `EncounterUnitStatus` list，包含 `creatureID`、`creatureName`、`remainingHealthPercent`，且標示為 non-secret。EAM 目前不做 encounter boss timeline。
- `C_EncounterEvents` 顏色 API 支援文字警告、timeline event、5 秒剩餘事件與 alpha 值。EAM 暫不整合 encounter event timeline。
- SimulateMouse API 不再攜帶 taint，但只能在目前 mouse focus 都不是 forbidden、locked down、script inaccessible 或 protected frame 時，且仍限 gamepad action 使用。EAM 不應把它納入操作模型。
- `C_ScenarioInfo.GetUnitCriteriaProgressValues` 第二回傳值改為 `[0, 1]`。EAM 不使用此 API。
- Battle.net：`BNInviteFriend` 遷移到 `C_BattleNet.InviteFriend`。EAM 不使用。
- Mythic Plus run history / best APIs 回傳 `CalendarTime` struct。EAM 不使用。
- `GROUP_FORMED` 修正 follower dungeon / delve 單人進入時的事件發送。EAM 目前不依賴。
- `raidtarget` secure action 新增 `"set-unmarked"`；EAM 不操作 secure raid target action。

### Classic PTR 資訊處理原則

使用者提供內容也包含 upcoming Classic PTR builds，但本專案是 Retail-only。Classic 的 secret doc、raid target、macro chat、minimap ping 等變更只作為「不可引回 EAM 架構」的背景，不進入 active code、TOC 或 module contract。

## 版本定位

- Retail 12.0.0 的 TOC 是 `120000`。
- Retail 12.0.1 的 TOC 是 `120001`。
- Retail PTR 12.0.5 在 `Public client builds` 顯示 Interface `120005`。
- Retail 12.0.7 的 API change summary 標示 TOC 是 `120007`。
- EAM Retail rewrite 應以 12.x / Midnight-era API 為目標。
- Classic、MOP Classic、Cata Classic、Wrath Classic、TBC、Era 都不應進入新架構。

## 12.0.5 API 變更重點

12.0.5 的 API change page 對 EAM 影響最大的是 Lua formatter、DurationObject、aura 欄位 secrecy、`table.freeze`、以及 cooldown timer 顯示 API。

### API Predicates 文件

12.0.5 新增 Predicates table 到 Lua API documentation，用來描述每個 API 的限制條件。

EAM 實作規則：

- 實作前先看 API predicates，不只看函式名稱與回傳型別。
- 若標記 `SecretWhen...`、`AllowedWhenUntainted`、`SecretArguments`、`SecretReturnsForAspect`，該 API 必須經過 service 層或 renderer 隔離層。
- Debug export 不應輸出 predicates 判定後仍不安全的 raw value。
- 文件未列出或搜尋索引不完整時，不可推論「安全」；只能標記為待實機驗證。

### Lua Formatter 與 DurationObject

12.0.5 新增 Lua numeric formatter types：

```lua
AbbreviatedNumberFormatter
NumericRuleFormatter
SecondsFormatter
```

文件指出這些 formatter 可透過 duration object 的 `Format` functions 接收 secret numbers，並可供 cooldown frame 使用。

新增 cooldown API：

```lua
Cooldown:SetCountdownFormatter(formatter)
Cooldown:SetCountdownMillisecondsThreshold(seconds)
```

EAM Renderer 規則：

- timer text 不要自己在 Lua hot path 拼字串。
- 有 `DurationObject` 時，優先讓 `Cooldown` 使用 formatter。
- 小於門檻的毫秒/小數顯示交給 `SetCountdownMillisecondsThreshold`。
- 秒數文字 formatter 必須 live Retail 實測，不可假設所有 locale 都一致。

### Charge Duration 與 Zero-Span Duration

12.0.5 指出下列 charge duration API 在 spell 已達最大 charges 時，會回傳 zero-span duration：

```lua
C_SpellBook.GetSpellBookItemChargeDuration
C_Spell.GetSpellChargeDuration
C_ActionBar.GetActionChargeDuration
```

並且 zero-span duration objects 會被視為 fully elapsed。

EAM CooldownService 規則：

- charge-based spell 不要只用舊式 `charges == maxCharges` 判斷 timer。
- 需支援 zero-span `DurationObject`。
- `IconRenderState.timer.mode` 可保留 `displayOnly`，由 renderer 交給 cooldown widget。
- 若需要判斷「已完成」，必須確認 duration object 是否可安全判斷或由 widget 顯示結果承擔。

### ignoreGCD 參數

12.0.5 新增 cooldown-duration-constructing APIs 的 `ignoreGCD` 參數。

EAM 規則：

- spell cooldown alert 應預設忽略 GCD 類 cooldown。
- 若 API 提供 `ignoreGCD`，優先使用官方參數，不要再靠 61304 差值推測。
- 仍需保留 GCD dummy spell `61304` 作為測試/相容觀察點，但不應作為唯一架構。

### AuraData 欄位不再 secret

12.0.5 指出下列 `AuraData` 欄位不再 secret：

```lua
isHelpful
isHarmful
isRaid
isNameplateOnly
isFromPlayerOrPlayerPet
```

EAM AuraService 規則：

- 這些欄位可作為分類/過濾優先候選，但仍需檢查目標 build 行為。
- `isFromPlayerOrPlayerPet` 可取代部分舊式 `unitCaster == "player"` 邏輯。
- 不代表整個 `AuraData` 安全；duration、expiration、spellID、name、icon 仍需個別檢查。

### Aura Instance ID 重隨機

12.0.5 指出 aura instance IDs 會在進入 encounter、Mythic+、PvP 時重新隨機。

EAM AuraService 規則：

- `auraInstanceID` 可作為單次 session / 單次限制區間內的安全 anchor。
- 不可跨 encounter / M+ / PvP 長期保存。
- 進入限制場景或收到 target/world/combat 狀態變更時，應清理 aura cache。
- SavedVariables 絕不可保存 `auraInstanceID`。

### Unit API 與身份限制

12.0.5 加強 unit identity restriction：

- `UnitName` 不再接受 secret unit tokens。
- `UnitSpellTargetName` 只回傳 player unit names。
- `UnitTokenFromGUID` 在身份 secret 時不回傳 arena、nameplate、boss、party、raid、target-of-target token。
- `UnitIsUnit` 對 `targettarget` / `focustarget` 可能回傳 secret，禁止比較時回傳 nil。

EAM 規則：

- 不要用 `targettarget` / `focustarget` 作為核心 alert matching。
- target aura alert 只追蹤 `target`，不要自動延伸到 target-of-target。
- debug export 不應嘗試把 secret unit identity 轉成名字/GUID。
- UI label 若 unit name 不安全，顯示空白或安全 fallback。

### table.freeze / table.isfrozen

12.0.5 新增：

```lua
table.freeze(tbl)
table.isfrozen(tbl)
```

EAM 規則：

- 可用於 `Core/Constants.lua` 的 enum、schema、module names、status constants。
- 不可用於 SavedVariables。
- 不可用於 runtime aura/cooldown/icon state。
- 不可用於 scheduler queue 或 pool objects。
- 需要 fallback，因為開發環境或舊 build 可能沒有這些 API。

### Secret 字串格式化限制

12.0.5 指出 string formatting API 不再對 secret strings 套用 field-width modifiers，例如 `"%.5s"` 不截斷 secret string。

EAM 規則：

- 不要靠格式化截斷 secret-derived text。
- `C_TooltipInfo` parsing 前仍要先檢查 text 是否 secret。
- debug export 不要把 secret string 透過 `format` 硬轉出來。
- timer/name text 的長度控制應在 safe string 上做。

### Player Stat 與 Aura Secret 關聯

12.0.5 指出回傳 player stats 的 API 在 auras secret 時也可能回傳 secret。

EAM 規則：

- special power / resource UI 不能假設 player stats 永遠安全。
- `SpecialPower` rewrite 應走同一個 boundary policy。
- 若 power/resource 不安全，render icon-only 或交給 Blizzard-supported display。

### Font Smooth Scaling

12.0.5 新增：

```lua
FontString:GetSmoothScaling()
FontString:SetSmoothScaling(smooth)
```

EAM Renderer 可在 live Retail 驗證後，用於 timer/name/stack label 視覺品質，但不應放入 hot path 重複設定。

### Cooldown Widget Secret Aspect

`Cooldown:SetCooldown` 與 `Cooldown:SetCooldownDuration` 允許在 tainted 路徑接收特定 secret arguments，但會加入 `Enum.SecretAspect.Cooldown`。`Cooldown:GetCooldownDisplayDuration` 則可能依 Cooldown secret aspect 回傳 secret。

EAM Renderer 規則：

- 可把安全的 numeric cooldown 交給 `SetCooldown(start, duration, modRate)`。
- 若來源是 `DurationObject`，優先使用 `SetCooldownFromDurationObject(duration, clearIfZero)`。
- 不在 Renderer 讀回 `GetCooldownDisplayDuration()` 作為事實資料。
- 任何可能被 secret aspect 標記的 Cooldown frame，都只用於顯示；不要把 getter 回傳值送回 service state。

## 12.0.7 API 變更重點

截至 2026-05-26 複查，Warcraft Wiki 已有 `Patch 12.0.7/API_changes`，標示 TOC 為 `120007`，差異區間為 `12.0.5 (67602) -> PTR 12.0.7 (67669)`。

與 EAM 直接相關或需要追蹤的項目：

- 新增 `C_DurationUtil.CreateDurationTextBinding`。
- 新增 `C_DurationUtil.CreateManualClock`。
- 移除 `C_DurationUtil.GetCurrentTime`。
- 新增 profiling / CPU usage 類 API：`GetEventCPUUsage`、`GetFunctionCPUUsage`、`GetScriptCPUUsage`。
- 多數其他新增項目偏向 Delves、Housing、Merchant、PartyInfo、UIFileAsset 等系統，暫不作為 EAM 核心依賴。

EAM 文件規則：

- `EventAlertMod.toc` 目前已錨定 `120007`；發佈前仍需確認 CurseForge game version ID 與 WoW Retail/PTR 實機載入狀態。
- DurationObject / timer 顯示層需評估 `CreateDurationTextBinding` 與 `CreateManualClock` 是否可替代手寫倒數字串。
- 不使用已移除的 `C_DurationUtil.GetCurrentTime`。
- 新增 CPU usage API 只能作為 debug/profiling on-demand 工具，不可放入 hot path。
- 12.0.7 仍需 live Retail/PTR 實測，不得只靠文件宣稱完全相容。

## 12.0 AddOn Security 核心變化

12.0.0 引入 AddOn security changes，目標是限制 AddOn 使用戰鬥資訊做複雜決策，但仍允許 UI 外觀調整。

核心概念是 `Secret Values`：

- secret value 是黑盒值。
- tainted addon code 可以收到 secret，也可以把 secret 傳給部分允許的 API。
- tainted addon code 不可以讀出 secret 內部值。
- 不可對 secret 做一般 Lua 算術、比較、轉字串、`tonumber`、`string.match`、table key 等操作。
- 若 API 文件標示會回傳 secret，EAM 必須把該資料視為 unsafe，不能把它混入 facts。

## Secret 相關 API

12.0.0 新增多個 secret 檢查/處理 API。EAM rewrite 應集中包裝在 `Core/Env.lua` 或 `Core/Util.lua`，不要讓各服務直接散落呼叫。

重要 global API：

```lua
issecretvalue
issecrettable
hasanysecretvalues
canaccesstable
canaccessvalue
canaccessallvalues
canaccesssecrets
scrubsecretvalues
dropsecretaccess
mapvalues
secretwrap
```

重要 `C_Secrets` API：

```lua
C_Secrets.HasSecretRestrictions
C_Secrets.ShouldAurasBeSecret
C_Secrets.ShouldCooldownsBeSecret
C_Secrets.ShouldSpellAuraBeSecret
C_Secrets.ShouldSpellCooldownBeSecret
C_Secrets.ShouldSpellBookItemCooldownBeSecret
C_Secrets.ShouldUnitAuraIndexBeSecret
C_Secrets.ShouldUnitAuraInstanceBeSecret
C_Secrets.ShouldUnitAuraSlotBeSecret
C_Secrets.ShouldUnitPowerBeSecret
C_Secrets.ShouldUnitPowerMaxBeSecret
C_Secrets.ShouldUnitSpellCastBeSecret
C_Secrets.ShouldUnitSpellCastingBeSecret
C_Secrets.GetSpellAuraSecrecy
C_Secrets.GetSpellCooldownSecrecy
C_Secrets.GetSpellCastSecrecy
C_Secrets.GetPowerTypeSecrecy
```

實作規則：

- 讀 table 前先檢查 table 本身可讀性。
- 讀值後再檢查值是否為 secret。
- 只有確認安全的值才能進入 `facts`。
- unsafe 值只能形成 `boundaryWarnings` 或 `timer.mode = "protected" / "unknown" / "displayOnly"`。
- 不要把 secret 值寫入 SavedVariables。

### Secret Values 單頁補充

Warcraft Wiki `Secret_Values` 將 Secret 描述為 Patch 12.0.0 引入的新機制；受 taint 的 addon code 通常只能保存 secret 或傳給允許的 API，不能檢視內容。

EAM 判斷規則：

- `if value then` 只能用來區分是否為 nil；不能代表 value 可比較、可格式化或可序列化。
- 不可把 secret string 丟進 `string.match`、`string.format` 或 tooltip parser。
- 不可把 secret number 用於 timer 運算、排序、差值、table key。
- 若 API 單頁出現 `ConditionalSecret` 或 `SecretWhen...`，就算測試環境暫時回傳普通值，也要保留 boundary handling。

## Secret Aspects 與 UI 物件

Secret 不只影響 Lua 值，也會污染 script object 的 aspect。

重要風險：

- 把 secret 傳進部分 widget API，可能讓該 widget 的相關 getter 之後回傳 secret。
- Secret anchors 可能沿著 anchor chain 往下傳播。
- Layout frame 不應直接接收 secret-fed 資料。
- Renderer 應隔離「承接 secret display object」與「負責 layout anchor」的 frame。

EAM UI 實作建議：

- `IconPool` 建立穩定 frame 結構。
- `Renderer` 只接收 normalized `IconRenderState`。
- 任何可能 secret 的 texture、alpha、shown、text、duration 顯示，都要限制在最小 UI 節點。
- 若 frame 需要重用，應研究並實測 `SetToDefaults` 是否能安全清除 secret aspect。

## Aura API 變更重點

12.x 對 aura 存取有 secret restriction。規劃筆記指出：

- aura access 在限制狀態下會變 secret。
- `GetUnitAuras` / `UNIT_AURA` 的 vector 容器可能不是 secret，但內容值可能是 secret。
- `AuraInstanceID` 不是 secret。
- 依 spellID/name 直接查單一 aura 的 API，在 aura access secret 時可能不可呼叫。

EAM `AuraService` 實作規則：

- 優先使用 `UNIT_AURA` 增量資訊。
- 使用 `auraInstanceID` 作為安全識別 anchor。
- 不假設 spellID lookup 在戰鬥中一定可用。
- 可讀才寫入 `AuraState.factsSafe = true`。
- 不可讀時保留安全 icon/name，timer 設為 `protected` 或 `unknown`。
- 脫戰 `PLAYER_REGEN_ENABLED` 後做一次安全重掃，清掉殘影與 boundary-limited state。

相關 API：

```lua
C_UnitAuras.GetAuraDuration
C_UnitAuras.GetAuraBaseDuration
C_UnitAuras.DoesAuraHaveExpirationTime
C_UnitAuras.GetAuraApplicationDisplayCount
C_UnitAuras.GetUnitAuraInstanceIDs
C_TooltipInfo.GetUnitAuraByAuraInstanceID
```

### C_UnitAuras.GetAuraDataByAuraInstanceID

`C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)` 的 `auraInstanceID` 參數標記為 `NeverSecret`，但回傳的 `UnitAuraInfo` 可能是 `SecretWhenUnitAuraRestricted`。

EAM 實作規則：

- `auraInstanceID` 可作為 runtime anchor，但不可保存到 SavedVariables。
- 四大核心安全檢查防禦：
  - `canaccesstable(table)`：必須在存取任何回傳 table 欄位前進行安全判定。
  - `canaccessvalue(value)`：在讀取欄位內容前進行存取許可判定。
  - `issecretvalue(value)`：用以確認欄位（如 `spellId` 或 `duration`）是否已被加密為秘密值。
  - `issecrettable(table)` / `hasanysecretvalues(table)`：檢查 table 結構本身是否已被限制或含有秘密。
- **Table 索引防護規範 (Critical)**：
  - 嚴禁直接以可能為秘密值（如 restricted 狀態下的 `spellId`）的 key 對任何自訂 Lua table（如 `EAM.SavedVariables`、`EAM.db`）進行 `tbl[spellId]` 查表。
  - 此操作將引發致命錯誤：`attempted to index a table that cannot be indexed with secret keys`。
  - 在查表前，必須以 `if not issecretvalue(key) and canaccesstable(tbl) then ... end` 的本地 in-place 模式進行預防性檢查，拒絕使用 secret key。
- 可安全讀取的欄位才進 `facts`；其餘只進 `boundaryWarnings`。
- Aura matching 不可只依賴 unsafe `spellID`；必要時用設定、事件、safe anchor 與顯示降級共同處理。

## Cooldown API 變更重點

12.0 移除或淘汰許多舊 global spell API。EAM 不應再保留 Classic/舊版 unpacked return layer。

舊 global API 應改用 `C_Spell`：

```lua
GetSpellInfo       -> C_Spell.GetSpellInfo
GetSpellCooldown   -> C_Spell.GetSpellCooldown
GetSpellTexture    -> C_Spell.GetSpellTexture
GetSpellCharges    -> C_Spell.GetSpellCharges
IsUsableSpell      -> C_Spell.IsSpellUsable
```

12.0 相關 `C_Spell` 重點：

```lua
C_Spell.GetSpellCooldownDuration
C_Spell.GetSpellChargeDuration
C_Spell.GetSpellDisplayCount
C_Spell.GetSpellMaxCumulativeAuraApplications
C_Spell.IsPriorityAura
C_Spell.IsSelfBuff
```

`SpellCooldownInfo` 在 12.x 有新欄位，例如：

```lua
timeUntilEndOfStartRecovery
isOnGCD
```

Warcraft Wiki 單頁指出 `C_Spell.GetSpellCooldown` 是 Patch 11.0.0 加入、取代舊 `GetSpellCooldown` 的 API；它可能回傳 nil，且在 spell cooldown restricted 時可能回傳 secret。`isOnGCD` 欄位為 `NeverSecret`，但文件提醒除非正在回應 `SPELL_UPDATE_COOLDOWN`，否則不要信任此欄位。

EAM `CooldownService` 實作規則：

- 優先用 structured `C_Spell` return。
- 不再依賴舊的 `start, duration, enabled = GetSpellCooldown(id)` unpack。
- 使用 `C_Secrets.ShouldSpellCooldownBeSecret(spellID)` 或 secrecy API 判斷。
- cooldown 不安全時，不要自行猜 start/duration。
- GCD 判斷應使用安全欄位，例如 `isOnGCD`，並用 live Retail 驗證。
- `isOnGCD` 只在 `SPELL_UPDATE_COOLDOWN` 事件脈絡下作為可信判斷候選。
- `C_Spell.GetSpellCharges` 同樣可能受 cooldown restriction 影響；charge 欄位不可在未檢查前直接運算。
- 舊 `GetSpellCooldown` 頁面已明確標示 11.0.0 起移除/取代，新架構不得把它當核心 fallback。

## DurationObject 與 C_CurveUtil 系統

12.0.0 新增 `DurationObject`，12.0.1 加入 `DurationObject:GetClockTime`，而在 12.0.7 則補強了原生文字與曲線綁定。

### 🔑 DurationObject 核心內置方法與安全陷阱
- **`durationObj:IsZero()`**：
  - *用途*：檢測持續時間是否已為 0 (已過期)。
  - *致命陷阱*：在戰鬥或 Restricted (受限) 狀態下，此方法會回傳 **`SecretBoolean`**。若在 Lua 中直接執行 `if durationObj:IsZero() then`，會立即引發致命崩潰：`attempt to perform boolean test on a secret value`！
  - *安全防禦*：必須使用 `issecretvalue(val)` 或 `pcall` 進行預防性保護，或者完全交給 C++ 原生的 `clearIfZero` 參數（例如在 `SetCooldownFromDurationObject` 中設定）。
- **`durationObj:GetRemainingDuration()`**：
  - *用途*：取得剩餘秒數。
  - *限制*：在 Restricted（戰鬥限制）狀態下，會回傳被加密的 **`SecretValue`**。直接對其進行 Lua 算術運算（如 `+ - * / < > ==`）會直接觸發致命紅字錯誤。
- **`durationObj:GetClockTime()`**：
  - *用途*：用於底層原生時鐘同步，杜絕漂移與 UI 抖動產生的 Taint。但在戰鬥中這同樣也是 `SecretValue`。

### 🎨 C_CurveUtil (曲線視覺化工具) 戰鬥防 Taint 機制
為了解決在戰鬥中無法直接以 `if remaining < 5 then` 進行時間比對以改變圖示顏色或閃爍（因為會觸發 `SecretValue` 比較崩潰）的問題，暴雪引入了 **`C_CurveUtil`**：
*   **機制**：AddOn 可使用 `C_CurveUtil.CreateCurve()` 建立非線性的顏色或透明度曲線映射，例如定義「在剩餘時間小於 20% 時變紅（Pandemic 判定）」。
*   **綁定**：將此曲線與 `DurationObject` 一併綁定至 Status/Progress Bar 或 Cooldown 控件（例如 `statusBar:SetColorCurve(curve, durationObject)`）。
*   **優勢**：所有的數學比較與顏色轉換都發生在 C++ 原生層，**100% 避免了 Lua 呼叫堆疊的 Taint，且完全免去了 per-frame OnUpdate 垃圾回收壓力**！

### 📝 12.0.7 原生 FontString 與 Cooldown 顯示綁定
*   **`C_DurationUtil.CreateDurationTextBinding(durationObject, fontString)`**：
    - 在 12.0.7 中，可以直接將 `DurationObject` 與 FontString 進行原生綁定。倒數秒數文字直接在 C++ 渲染更新，免去了 Lua 每幀拼字串的負擔。
    - 清除時必須使用 `timerBinding:Unbind()` 且對 FontString 呼叫 `fontString:ClearText()`（12.0.1 引入，用以移除 Text secret aspect，防止 Secret Anchor 污染）。
*   **`Cooldown:SetCooldownFromDurationObject(durationObject [, clearIfZero])`**：
    - Cooldown 遮罩專用的原生綁定。當為 zero-span 時，設定 `clearIfZero = true` 會由原生引擎自動清除 Swipe 遮罩。

Warcraft Wiki `ScriptObject DurationObject` 說明 DurationObject 用於讓原生端對可能 secret 的時間資料做計算，再把結果回傳給 Lua。它可由 `C_DurationUtil.CreateDuration()` 建立，也可由 aura、cast、spellbook cooldown duration 等 API 回傳，並可傳給 `Cooldown:SetCooldownFromDurationObject()` 或 `StatusBar:SetTimerDuration()`。

12.x 規劃方向是移除剩餘時間 API，改用 duration object：

```lua
C_ActionBar.GetActionCooldownRemaining
C_ActionBar.GetActionCooldownRemainingPercent
C_Spell.GetSpellCooldownRemaining
C_Spell.GetSpellCooldownRemainingPercent
C_UnitAuras.GetAuraDurationRemaining
C_UnitAuras.GetAuraDurationRemainingPercent
```

上述 API 應避免成為新架構依賴。

重要 widget API：

```lua
Cooldown:SetCooldownFromDurationObject(duration [, clearIfZero])
Cooldown:SetCooldownFromExpirationTime(expirationTime, duration [, modRate])
Cooldown:SetPaused(paused)
Cooldown:GetCountdownFontString()
```

EAM `Renderer` 實作規則：

- 若有安全 `DurationObject`，優先交給 `Cooldown:SetCooldownFromDurationObject()`。
- 不在 Lua hot path 自己每幀計算剩餘秒數。
- timer text 若無法安全取得，就不要顯示假秒數。
- `IconRenderState.timer.mode` 要明確標示：`numeric`、`displayOnly`、`protected`、`unknown`。
- 不把 `DurationObject` 序列化，不寫入 SavedVariables，不放入 debug facts。
- 若要顯示 duration，Renderer 僅負責把 object 傳給支援的 widget；service state 只標記來源與 mode。

## FontString 與 Text Secret Aspect

12.0.1 新增：

```lua
FontString:ClearText()
```

其用途是把文字設為空字串，並移除 Text secret aspect。

EAM Renderer 建議：

- 清空可能接觸過 secret text 的 FontString 時，優先實測 `ClearText()`。
- 若 `ClearText()` 可用，清 timer/name/stack label 時使用它。
- 不要用 secret-derived string 做 `SetText` 後再回讀。
- `SetText` 必須做 value gating，避免重複 UI 寫入與 GC。

## Tooltip / C_TooltipInfo Duration Parsing

`C_TooltipInfo` 可以作為低頻 fallback，但不能是 hot path。

在 12.x / Midnight 當中，應特化使用 **`C_TooltipInfo.GetUnitBuffByAuraInstanceID(unitToken, auraInstanceID [, filter])`** 與 **`GetUnitDebuffByAuraInstanceID(unitToken, auraInstanceID [, filter])`**。這兩個 API 完美橋接了 `NeverSecret` 的 `AuraInstanceID`，實現了資料與 UI 的數據驅動解耦，提供極低的 GC 開銷且遠比舊式 `SetUnitBuff` 模擬渲染安全。

### 🚨 關鍵避坑點 1：嚴禁調用 `TooltipUtil.SurfaceArgs`
在 Patch 10.1.0 之後，`C_TooltipInfo` 的數據在返回 Lua 時就已經由底層原生自動「Surfaced」，此 SharedXML 庫輔助函數已經被暴雪**徹底移除 (nil)**。
* 任何對 `TooltipUtil.SurfaceArgs` 的調用都會直接觸發 `attempt to call field 'SurfaceArgs' (a nil value)` 導致 AddOn 崩潰。
* 12.x 開發應直接存取 `TooltipDataLine.leftText`。

### 🚨 關鍵避坑點 2：直接存取 `line.leftText` 的屬性讀取與自訂函數傳參雙重崩潰
> [!WARNING]
> **少年欸最頂尖的實戰發現（超關鍵）**：
> 1. 如果試圖將一個受限/帶有 Secret Aspect 的 Table 包進自訂的 Lua 函數（例如 `GetSafeLeftText(line)`）中處理，**在「將該 Table 作為參數傳給自訂 Lua 函數」這一步，就會因為沙盒安全防禦直接丟出參數違規錯誤而崩潰！** 
> 2. 這是因為受限的 Secret/Protected 物件是禁止傳遞給非受信任的自訂 Lua 函數的。
> 
> 因此，**「包進自訂 FUNCTION 傳參」這條路在戰鬥中是絕對不可行的！**

#### 🛡️ 100% 絕對可行且安全的「本地 Inline pcall 匿名閉包」防禦方案：
為了在不調用自訂函數傳參的前提下，安全地讀取 Table 屬性，我們必須使用系統內建、具有底層 C++ 執行豁免權與錯誤捕獲權的 **`pcall`**，在**同一個 Local 作用域（Scope）內進行本地 inline 匿名閉包讀取**：

```lua
-- ====================================================================
-- 本地 Inline pcall 屬性盾範例 (在業務代碼中直接原地 inline 呼叫)
-- ====================================================================
local data = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", instanceID)

-- 1. 用 pcall 在本地安全讀取 lines 表，防止 data 被限制時直接讀屬性崩潰
local dataOk, lines
if data then
    dataOk, lines = pcall(function() return data.lines end)
end

if dataOk and lines then
    for i = 1, #lines do
        local line = lines[i]
        
        -- 2. 用 pcall 本地匿名閉包讀取 leftText，絕不將 line 作為參數傳出！
        local lineOk, text
        if line then
            lineOk, text = pcall(function() return line.leftText end)
        end
        
        -- 3. 確保讀取成功，且最終獲取的字串值不是 Secret Value，此時 text 100% 安全
        if lineOk and text and not issecretvalue(text) then
            -- 在此安全地進行任何 string.find 等 Lua 運算！
            if string.find(text, "恢復") then
                -- 處理邏輯
            end
        end
    end
end
```

EAM `AuraService` 與其他分析模組在存取任何可能受到限制的 C_TooltipInfo 返回值時，**一律嚴格遵循此本地 Inline pcall 匿名閉包模式**，杜絕任何裸讀查表與自訂函數傳參。

`C_TooltipInfo.GetUnitAuraByAuraInstanceID` 在 12.0.0 加入，predicate 包含 `MayReturnNothing` 與 `SecretWhenInCombat`，並且 `SecretArguments` 只允許 untainted 使用。其 filter 在 12.0.1 新增 `CROWD_CONTROL`、`RAID_IN_COMBAT`、`RAID_PLAYER_DISPELLABLE`、`BIG_DEFENSIVE`、`IMPORTANT`。

可考慮解析：

- 靜態「持續 X 秒」描述。
- 靜態「恢復時間」描述。
- 靜態最大冷卻時間描述。

必須避開：

- 動態倒數文字。
- 包含「尚有」的文字。
- 包含 `Remaining` 的文字。
- 任何未經 `issecretvalue(text)` 檢查的 line text。

原因：

- 12.x 中由 secret 值生成的動態文字可能本身就是 secret userdata。
- 對 secret text 做 `string.match` 可能直接錯誤。
- Tooltip parsing 會產生字串與 table 解析成本，不可放在 `OnUpdate`。

EAM 實作規則：

- Tooltip parsing 只能在事件觸發、cache miss、設定變更、或低頻 idle fallback 時執行。
- 不可在 `Renderer` 執行。
- 不可在 per-icon timer 執行。
- 解析前先檢查 text 安全。
- 若 tooltip API 在 combat 中回傳 secret 或 nil，直接降級，不重試熱迴圈。
- 新增 filter 只能作為縮小 tooltip 來源的提示，不可當作安全保證。
- 黑名單關鍵字優先於 pattern match。
- 解析結果若不是原生 API fact，應標為 `derived` 或 `fallback`，不可冒充原生 facts。

## Item Cooldown 與 Item-Spell Mapping

Warcraft Wiki 12.x 變更重點沒有支持 EAM 繼續做大範圍 itemID 掃描。

EAM `ItemCooldownService` 規則：

- 直接 itemID cooldown monitoring 優先。
- item-spell mapping cache 只能 opt-in。
- cache building 必須 idle-only、非戰鬥、FPS-aware、可中斷。
- 不可在 combat 中掃 large item range。
- 不可把 cache builder 放在登入 hot path。

## 事件與架構

12.x 不適合讓 EAM 繼續依賴 combat log 盲掃。

建議事件：

```lua
PLAYER_LOGIN
PLAYER_ENTERING_WORLD
PLAYER_REGEN_ENABLED
PLAYER_REGEN_DISABLED
PLAYER_TARGET_CHANGED
UNIT_AURA
SPELL_UPDATE_COOLDOWN
SPELL_UPDATE_CHARGES
BAG_UPDATE_COOLDOWN
UNIT_SPELLCAST_SUCCEEDED
ADDON_RESTRICTION_STATE_CHANGED
```

實作規則：

- 使用單一 `EventRouter` frame。
- 事件 frame 可用 `CreateFrame("Frame", nil, nil)` 形成孤兒 frame，降低 UI taint 風險。
- 不使用 `RegisterAllEvents`。
- 不在事件 handler 內建立 closure。
- 事件只標記 dirty state，實際 UI 寫入交給 Renderer batch。

## SavedVariables 規則

12.x 規劃/文件指出 secret 不應進入 SavedVariables；secret serialization 可能被替換成 nil。

EAM 規則：

- SavedVariables 只存 user config。
- 不存 aura runtime state。
- 不存 cooldown runtime state。
- 不存 `DurationObject`。
- 不存 secret value。
- 不存 debug snapshot 中的 unsafe raw value。

## Debug Export 規則

Debug export 必須分層：

```js
{
  facts: {},
  derived: {},
  boundaryWarnings: [],
  humanNotes: [],
  environment: {}
}
```

規則：

- 只有 safe fact 能進 `facts`。
- Tooltip parsing 結果進 `derived` 或標記 `fallback`。
- secret/protected/unavailable 狀態進 `boundaryWarnings`。
- 不輸出 huge logs。
- 不自動 export。
- 不把 secret 值轉字串。

## Live Retail 12.x 必測項目

以下都不能只靠文件假設：

- `issecretvalue`、`canaccesstable`、`canaccessvalue` 實際名稱與行為。
- `C_Secrets.Should*` 系列是否在目標 build 全部存在。
- `C_Secrets.GetSpellAuraSecrecy`、`GetSpellCooldownSecrecy` 回傳 enum 內容。
- `C_UnitAuras.GetAuraDuration` 回傳的 `DurationObject` 行為。
- `Cooldown:SetCooldownFromDurationObject()` 是否可接 secret-safe duration。
- `FontString:ClearText()` 是否能安全清 Text secret aspect。
- `Cooldown:SetCountdownFormatter()` 與 `SecondsFormatter` 是否能安全接收 secret duration。
- `Cooldown:SetCountdownMillisecondsThreshold()` 小數顯示在 zhTW/enUS locale 的實際效果。
- `C_Spell.GetSpellChargeDuration()` 在 max charges 時是否回傳 zero-span duration。
- zero-span `DurationObject` 的 fully elapsed 行為是否符合 EAM 冷卻完成判定。
- cooldown-duration APIs 的 `ignoreGCD` 參數實際名稱、預設值與適用 API 清單。
- `AuraData.isHelpful`、`isHarmful`、`isRaid`、`isNameplateOnly`、`isFromPlayerOrPlayerPet` 是否在限制狀態下穩定 non-secret。
- encounter / M+ / PvP 開始時 `auraInstanceID` 是否如文件所述重新隨機。
- `table.freeze` 與 `table.isfrozen` 是否存在於目標 client，且對 SavedVariables/runtime state 的誤用是否會造成錯誤。
- `SPELL_UPDATE_COOLDOWN` 是否帶 spellID 或可縮小更新範圍。
- `SpellCooldownInfo.isOnGCD` 是否可靠。
- `C_TooltipInfo.GetUnitAuraByAuraInstanceID` 對 secret aura 的限制。
- dynamic tooltip line 是否可能為 secret userdata。
- secret restriction forced CVars 的名稱與可用性。
- 12.0.7 的 `C_DurationUtil.CreateDurationTextBinding`、`CreateManualClock` 與移除 `GetCurrentTime` 對 EAM timer 顯示層的實際影響。

## 對 EAM Rewrite 的結論

EAM 12.x 架構應採用：

- Retail-only。
- event-driven first。
- single scheduler。
- no timer-per-icon。
- no timer-per-spell。
- no large item scan by default。
- facts/derived/boundaryWarnings 分離。
- DurationObject 優先於 Lua 秒數運算。
- Tooltip parsing 只作低頻 fallback。
- Renderer 不查 API。
- SavedVariables 永遠不保存 runtime/secret state。
