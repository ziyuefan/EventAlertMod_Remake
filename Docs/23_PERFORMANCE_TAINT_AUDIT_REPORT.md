# Performance & Taint Control 審查報告：統一 OnUpdate 計時器與 Layout 偏移陣列

> [!NOTE]
> 本文件由 EAM Performance & Taint Control Expert 撰寫，旨在評估 EventAlertMod 重構版中統一計時器（legacyTimer）的運作開銷、LAYOUT_OFFSETS 靜態偏移陣列的算術性能，並識別戰鬥中潛在的隱性 Taint 洩漏與 GC 垃圾分配問題。

---

## 1. 統一 OnUpdate 計時器（legacyTimer）運作開銷審查

`UI/Renderer.lua` 中的 `legacyTimer` 負責在不使用原生 Duration Binding 時，提供備用的秒數倒數顯示（尤其在 $timeLeft < 3.05$ 秒時提供小數點後一位倒數）。其運作機制為使用一個唯一的匿名偵聽 Frame 監聽 `OnUpdate`，遍歷 `activeLegacyTimers` 與 `activeDurationObjects` 以更新圖示的 `timerText`。

### 1.1 性能優勢
*   **單一 Frame 集中驅動**：避免了每個圖示或每個法術各自綁定 `OnUpdate` 的高開銷設計。當沒有 active 任務時，會調用 `legacyTimerFrame:SetScript("OnUpdate", nil)` 解除綁定，保持 CPU 零占用。
*   **孤兒 Frame 隔離**：`legacyTimerFrame` 為匿名無 Parent 的 Frame（`CreateFrame("Frame")`），完全與 `UIParent` 核心鏈解耦，消除了事件派發過程中的 Taint 傳播風險。

### 1.2 運作開銷與 GC 瓶頸分析
在高頻戰鬥環境（例如 60-120 FPS，擁有多個活動監控圖示）下，目前的實作存在顯著的 GC 與 CPU 開銷：
1.  **頻繁的字串格式化 (GC Heap 垃圾主要來源)**：
    *   在 `onLegacyTimerUpdate` 中，每幀對所有 active icon 執行：
        ```lua
        if timeLeft < 3.05 then
            text = string.format("%.1f", timeLeft)
        else
            text = string.format("%d", math.ceil(timeLeft))
        end
        ```
    *   在 Lua VM 中，`string.format` 會產生全新的字串對象。在 60 FPS 下，若有 5 個圖示同時倒數，一秒將配置 $60 \times 5 = 300$ 個字串。這會直接加速 GC 觸發，造成幀率抖動（Micro-stutter）。
2.  **`pairs` 雜湊表迭代開銷**：
    *   使用 `pairs(activeLegacyTimers)` 來遍歷活動計時器。在 LuaJIT 中，若遍歷雜湊表（Hash Part），JIT 編譯器可能無法有效進行 Trace Compiler 編譯，且迭代過程中對 table 進行 `activeLegacyTimers[icon] = nil` 的刪除操作，容易引起內部 Hash 結構重整與 GC 開銷。
3.  **`pcall` 所致的 JIT Trace Abort**：
    *   在 `activeDurationObjects` 迭代中，調用了 `safeCheckIsZero(durationObj)`，其內部包含 `pcall(durationObj.IsZero, durationObj)`。
    *   在 LuaJIT 中，`pcall` 會直接導致當前的 Trace 編譯失敗（Trace Abort），使得 OnUpdate 的核心執行路徑只能退回到低效的 interpreter 模式執行，大幅增加了每幀的 CPU 算術與調用開銷。

---

## 2. 7 大 Alert Frame Layout 靜態連續偏移陣列（LAYOUT_OFFSETS）審查

EAM 定義了 7 大獨立告警框架，並在排版時利用 `EAM.Constants.LAYOUT_OFFSETS` 做為位移向量：
```lua
LAYOUT_OFFSETS = freeze({
    freeze({ 1, 0 }),  -- 1 = RIGHT (向右成長)
    freeze({ -1, 0 }), -- 2 = LEFT (向左成長)
    freeze({ 0, 1 }),  -- 3 = UP (向上成長)
    freeze({ 0, -1 })  -- 4 = DOWN (向下成長)
})
```

### 2.1 CPU 算術開銷評估
在 `layout(frameName)` 執行時，其定位計算為：
```lua
local offset = EAM.Constants.LAYOUT_OFFSETS[dirIdx]
local dx, dy = offset[1], offset[2]
...
local dist = (layoutIndex - 1) * (size + spacing)
local offsetX = dx * dist
local offsetY = dy * dist
```

*   **算術性能極佳**：相較於舊版 EventAlert 的多重 `if-else` 或 `switch` 分支判斷（如 `if dir == 1 then x = ... else ...`），以連續數字索引陣列配合乘法運算，完全消除了 CPU 分支預測錯誤（Branch Misprediction）的可能。
*   **唯讀凍結保障**：使用了 `table.freeze` 確保該常數陣列在執行期不可被篡改，兼顧安全與效能。
*   **查表開銷評估**：雖然每次定位都需要從 `LAYOUT_OFFSETS` 讀取內部 table 元素，但在實際運作中，`layout` 僅在圖示增減或設定變更時被觸發（由 `BeginBatch/EndBatch` 節流，並非高頻熱路徑），因此其產生的微小查表開銷在整體 AddOn 中微不足道，屬於極佳的設計決策。

---

## 3. 戰鬥中隱性 Taint 洩漏與 GC heap 垃圾分配評估

經深入代碼走讀，我們發現了以下在戰鬥中高頻事件與渲染下，可能導致隱性 Taint 洩漏或 GC heap 垃圾分配的關鍵問題：

### 3.1 隱性 Taint 洩漏與戰鬥鎖定 (Combat Lockdown) 隱患
1.  **戰鬥中動態 `CreateFrame` (高風險點)**：
    *   雖然 `ensureParent` 具備 `InCombatLockdown` 守衛，但在 `Renderer.render` 中，如果 `IconPool` 的可用緩衝圖示用盡（例如在戰鬥中同時觸發多個天賦/冷卻/法術，使得 active 數量大於 prewarm 的 16 個），會觸發 `IconPool.acquire()` -> `createIcon()`：
        ```lua
        local function createIcon()
            local button = api.CreateFrame("Frame", name, UIParent)
            ...
            local cooldown = api.CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        ```
    *   **風險**：在戰鬥鎖定期間呼叫 `CreateFrame("Frame", name, UIParent)` 且載入了官方的 `CooldownFrameTemplate`，可能會污染暴雪內部的 Secure Template Chain，並高機率觸發 "Action blocked by an addon" 錯誤。
2.  **影子載體 (Shadow Host) 寄生模式的潛在 Taint 傳播 (極高風險點)**：
    *   雖然目前 `useCDM` 被強制設為 `false`，但若啟用此模式，代碼會將 EAM 的 icon 寄生在官方原生 `CooldownViewer` 或 ActionButton 下：
        ```lua
        icon:SetParent(hostIcon)
        icon:ClearAllPoints()
        icon:SetAllPoints(hostIcon)
        ```
    *   **風險**：官方的 `CooldownViewer` 與 ActionButton 屬於高度受保護的 Secure / Protected Frame。非安全的 EAM 圖示在戰鬥中呼叫 `SetParent` 附加到 Secure Frame 上，當暴雪 UI 試圖重新排版或操作該 Secure Frame 時，會因為其子系包含 Unsecure Frame 而導致整條執行鏈被標記為 Taint，進而引發戰鬥中 Action Button 被阻擋、無法點擊的致命錯誤。

### 3.2 隱性 GC Heap 垃圾分配隱患
1.  **熱路徑中的匿名閉包 `pcall`**：
    *   在 `Renderer.render` 中：
        ```lua
        pcall(function()
            icon:SetFrameStrata("MEDIUM")
            icon:SetFrameLevel(hostIcon:GetFrameLevel() + 10)
        end)
        ```
    *   每次渲染更新（如堆疊數、冷卻更新）時，都會在熱路徑中動態分配這兩個匿名 closure 函數，並調用 `pcall`。這不僅會阻礙 LuaJIT VM 的 Trace Compilation，還會產生持續的 GC 垃圾堆積。
    *   *註：`icon.overlay` 與 `icon.cooldown` 皆為 EAM 內部建立的 Frame，其方法是 100% 確定存在的，根本不需要使用 `pcall` 進行防護。*

---

## 4. 具體重構與優化建議

為了消除上述隱患並達成 EAM 重寫版的極致性能與零 Taint 要求，建議實施以下優化重構：

### 4.1 消除字串分配與 `pairs` 迭代：引進「時間字串快取」與「雙向鏈結串列」
*   **時間字串快取 (Time Text Cache)**：
    預先生成 $0.0$ 到 $3.0$ 秒（間隔 0.1 秒，共 30 個）以及 $3$ 到 $3600$ 秒的整數字串表。在 OnUpdate 中，通過數值計算直接索引此快取表，將格式化開銷降為零。
*   **平坦雙向鏈結/數值索引陣列**：
    將 `activeLegacyTimers` 改為使用數值索引的平坦陣列，藉此使用 `for i = 1, count` 進行數字循環迭代，消除 `pairs` 在高頻路徑下的 iterator 分配與雜湊查表開銷。

### 4.2 移除熱路徑 `pcall` 與匿名閉包
*   移除 `Renderer.render` 中對自建框架的 `pcall(function() ... end)` 包裝，改為直接賦值或使用預先定義好的靜態輔助函數，避免高頻分配。

### 4.3 強制執行戰鬥中 `CreateFrame` 與 `SetParent` 延遲
*   在 `IconPool.acquire()` 中加入 `InCombatLockdown` 檢測。若在戰鬥中且無可用 icon，應降級或將其加入延遲渲染佇列（`deferRender`），嚴禁在戰鬥鎖定期間呼叫 `api.CreateFrame`。
*   徹底廢除或嚴格限制影子載體（Shadow Host）寄生模式在戰鬥中的 `SetParent` 行為，避免任何與 Secure Frame 的直接 parent 連結。

---

## RACI 權責分工與審查結論
本審查報告依據 [Docs/21_RACI_EXPERTS_MATRIX.md](file:///d:/EventAlertMod/Docs/21_RACI_EXPERTS_MATRIX.md) 規範，由 **Performance & Taint Control Expert** 負責（Responsible），為 **Main Agent** 提供核心技術決策諮詢。

*   **建議決策**：在下一個重構週期中，應立即針對 `UI/Renderer.lua` 與 `UI/IconPool.lua` 進行局部重構，落實「時間字串快取」、「無 pcall 直接調用」以及「戰鬥中 CreateFrame 延遲守衛」，以確保 AddOn 運作時的極致低 GC 與絕對安全。
