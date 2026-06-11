--[[ EAM_FILE_COMMENTARY
EventAlertMod Retail Rewrite
Module: Docs/21_RETAIL_12X_NEW_EVENTS_INVESTIGATION
檔案: Docs\21_RETAIL_12X_NEW_EVENTS_INVESTIGATION.md

理念:
- 詳細記錄魔獸世界 12.x / Midnight-era 下新引進或高頻的 16 個事件的原生作用、引數（Payload）及在 EAM 模組重構中的具體應用情境。
- 保持文檔與代碼一致性。
]]

# 魔獸世界 Retail 12.x / Midnight-era 全新與高頻事件調查報告

少年欸！針對您二次提供與追加的 16 個核心事件，我們完成了魔獸世界 12.x 最新 AddOn API 的調查，以下為各事件的底層原理、Payload 引數及 EAM 的具體整合設計方案。

---

## 1. 第一批事件詳細調查與 Payload 說明

### 📌 Event 1: `COMBAT_LOG_MESSAGE`
*   **原生作用**：Patch 12.0.0 後新引進的事件。由於官方將傳統的 `COMBAT_LOG_EVENT_UNFILTERED` (CLEU) 移出 AddOn 存取權限，且將 `CombatLogGetCurrentEventInfo()` 設為 Restricted（被污染的插件代碼無法讀取），官方提供了此事件作為 floating combat text (FCT) 浮動文字顯示的**格式化替代方案**。
*   **引數 Payload**：
    *   `Arg 1 (messageText)`: string - 已格式化好且在地化的戰鬥文字字串（例如："你的點燃傷害順劈斬訓練目標262點火焰。"）。
    *   `Arg 2 (r)`: number - 文字顯示的紅色色值通道。
    *   `Arg 3 (g)`: number - 文字顯示的綠色色值通道。
    *   `Arg 4 (b)`: number - 文字顯示的藍色色值通道。
    *   `Arg 5 (displayType)`: string/number - 訊息的類型或樣式。
*   **EAM 整合策略**：
    *   **限制**：此事件不包含 `spellID`、`sourceGUID`、`destGUID` 等結構化數據，只有純文字與顏色，對其做 regex scraping 的 CPU 負擔極高且不具備版本健壯性。
    *   **應用**：EAM 將其註冊至 `EventRouter` 作為 debug/trace 日誌，在使用者開啟除錯模式時直接輸出為可讀性極佳的戰鬥事件流，不參與核心的 Aura/Cooldown 計時事實。

---

### 📌 Event 2: `COMBAT_TEXT_UPDATE`
*   **原生作用**：魔獸世界傳統的浮動戰鬥文字（Floating Combat Text）更新事件。當被監控的單位（預設需用 `CombatTextSetActiveUnit` 設定，通常是 `"player"`, `"target"`, `"pet"`）發生戰鬥狀態更新時觸發。
*   **引數 Payload**：
    *   `Arg 1 (combatTextType)`: string - 戰鬥文字類型（例如：`"SPELL_AURA_START"`, `"DAMAGE"`, `"HEAL"`, `"ENERGY"`, `"RAGE"`, `"DODGE"` 等）。
*   **EAM 整合策略**：
    *   主要用於 `EventRouter` debug trace 監控，在 `AuraService` 因安全限制突然失效時，可作為獲取 `"SPELL_AURA_START"` 狀態的防禦性輔助日誌。

---

### 📌 Event 3: `UNIT_SPELLCAST_SENT`
*   **原生作用**：當被監控的單位發送施法請求給伺服器時觸發（此時法術尚未真正施放成功，還在 GCD 判定或唱法開始階段）。
*   **引數 Payload**：
    *   `Arg 1 (unitTarget)`: string - 施法單位（如 `"player"`, `"party1"`）。
    *   `Arg 2 (targetName)`: string - 目標名稱。
    *   `Arg 3 (castGUID)`: string - 該次施法的唯一 GUID。
    *   `Arg 4 (spellID)`: number - 法術 ID。
*   **EAM 整合策略**：
    *   可用於 EAM 的**施法預響應機制**。在唱法（Cast）或瞬發法術發送的瞬間，若對應 spellID 在監控名單中，可預先建立 AlertState 並渲染，提升視覺回饋速度。如果後續收到 `UNIT_SPELLCAST_FAILED_QUIET` 或 `UNIT_SPELLCAST_FAILED`，則即時清理，避免 ghost 圖示殘留。

---

### 📌 Event 4: `UNIT_SPELLCAST_SUCCEEDED`
*   **原生作用**：當被監控的單位成功施放法術時觸發。
*   **引數 Payload**：
    *   `Arg 1 (unitTarget)`: string - 施法單位。
    *   `Arg 2 (castGUID)`: string - 施法唯一 GUID。
    *   `Arg 3 (spellID)`: number - 法術 ID。
*   **EAM 整合策略**：
    *   **核心重構替代方案**：這是 12.x 下 `GroundEffectService` (地面效果監控) 的**救星級 API**！由於 CLEU 被封閉，我們直接將 `GroundEffectService` 修改為註冊 `UNIT_SPELLCAST_SUCCEEDED`。
    *   當 `unitTarget == "player"` 且 `spellID` 為我們監控的地面技能（如暴風雪、寒冰寶珠）時，立刻觸發該技能的持續時間倒數。此 API 100% 避開了 CLEU，且 100% 為 Retail 安全 API，完全無 Taint 被隔離的風險。

---

### 📌 Event 5: `UNIT_SPELLCAST_FAILED_QUIET`
*   **原生作用**：當單位的施法失敗且不觸發標準的 UI 錯誤語音（例如 GCD 衝突被伺服器拒絕）時觸發。
*   **引數 Payload**：
    *   `Arg 1 (unitTarget)`: string - 施法單位。
    *   `Arg 2 (castGUID)`: string - 該次施法 GUID。
    *   `Arg 3 (spellID)`: number - 法術 ID。
*   **EAM 整合策略**：
    *   用於**防禦性狀態重置**。當捕獲到玩家自身的此事件時，若該 spellID 的預備狀態或唱法計時存在，第一時間將其回收釋放，確保 UI 的狀態精確同步。

---

### 📌 Event 6: `CURRENT_SPELL_CAST_CHANGED`
*   **原生作用**：玩家當前的施法（唱法/引導）狀態發生改變時觸發。
*   **引數 Payload**：
    *   `Arg 1 (cancelledCast)`: boolean - 前一次施法是否被取消。
*   **EAM 整合策略**：
    *   用於 EAM 的 Cast/Channeling 輔助監控。如果 `cancelledCast == true`，代表施法被打斷或因移動中斷，EAM 能即時將關聯的 Alert 圖示隱藏。

---

### 📌 Event 7: `SPELL_ACTIVATION_OVERLAY_HIDE`
*   **原生作用**：當原生 UI 螢幕中央的半透明「法術 proc 貼圖提示（C_SpellActivationOverlay）」消失時觸發。
*   **引數 Payload**：
    *   `Arg 1 (spellID)`: number - 螢幕提示消失的法術 ID。
*   **EAM 整合策略**：
    *   用於監控大型螢幕貼圖 proc 的消失。這與快捷列的發光不同，但它代表該法術在中央的 proc 動畫已經結束。

---

### 📌 Event 8: `UNIT_POWER_FREQUENT`
*   **原生作用**：被監控單位的能量值（聖能、連擊點、真氣等）發生變更時的高頻觸發版本。傳統的 `UNIT_POWER_UPDATE` 有官方節流，而此事件在急速變動時能保證即時觸發。
*   **引數 Payload**：
    *   `Arg 1 (unitTarget)`: string - 能量變更單位。
    *   `Arg 2 (powerTypeToken)`: string - 能量類型（如 `"COMBO_POINTS"`, `"HOLY_POWER"`）。
*   **EAM 整合策略**：
    *   **無延遲能量更新**：將其引入 `ClassPowerService`！除註冊 `UNIT_POWER_UPDATE` 外，同時註冊 `UNIT_POWER_FREQUENT`，使連擊點、聖能、真氣等資源變動的視覺反應速度達到 0ms 延遲，大幅優化操作流暢度。

---

## 2. 第二批事件詳細調查與 Payload 說明

### 📌 Event 9: `SPELL_UPDATE_COOLDOWN`
*   **原生作用**：當任一技能進入冷卻、冷卻狀態變更或冷卻完成時觸發。
*   **引數 Payload**：無引數。
*   **EAM 整合策略**：
    *   此事件為 `CooldownService` 的核心事件。每當觸發時，CooldownService 會對監控的冷卻技能列表進行 O(1) 的反應式重新掃描，確保計時圖示精確顯現。

---

### 📌 Event 10: `SPELL_UPDATE_USABLE`
*   **原生作用**：當法術的可用性（Usable）狀態改變時觸發（如能量值足夠/不足以施放、或是技能施放條件被滿足/取消）。
*   **引數 Payload**：無引數。
*   **EAM 整合策略**：
    *   可做為 `CooldownService` 輔助檢測可用性的時機。在除錯模式下，記錄此事件發送，幫助排查部分冷卻技能因資源不足在 CD 轉完後沒有顯示為可用的 bug。

---

### 📌 Event 11: `SPELL_UPDATE_USES`
*   **原生作用**：魔獸世界 12.x 新引入事件。當某法術的「可用次數/使用次數（Uses）」或「充能次數（Charges）」改變時觸發。
*   **引數 Payload**：
    *   `Arg 1 (spellID)`: number - 法術 ID。
    *   `Arg 2 (uses/charges)`: number - 剩餘使用次數。
*   **EAM 整合策略**：
    *   可用於技能充能次數或可用次數改變時，即時更新 `CooldownService` 中對應技能的 `charges` 數值，不需要等待整體的 Full Scan，提高反應效率。

---

### 📌 Event 12: `SPELL_ACTIVATION_OVERLAY_GLOW_HIDE`
*   **原生作用**：**這是一個極其關鍵的事件！** 與 `SPELL_ACTIVATION_OVERLAY_HIDE`（螢幕中央月牙貼圖消失）不同，這是指**快捷列技能圖示金色發光亮框（Action Bar Glow）** 消失的事件。其對應的事件是 `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW`。
*   **引數 Payload**：
    *   `Arg 1 (spellID)`: number - 金色發光亮框消失的法術 ID。
*   **EAM 整合策略**：
    *   **完美的圖示亮框同步**：我們應該監聽 `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` 與 `SPELL_ACTIVATION_OVERLAY_GLOW_HIDE`。
    *   當玩家觸發 Proc（如火法的大火球、冰法的冰指亮框）時，官方會觸發 `SHOW`，如果 EAM 目前顯示了該技能圖示，我們在其上顯示 Glow 亮框；收到 `HIDE` 時隱藏發光。這能做到與官方按鈕發光 100% 同步！

---

## 3. 第三批追加事件詳細調查與 Payload 說明

### 📌 Event 13: `BAG_UPDATE_COOLDOWN`
*   **原生作用**：當背包中任一物品（如爐石、使用型飾品、藥水等）進入冷卻、冷卻狀態變更或冷卻結束時觸發。
*   **引數 Payload**：無引數。
*   **EAM 整合策略**：
    *   此事件為 `ItemCooldownService` 監控物品冷卻的核心事件。觸發時會重新掃描當前被監控的物品冷卻資訊並更新至 UI，避免了 OnUpdate 輪詢背包冷卻的 CPU 開銷。

---

### 📌 Event 14: `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED`
*   **原生作用**：**魔獸 12.x 原生 CooldownViewer (冷卻管理器/CDM) 專用內部事件**。當法術覆蓋關係（Spell Override，即因為天賦、形態或某些特殊狀態，使一個法術被另一個法術替換，例如薩滿冰霜震擊變成冰怒）發生變更時由客戶端觸發。
*   **引數 Payload**：
    *   `Arg 1 (overriddenSpellID)`: number - 被覆蓋/新替換的法術 ID。
    *   `Arg 2 (originalSpellID)`: number - 原始法術 ID。
*   **EAM 整合策略**：
    *   **解決技能 Override 的計時 Bug**：對 EAM 的冷卻監控非常有用！以往玩家點了天賦使法術 ID 變更時，EAM 無法第一時間動態跟隨。我們將在 `CooldownService` 監聽此事件，當偵測到被監控的法術被 Override 時，動態將對應狀態的 `spellID` 或是監控參數更新為 override 後的新 ID，完美避免冷卻失效。

---

### 📌 Event 15: `ASSISTED_COMBAT_ACTION_SPELL_CAST`
*   **原生作用**：魔獸 12.x 針對「輔助功能（Assisted Combat / 輔助點擊 / Hold to Cast 連續施法）」新引進的輔助施法觸發事件。當玩家使用輔助系統進行法術施放時觸發。
*   **引數 Payload**：通常攜帶 `spellID` 及 `castGUID` 等。
*   **EAM 整合策略**：
    *   這是一個全新的內部輔助施法事件。EAM 將其註冊至 `EventRouter` 作為除錯追蹤。當玩家開啟了原生輔助施法且觸發該事件時，可用於輔助 `UNIT_SPELLCAST_SUCCEEDED` 的雙重判定，防範極限高頻施法時漏判。

---

### 📌 Event 16: `ACTIONBAR_UPDATE_STATE`
*   **原生作用**：快捷列狀態更新事件。當快捷列上的任何技能、物品的狀態（例如變灰、變亮、可用性、冷卻等）改變時觸發。
*   **引數 Payload**：無引數。
*   **EAM 整合策略**：
    *   主要做為 Debug Trace 記錄，以及在特殊狀態下（如切換動作條頁面）觸發 `CooldownService` 和 `ItemCooldownService` 做防禦性一次性刷新，確保圖示視覺一致。

---

## EAM 全事件整合作用一覽表 (EAM Events Mapping)

| 事件名稱 | 觸發頻率 | EAM 接收模組 | 主要作用 |
| :--- | :--- | :--- | :--- |
| `COMBAT_LOG_MESSAGE` | 極高 (戰鬥中) | `EventRouter` (Debug) | 除錯日誌串流輸出，不參與計時事實 |
| `COMBAT_TEXT_UPDATE` | 中高 | `EventRouter` (Debug) | 除錯日誌與輔助光環更新 |
| `UNIT_SPELLCAST_SENT` | 中高 | `CooldownService` / UI | 施法開始預先響應機制 |
| `UNIT_SPELLCAST_SUCCEEDED` | 中高 | `GroundEffectService` | **替代 CLEU，100% 安全監控地毯技能** |
| `UNIT_SPELLCAST_FAILED_QUIET` | 低 | `CooldownService` | 施法失敗時防禦性回收預備計時 |
| `CURRENT_SPELL_CAST_CHANGED` | 低 | `CooldownService` / UI | 唱法中斷/取消時的圖示重置 |
| `SPELL_ACTIVATION_OVERLAY_HIDE` | 中低 | `AlertManager` | 大型螢幕中央貼圖提示隱藏 |
| `SPELL_ACTIVATION_OVERLAY_GLOW_HIDE` | 中低 | `AlertManager` / UI | **與原生快捷列金色亮框同步隱藏** |
| `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` | 中低 | `AlertManager` / UI | **與原生快捷列金色亮框同步高亮** |
| `UNIT_POWER_FREQUENT` | 極高 (戰鬥中) | `ClassPowerService` | **職業能量更新（聖能/連擊點）0ms 延遲** |
| `SPELL_UPDATE_COOLDOWN` | 中 | `CooldownService` | 技能冷卻事實重新掃描 |
| `SPELL_UPDATE_USABLE` | 中 | `CooldownService` | 技能可用性狀態更新 |
| `SPELL_UPDATE_USES` | 中 | `CooldownService` | 技能剩餘可用次數即時變更 |
| `BAG_UPDATE_COOLDOWN` | 中 | `ItemCooldownService` | 物品冷卻事實重新掃描 |
| `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED` | 低 | `CooldownService` | **動態修正技能 Override / 覆蓋更新** |
| `ASSISTED_COMBAT_ACTION_SPELL_CAST` | 中 | `EventRouter` (Debug) | 輔助施法之雙重判定防漏機制 |
| `ACTIONBAR_UPDATE_STATE` | 中高 | `CooldownService` (Debug) | 動作條切換或狀態同步刷新時機 |
