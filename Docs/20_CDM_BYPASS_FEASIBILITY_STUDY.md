# Docs/20_CDM_BYPASS_FEASIBILITY_STUDY.md
# 12.1.0 影子載體技術 (Shadow Host) 可行性評估與實施計劃：借用官方 CooldownViewer 繞過戰鬥 Secret/Taint 限制

本文件針對利用魔獸世界 12.0.7 / 12.1.0 正式服內建的 **CooldownViewer (冷卻管理器/CDM)** 作為「影子載體（Shadow Host）」，以解決 EAM 戰鬥中 Secret Value 受限與 Taint Tunnels 之方案，進行深度技術評估與架構設計。

---

## 一、 技術原理：什麼是「影子載體 (Shadow Host)」？

在 Retail 12.x 環境中，戰鬥中獲取 cooldown/aura 時間（如 timeLeft, expirationTime）已被限制（Secret Value），且在戰鬥中動態修改 UI 佈局極易引發 Action Blocked 崩潰。

官方內置的 `EssentialCooldownViewer` 與 `UtilityCooldownViewer` 是暴雪的原生 Secure Frame，享有戰鬥中完全更新、定位與倒數的特權。

**影子載體技術 (Shadow Host)**：
1.  **影子初始化**：在戰鬥外，將官方 CooldownViewer 的 Frame 設置為透明（Alpha = 0）或降至最低 Frame Level (BACKGROUND, -100)，使其視覺上完全不可見。
2.  **寄生錨定**：將 EAM 的美化 Icon 作為 Child Frame 掛載（Parented）到官方對應的 Cooldown Icon 上。
3.  **無代碼同步**：利用 WoW 引擎內建的 Parent-Child 級聯渲染：
    *   官方 Icon 被 Show/Hide 時，EAM 的 Icon 會**自動** Show/Hide。
    *   官方 Icon 移動或重排（Layout）時，EAM 的 Icon 隨之位移。
    *   由於完全依賴底層 C++ 引擎的渲染級聯，**戰鬥中不需要執行任何 Lua 代碼來控制顯示與位置，實現 0-Taint 與 0-GC 戰鬥同步**。

```text
 Blizzard CooldownViewer (Shadow Host) [Alpha = 0, Secure Frame]
   └── (Parent-Child Bind)
        └── EAM Custom Icon (Parasitic Frame) [Alpha = 1, Display Only]
```

---

## 二、 可行性分析與 API 邊界稽核

### 1. 官方 API 與 SpellID 限制
*   **特性**：`C_CooldownViewer` 僅允許追蹤「暴雪官方數據庫內置並支持的 SpellID」。
*   **評估**：對於職業大招（如聖騎翅膀 31884、戰士魯莽 1719）及核心 Buff/DoT，官方均有內置支持。但對於玩家自訂的稀有/臨時 SpellID，官方 CDM 無法載入。
*   **策略**：EAM 採用**雙軌驅動**：
    *   **影子載體軌（Track A）**：對於官方支持的核心 SpellID，啟用影子載體掛載，獲得 100% 戰鬥穩定性。
    *   **常規數據軌（Track B）**：對於自訂或非官方支持的法術，降級使用 EAM 自身的計時器與安全 fallback 渲染。

### 2. Taint 與戰鬥鎖定 (Combat Lockdown) 避讓
*   **問題**：若在戰鬥中調用 `SetParent`、`SetPoint` 或者是修改官方 Frame，會直接引發 `attempt to modify secure frame` 崩潰。
*   **解決方案**：
    1.  **戰鬥外綁定**：所有 `SetParent`、`SetPoint`、`SetAlpha` 運作均限制在 `PLAYER_REGEN_ENABLED`（脫戰）或 `ADDON_LOADED`（加載時）進行。
    2.  **戰鬥中只讀**：戰鬥中（`InCombatLockdown()` 為 true 時），EAM 絕對不對官方 Frame 進行任何寫入操作，僅讓寄生的 Child Frame 被動受 C++ 引擎驅動。

---

## 三、 實作概念代碼 (Proof of Concept)

### 1. 影子化官方 CooldownViewer
在非戰鬥狀態下，對官方主要框架進行透明化，並降下 Frame Level。
```lua
local function MakeHostInvisible(hostFrame)
    if not hostFrame or InCombatLockdown() then return end
    
    -- 設為完全透明，但保留其 Child Widgets 的 Show/Hide 生命週期與 Layout 重排
    hostFrame:SetAlpha(0)
    
    -- 將層級降至背景最底層，以防萬一
    hostFrame:SetFrameStrata("BACKGROUND")
    hostFrame:SetFrameLevel(0)
end

local function InitShadowHosts()
    if EssentialCooldownViewer then
        MakeHostInvisible(EssentialCooldownViewer)
    end
    if UtilityCooldownViewer then
        MakeHostInvisible(UtilityCooldownViewer)
    end
end
```

### 2. 寄生掛載與 Layout 級聯
獲取官方圖示池（通常為一個 FramePool 或靜態 Array），並將 EAM 圖示錨定其上。
```lua
local function AnchorParasiticIcon(eamIcon, hostIcon)
    if InCombatLockdown() then return end
    
    -- 將 EAM 圖示的 Parent 設為官方圖示
    eamIcon:SetParent(hostIcon)
    eamIcon:ClearAllPoints()
    eamIcon:SetPoint("CENTER", hostIcon, "CENTER", 0, 0)
    
    -- 確保 EAM 圖示的 Strata 比官方高，且 Alpha 為 1
    eamIcon:SetFrameStrata("MEDIUM")
    eamIcon:SetFrameLevel(hostIcon:GetFrameLevel() + 10)
    eamIcon:SetAlpha(1)
    
    -- 影子載體會同步控制 eamIcon.Show / Hide
end
```

---

## 四、 風險與防範策略 (Mitigation Plan)

| 風險項目 | 影響 | 防範與優化策略 |
| :--- | :--- | :--- |
| **官方 Layout 變更** | 暴雪在 12.1.0 改變了 `EssentialCooldownViewer` 的子節點獲取方式 | 採用動態反射與特徵檢查，若無法獲取子圖示，自動降級關閉「影子載體」，回退至 Track B。 |
| **戰鬥中特殊載具覆蓋** | 進入載具時，官方 Host 隱藏，導致 EAM 寄生圖示也消失 | 這是預期行為（符合 `hideWhenActionBarIsOverriden`）。如果玩家想保留，可對 EAM 圖示手動調用提權或複製。 |
| **戰鬥 Taint 擴散** | 如果 EAM 的 Icon 包含 Click-to-Cast 或 Secure Action 按鈕 | **硬性規定**：EAM 的 Icon 僅作為「純視覺渲染器 (Display Only)」，不註冊任何 Click/Mouse-click 事件，不承擔安全動作，阻斷 Taint 傳回 Secure Chain。 |

---

## 五、 下一階段執行步驟 (12.1.0 重構清單)

1.  **第一階段 (調查與特徵捕獲)**：
    *   在脫戰狀態下，使用 debug 工具傾倒官方 `EssentialCooldownViewer` 的子物件結構，確定其 Icon Pool 的實體變數名。
2.  **第二階段 (單向影子試點)**：
    *   在測試代碼中，嘗試將 `EssentialCooldownViewer` 設為 Alpha = 0，並觀測是否會引發 EditMode 的 taint 警告。
3.  **第三階段 (雙軌渲染適配)**：
    *   在 `Renderer.lua` 中加入影子載體綁定邏輯。
