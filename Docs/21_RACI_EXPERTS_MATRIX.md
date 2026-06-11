# EventAlertMod 專家角色 RACI 職責定位矩陣

少年欸！為了讓 EAM 重構專案中的 AI 專家智囊團在協作開發時有章可循，並確保 PR 審查、效能優化與 API 安全防禦的責任邊界清晰，本文件正式定義專案的 RACI 職責矩陣。

後續所有 subagent 派工、主代理整合、PR 審查與代碼變更，都必須嚴格遵循此 RACI 原則。

---

## 1. RACI 定義說明

*   **R (Responsible - 負責執行者)**：動手編寫程式碼、維護資料庫或撰寫文件的主力執行角色。
*   **A (Accountable - 最終負責者)**：對該任務領域的設計決策、架構健壯性與程式碼安全負最終責任的角色。**每個任務領域只能有且僅有一個 A**，其有權對 PR 進行批准 or 否決。
*   **C (Consulted - 諮詢對象)**：在設計、效能評估、Secrecy 安全防禦或玩家實戰體驗上提供專業建議的諮詢角色。在執行任務時，必須主動向其獲取意見。
*   **I (Informed - 告知對象)**：任務完成或設定變更時的通知對象，被動知悉結果以保持各模組資訊同步。

---

## 2. 專家縮寫對照表

| 縮寫 | 專家角色名稱 | 核心職能領域 |
| :--- | :--- | :--- |
| **ARCH** | `EAM_Addon_Architect` | 插件核心架構、Taint 避讓、Secure Chain 控制 |
| **SEC** | `EAM_API_Security_Expert` | Retail 12.x API 邊界、Secret Value 安全防衛 |
| **PERF** | `EAM_Performance_Expert` | Hot Path 零分配 (0-Allocation)、Frame 復用與 GC 節流 |
| **UI** | `EAM_UI_Renderer_Expert` | Renderer 渲染管線、IconPool 管理、設定 UI 佈局 |
| **LUA** | `EAM_Lua_VM_Expert` | LuaJIT 底層優化、閉包快取、Inline pcall 開銷稽核 |
| **AUD** | `EAM_Security_Auditor` | 官方 UI 逆向、繞過漏洞與降級策略稽核 |
| **UX** | `EAM_UX_Gameplay_Expert` | 戰鬥實戰體驗、Pandemic 刷新、視覺降噪 |
| **SPEC** | `EAM_Class_Expert` | 13 職業專精配置、資料庫法術校對 |
| **TANK_P** | `EAM_Class_Tanks` | 6 大坦克生存 Buff 與主動減傷預警 |
| **HEAL_P** | `EAM_Class_Healers` | 6 大治療 HoT 覆蓋與 Proc 急救監控 |
| **MEL_P** | `EAM_Class_Melee` | 近戰輸出連續資源節奏與流血 DoT 監控 |
| **RNG_P** | `EAM_Class_Ranged` | 遠程多目標 DoT 維持與瞬發 Procs 置頂 |
| **PRO_T** | `EAM_Tank_Pro` | 頂尖坦克實戰版面與優先級建議 |
| **PRO_H** | `EAM_Healer_Pro` | 頂尖治療實戰版面與團隊框架防遮擋建議 |
| **PRO_M** | `EAM_Melee_DPS_Pro` | 頂尖近戰輸出資源防溢出高亮建議 |
| **PRO_R** | `EAM_Ranged_DPS_Pro` | 頂尖法系移動施法與爆發降噪建議 |
| **MOCK** | `EAM_Mock_Sandbox_Expert` | 魔獸 API 虛擬沙盒模擬、單元/整合測試框架維護 |
| **DATA** | `EAM_Data_Guard_Expert` | SavedVariables WTF 檔案版本 Schema 升級與配置相容防禦 |
| **DEVOPS** | `EAM_DevOps_Release_Expert` | 自動化發佈打包、TOC 檢驗、靜態代碼與語系分析 |
| **SCRAPER** | `EAM_Combat_Scraper_Expert` | 戰鬥日誌分析、動態天賦監控、隱藏法術 ID 挖掘 |

---

## 3. RACI 職責矩陣表

| 任務領域 | ARCH | SEC | PERF | UI | LUA | AUD | UX | SPEC | MOCK | DATA | DEVOPS | SCRAPER |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Core (核心路由/排程)** | **A** | I | C | I | R/C | I | I | I | I | I | I | I |
| **2. Services (數據服務)** | **A** | C | C | I | R/C | I | I | C | I | C | I | I |
| **3. UI / Renderer (渲染引擎)** | C | I | R/C | **A** | C | C | C | I | I | I | I | I |
| **4. Secrecy / Taint (安全防禦)**| C | **A** | R/C | I | C | R/C | I | I | I | I | I | I |
| **5. Config & UI Panel (設定面板)**| C | I | I | R | I | I | C | I | I | **A** | I | I |
| **6. Class DB (法術資料庫)** | I | I | I | I | I | I | **A** | R | I | I | I | R/C |
| **7. Package & Release (發佈打包)**| **A** | C | C | I | I | C | I | I | I | I | R | I |
| **8. Test & Mock (沙盒測試)** | C | C | C | I | I | I | I | I | **A**/R | I | C | I |
| **9. Data Migration (WTF 遷移)** | C | I | I | C | I | I | I | I | I | **A**/R | I | I |

*註：各職業與 PRO 玩家專家（TANK_P/HEAL_P/MEL_P/RNG_P/PRO_*）在 Class DB 與 UI/Renderer 領域的 C/I 定位維持原狀。*

---

## 4. 各任務領域開發實施原則

### 1. Core (核心路由與排程系統)
*   **變更範圍**：[Core/EventRouter.lua](file:///d:/EventAlertMod/Core/EventRouter.lua), [Core/Scheduler.lua](file:///d:/EventAlertMod/Core/Scheduler.lua), [Core/Env.lua](file:///d:/EventAlertMod/Core/Env.lua), [Core/Main.lua](file:///d:/EventAlertMod/Core/Main.lua)。
*   **Accountable (A) 審查**：由 **ARCH** 負最終責任，審核事件派發機制與 Scheduler 任務分發鏈是否具備足夠的隔離與容錯防禦。
*   **實作與諮詢**：由 **LUA** 負責實作，確保 Event/Timer dispatch 沒有建立 transient tables 或匿名閉包。在優化 OnUpdate 的 CPU 執行時需諮詢 **PERF**。

### 2. Services (數據與業務邏輯服務)
*   **變更範圍**：[Services/](file:///d:/EventAlertMod/Services/) 下的五大服務與狀態池（StatePool）機制。
*   **Accountable (A) 審查**：由 **ARCH** 審查服務層的數據-視圖解耦度與事件拋出機制。
*   **實作與諮詢**：由 **LUA** 負責零分配 StatePool 的實作與 GC 防禦。由 **SEC** 諮詢資料讀取是否安全，**PERF** 諮詢事件節流與頻率控制。各職業專精智囊提供對應專精能量與法術時間變動的業務諮詢，並向 **DATA** 諮詢與 SavedVariables 加載關聯的相容防禦。

### 3. UI / Renderer (渲染與佈局引擎)
*   **變更範圍**：[UI/Renderer.lua](file:///d:/EventAlertMod/UI/Renderer.lua), [UI/IconPool.lua](file:///d:/EventAlertMod/UI/IconPool.lua), 7 大獨立告警框架的坐標與成長偏移算法。
*   **Accountable (A) 審查**：由 **UI** 負最終責任，審核渲染管線的 normalized states消費、Timer text binding 解綁與 Frame level 遮擋。
*   **實作與諮詢**：由 **PERF** 負責 layout 靜態陣列偏量算術的實作，以消除 Hash 尋找開銷。由 **UX** 諮詢框架的預設坐標與 Pandemic glow 的呈現形式，四大 Pro 玩家提供實戰視覺干擾與框架防遮擋的配置諮詢。

### 4. Secrecy / Taint (安全防禦與 Taint 控制)
*   **變更範圍**：[Core/Util.lua](file:///d:/EventAlertMod/Core/Util.lua) 中的三大檢查，所有 OnUpdate 倒數、Table 索引、`InCombatLockdown()` 限制延後防禦。
*   **Accountable (A) 審查**：由 **SEC** 審查 100% 的 Secret 邊界安全，確保不會因 metamethod 崩潰或 Taint chain 污染導致動作阻擋（Action Blocked）。
*   **實作與諮詢**：由 **AUD** 負責對 `C_TooltipInfo` 降級、`ShadowHostService` 吸附等高級繞過進行安全稽核與實作。由 **ARCH** 諮詢 UIParent 下 the frame 創設與 attribute 修改安全。

### 5. Config & UI Panel (設定面板)
*   **變更範圍**：[UI/Options.lua](file:///d:/EventAlertMod/UI/Options.lua), [Locale/](file:///d:/EventAlertMod/Locale/) 語系，小地圖按鈕。
*   **Accountable (A) 審查**：由 **DATA** 負最終責任，審核 UI 設定值的存檔健壯性與輸入合法性。
*   **實作與諮詢**：由 **UI** 負責 Options 滑桿、能量 Checkbox、下拉篩選菜單的實作。**UX** 與 Pro 玩家提供設定佈局的直觀性與方便性諮詢。

### 6. Class DB (職業與英雄天賦資料庫)
*   **變更範圍**：[Data/SpellArray.lua](file:///d:/EventAlertMod/Data/SpellArray.lua), 13 職業與 28 英雄天賦預設監控。
*   **Accountable (A) 審查**：由 **UX** 審核法術庫在大範圍 M+ 或團本實戰中的視覺負載，避免版面雜亂。
*   **實作與諮詢**：由 **SPEC** 負責實作法術 ID、技能分類、與 30% Pandemic 秒數的整理與寫入。由 **SCRAPER** 負責解析戰鬥日誌動態數據，挖掘隱藏或被覆蓋的 Buff ID 作為數據校驗。

### 7. Package & Release (發佈與打包)
*   **變更範圍**：[Tools/Build-CurseForgePackage.ps1](file:///d:/EventAlertMod/Tools/Build-CurseForgePackage.ps1), [Tools/CheckLuaSyntax.ps1](file:///d:/EventAlertMod/Tools/CheckLuaSyntax.ps1), 發佈排除清單。
*   **Accountable (A) 審查**：由 **ARCH** 審核版本號規範、TOC 內容、打包目錄結構。
*   **實作與諮詢**：由 **DEVOPS** 負責自動化打包與發佈工具腳本的開發實作，確保過濾排除路徑乾淨，並諮詢 **SEC/AUD** 是否存在洩漏隱患。

### 8. Test & Mock (沙盒與 Mock 測試)
*   **變更範圍**：本地單元測試腳本、魔獸 API 沙盒模擬環境 (Mocking Layer)。
*   **Accountable (A) 審查**：由 **MOCK** 負最終責任，審核測試覆蓋率、測試數據 Mock 準確性。
*   **實作與諮詢**：由 **MOCK** 實作沙盒與單元測試代碼，向 **ARCH/SEC/PERF** 諮詢核心代碼的執行語意與安全隔離點，並在打包前與 **DEVOPS** 的 CI 整合。

### 9. Data Migration (WTF 持久化與設定檔遷移)
*   **變更範圍**：[Core/SavedVariables.lua](file:///d:/EventAlertMod/Core/SavedVariables.lua), 歷史版本 EA_* 設定檔升級邏輯。
*   **Accountable (A) 審查**：由 **DATA** 負最終責任，審核 WTF 數據遷移的無損升級與防崩潰降級。
*   **實作與諮詢**：由 **DATA** 負責實作，向 **ARCH** 諮詢數據庫格式，向 **UI** 諮詢設定變更後的佈局同步。

---

## 5. 後續開發遵循原則

1.  **PR / 實作派工守則**：
    *   在啟動 any subagent 進行代碼編寫前，主代理必須先根據本矩陣，將該任務領域的 **R** 專家分派為執行者。
2.  **諮詢（C）防護守則**：
    *   在開發過程中遇到疑難問題時，必須主動向該任務領域對應的 **C** 專家發起諮詢。
3.  **簽准（A）終審守則**：
    *   Subagent 提交成果後，主代理在整合前，必須由本矩陣中該任務領域對應的 **A** 專家進行審查與簽發。
