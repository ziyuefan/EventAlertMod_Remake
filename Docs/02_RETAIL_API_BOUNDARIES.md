<!-- EAM_DOCUMENTATION_SOURCE: zh-TW -->
# 正式服 API 邊界

## 正式服 12.x 假設

本重寫目標為 Retail 12.x / Midnight-era API。除非已在 WoW Retail 實機載入測試，否則本文件所有 API 筆記都視為文件假設。

優先使用命名空間：

- `C_AddOns`
- `C_Spell`
- `C_Item`
- `C_UnitAuras`
- `C_TooltipInfo`
- `AuraUtil`
- `C_Timer` 僅透過中央調度程序或明確非熱設定

除非有明確、嚴格且已文件化的正式服安全後備，不保留舊式解壓縮返回相內容層。

## 污染控制政策
Warcraft Wiki 的安全執行 / taint 文件指出，AddOn 與 `/script` 屬於不受信任來源；一旦 taint 進入 protected/secure 路徑，戰鬥中可能會導致 Blizzard UI 動作被匱乏。 EAM 必須把避免污染修改視為架構邊界，而不只視為 bug。

實行規則：

- 不鉤、覆寫、重新定義或猴子補丁 Blizzard secure/protected 函數、FrameXML 核心函數、動作按鈕、單位框架、銘牌、法術施法、瞄準、物品使用相關路徑。
- 不在戰鬥中修改受保護框架的屬性、父級、錨點、大小、可見性、模板或點擊行為。
- 不把secret/protected值、運行時快取、偵錯物件或addon回呼確定可能污染安全鏈的暴雪框架。
- EventRouter 使用孤兒框架；渲染框架僅作顯示，不承擔安全操作或受保護的互動。
- 需要 UIParent 訊框時，限定為非 protected 顯示用途；若 `InCombatLockdown()` 為 true，延後結構性 UI 變更。
- 不使用`forceinsecure`，不嘗試繞過污染，也不加入壓制暴雪阻止行動的解決方法。
- 發現污染、被阻止的動作、戰鬥鎖定錯誤時，需記錄到`Docs/15_DEVELOPMENT_ISSUE_LOG.md`。

## 目前 Aura API 使用審核

目前主線參考：

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
- 舊版 `UnitAura` / `select(10, UnitAura(...))` 後備路徑

重寫規則：

- Aura 事實必須來自安全結構化的正式服 Aura 數據，以穩定的 `NeverSecret` `AuraInstanceID` 為錨定。
- **阻止光環整合**：對於不需要的或垃圾/無用光環，請利用本機「C_UnitAuras.AddBlockedAura(unit, auraInstanceID)」將過濾委託給 C++ 引擎。只有當插件的執行路徑完全不受污染時才必須呼叫此方法 (`AllowedWhenUntainted`)。
- **本機雙管道持續時間**：偏好透過 `C_UnitAuras.GetAuraDuration` 檢索 C++ 黑盒 `DurationObject` 並直接提供給本機小工具（`CooldownFrame:SetCooldownFromDurationObject` 和 __EA__MCODE_13）。
- **大流行預測**：DoT刷新檢查必須在戰鬥中將`C_UnitAuras.GetRefreshExtendedDuration(unit, auraInstanceID)`與`GetAuraBaseDuration * 1.3`進行比較，以繞過受限的數字`timeLeft`檢查。
- 如果一个值是secret/protected/display-only，则标记`boundaryLimited`并且不要强制它通过正常的Lua比较或表键逻辑。
- 不要將廣泛的遺留 UnitAura 解包映射保留為體系結構。

## 当前冷却时间 API 使用情况审核

目前主線參考：

- `C_Spell.GetSpellCooldown`
- `C_Spell.GetSpellBaseCooldown`
- `C_Spell.GetSpellCharges`
- `C_Spell.GetSpellInfo`
- `C_Spell.GetSpellTexture`
- `C_Spell.GetSpellLink`
- `C_Spell.IsSpellUsable`
- `C_Spell.DoesSpellExist`
- 旧版全域 `GetSpellCooldown`、`GetSpellInfo`、`GetSpellTexture`、
  `GetSpellLink`、`GetSpellCharges`、`IsUsableSpell`
- `C_Secrets.ShouldSpellCooldownBeSecret`
- GCD 法術 ID `61304`

重寫規則：

- 偏好結構化的 `C_Spell` 回報。
- 當秘密/protected時，將冷卻事實視為不可用。
- 請勿偽造冷卻時間開始、持續時間或到期時間。
- 避免每幀重複的冷卻時間查詢。

## 目前物品冷卻 API 使用審核

目前主線參考：

- `C_Item.GetItemCooldown`
- `C_Item.GetItemSpell`
- `C_Item.DoesItemExistByID`
- `C_Container.GetItemCooldown` 作為一個別名層的後備
- 舊版全域 `GetItemCooldown`、`GetItemSpell`
- `GetInventoryItemCooldown`
- `GetInventoryItemID`
- 可選 `HeroDBC.DBC.ItemSpell`
- `EventAlert_ItemSpellCache.lua` 中的大項目範圍掃描

重寫規則：

- 首先支援直接itemID冷卻時間監控。
- 請勿在正常運作時掃描大範圍的項目。
- 任何物品-法術關係快取必須是選擇加入的、僅空閒的、可中斷的、
  FPS 意識和戰鬥意識。
## 目前專業化和在地化 API 審核

目前主線參考：

- `GetSpecializationInfoForClassID`
- `GetClassInfo`
- `GetSpecializationInfo`

重寫規則：

- **動態本地化**：使用本機 API 來查詢與客戶端當前語言設定動態對齊的匹配字串，而不是在配置 UI 中對本地化專業化或類別名稱進行硬編碼。
- **規範下拉過濾**：將類別標記映射到類別 ID（使用靜態枚舉映射，例如 `CLASS_TOKEN_TO_ID` 匹配 WoW 類別 ID）。透過 `GetSpecializationInfoForClassID(classID, specIndex)` 動態檢索規範名稱（其中 `classID` 是 1 到 13 之間的數字，`specIndex` 是 1 到 4 之間的數字）。
- **雙路徑回退**：當本機本地化 API 傳回 `nil` 或空值時，使用靜態本地化表 (`EAM.L`) 實作可靠的回退映射，以確保 UI 元件始終具有可讀的名稱。

## 秘密/受保護價值政策

當數據不安全或不可用時：

- **四個安全性檢查 API**：
  - `issecretvalue(value)`：檢查某個值是否被分類為秘密。
  - `canaccessvalue(value)`：確定目前上下文是否有權讀取某個值。
  - `canaccesstable(table)`：評估表的鍵和值是否可讀。
  - `issecrettable(table)` / `hasanysecretvalues(table)`：檢查表格結構是否受限或包含機密。
- **表格索引保護（嚴重）**：
- AddOns 絕對不能使用可能是「秘密值」的未經驗證的鍵來索引標準 Lua 表（例如，在戰鬥限制期間傳回 `spellId` 或 `text`）。
  - 嘗試使用金鑰對資料表進行索引會產生致命錯誤：「嘗試對無法使用金鑰進行索引的表進行索引」。
  - 總是使用「if not issecretvalue(key) and canaccesstable(tbl) then ... end」來保護表格查找。
- **資料驅動的工具提示與保密防禦**：
  - 戰鬥返回結構 `TooltipData` 中的直接 `C_TooltipInfo` 查詢 (`GetUnitBuffByAuraInstanceID`) 可能被標記為「秘密表」。
  - 從 `line.leftText` 解析靜態值時，請務必使用「if text and not issecretvalue(text) and canaccessvalue(text) then ... end」來防止秘密傳播。
- **無 `TooltipUtil.SurfaceArgs`**：在 12.x / Midnight 中，工具提示表是原生顯示的。 `TooltipUtil.SurfaceArgs` 幫助器被**完全刪除**；嘗試呼叫它會拋出致命的「nil value」Lua 錯誤。
- 繼續渲染安全狀態，例如 icon/name（如果可用）。
- 使用計時器模式 `protected`、`displayOnly` 或 `unknown`。
- 為偵錯狀態新增邊界警告。
- 僅在安全的情況下才安排非戰鬥刷新。
- 切勿將猜測值與事實混為一談。
- 切勿將不安全的值傳遞到 secure/protected UI 鏈中。

## 有意避免的 API/模式

- 經典 API 分支。
- MOP/Cata/Wrath/TBC API 傳回映射。
- `RegisterAllEvents`。
- 工具提示掃描作為普通資料來源（僅將其用於低頻靜態持續時間抓取回退）。
- `TooltipUtil.SurfaceArgs` 用法（始終讓本機引擎顯示參數）。
- 登入期間掃描大量物品 ID/combat。
- 每個圖示`SetScript("OnUpdate")`。
- 熱路徑中重複的`C_Timer.After(function() ...)`鏈。
- 配置的外部框架相依性。
- `forceinsecure` 或任何 taint 繞過、抑制被阻止操作的解決方法。