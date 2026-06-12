<!-- EAM_DOCUMENTATION_SOURCE: zh-TW -->
# EventAlertMod 專家角色 RACI 定位職責矩陣

為了讓EAM重構專案中的AI專家智庫在協作開發時有章可循，並確保PR審查、履行優化與API安全防禦的責任邊界劃分，本文件正式專案的RACI矩陣。

後續所有的子代理派工、主代理整合、PR審查與代碼變更，都必須嚴格遵守這個RACI原則。

---

## 1. RACI 定義說明
* **R (Responsible - 負責執行者)**：負責編寫程式碼、維護資料庫或編寫檔案的主要執行角色。
* **A（Accountable - 最終負責人）**：此任務領域的設計決策、架構搭建性與計畫碼安全負有最終責任的角色。 **每個任務領域只能有且有一個A**，其可以對PR進行批准或否決。
* **C（諮詢 - 諮詢對象）**：在設計、可行性評估、保密安全防禦或玩家實戰體驗上提供專業建議諮詢的角色。在執行任務時，必須主動向其獲取意見。
* **I (Informed - 通知對象)**：任務或設定變更時的通知對象，感知細緻結果以保持各資訊模組同步。

---

## 2. 專家縮寫對照表
| 縮寫 | 專家角色名稱 | 核心職能領域 |
| :--- | :--- | :--- |
| **拱門** | `EAM_Addon_Architect` | 插件核心架構、Taint避讓、安全鏈控制 |
| **SEC** | `EAM_API_Security_Expert` | Retail 12.x API 邊界、價值機密 安全防衛 |
| **符合** | `EAM_Performance_Expert` |熱路徑零分配 (0-Allocation)、訊框與 GC 節流重複使用
| **使用者介面** | `EAM_UI_Renderer_Expert` | 渲染器 渲染佈局、IconPool 管理、設定UI佈局 |
| **LUA** | `EAM_Lua_VM_Expert` | LuaJIT 底層優化、閉包快取、Inline pcall 頭審計 |
| **澳幣** | `EAM_Security_Auditor` | 官方UI逆向、繞過漏洞與降級策略審計 |
| **使用者體驗** | `EAM_UX_Gameplay_Expert` | 戰鬥實戰體驗、疫情刷新、文明覺醒 |
| **規格** | `EAM_Class_Expert` | 13 職業專精配置、資料庫卷校對|
| **TANK_P** | `EAM_Class_Tanks` | 6 大坦克生存Buff與主動減傷預警 |
| **HEAL_P** | `EAM_Class_Healers` | 6 大治療HoT 覆蓋與Proc 急救監控|
| **MEL_P** | `EAM_Class_Melee` | 近戰輸出連續資源節奏與流血DoT 監控 |
| **RNG_P** | `EAM_Class_Ranged` | 末端多目標DoT 維持與瞬發 Procs 置頂 |
| **PRO_T** | `EAM_Tank_Pro` | 頂尖坦克實戰版面與優先建議|
| **PRO_H** | `EAM_Healer_Pro` | 頂尖治療實戰版面與團隊框架防備建議|
| **PRO_M** | `EAM_Melee_DPS_Pro` | 頂尖近戰輸出資源防溢高亮建議 |
| **PRO_R** | `EAM_Ranged_DPS_Pro` | 頂尖法系移動實施法與爆發預警建議
| **模擬** | `EAM_Mock_Sandbox_Expert` | 魔獸API虛擬沙盒模擬、單元/整合測試框架維護 |
| **資料** | `EAM_Data_Guard_Expert` | SavedVariables WTF 文件版本架構升級與設定相容防禦 | SavedVariables WTF 文件版本架構
| **DEVOPS** | `EAM_DevOps_Release_Expert` | 自動化發布資源、TOC 偵測、靜態程式碼與語言系分析 |
| **刮刀** | `EAM_Combat_Scraper_Expert` | 戰鬥日誌分析、動態天賦監控、隱藏武器ID挖掘 |

---

## 3. RACI 職責矩陣表

|任務領域 |拱門 |美國證券交易委員會 |性能|用戶界面|路亞 |澳幣|用戶體驗 |規格|模擬|數據|Dk固定|刮刀|
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1.核心（核心路由/路由流程）** | **一個** |我| C|我| R/C |我|我|我|我|我|我|我|
| **2.服務（資料服務）** | **一個** | C | C|我| R/C |我|我| C|我| C|我|我|
| **3. UI / 渲染器（渲染引擎）** | C|我| R/C | **一個** | C | C | C|我|我|我|我|我|
| **4.保密/感染(安全防禦)**| C | **一個** | R/C |我| C | R/C |我|我|我|我|我|我|
| **5.配置與UI面板（設定面板）**| C|我|我|右|我|我| C|我|我| **一個** |我|我|
| **6。 Class DB（法術資料庫）** |我|我|我|我|我|我| **一個** |右|我|我|我| R/C |
| **7.資源並發布（發布資源）**| **一個** | C | C|我|我| C|我|我|我|我|右|我|
| **8.測試與模擬（沙盒測試）** | C | C | C|我|我|我|我|我| **A**/R |我| C|我|
| **9.資料遷移（WTF遷移）** | C|我|我| C|我|我|我|我|我| **A**/R |我|我|

*註：各職業與PRO玩家專家（TANK_P/HEAL_P/MEL_P/RNG_P/PRO_*）在Class DB與UI/Renderer領域的C/I定位維持原狀。 *

---

## 4. 各任務領域發展實施原則
### 1.核心（核心路由與排程系統）
* **變更範圍**：[Core/EventRouter.lua](file:///d:/EventAlertMod/Core/EventRouter.lua), [Core/Scheduler.lua](file:///d:/EventAlertMod__EAMCODE_12) [Core/Env.lua](檔案:///d:/EventAlertMod/Core/Env.lua), [Core/Main.lua](檔案:///d:/EventAlertMod__EAMCODE_16)。
* **Accountable (A)審查**：最終由**ARCH**決策，審核事件派發與調度調度任務分發鍊是否具備足夠的隔離與容錯防禦。
* **實踐與諮詢**：由 **LUA** 負責實踐，確保事件/定時器調度沒有建立瞬態表或匿名閉包。在優化 OnUpdate 的CPU執行時需諮詢**PERF**。

### 2. 服務（資料與業務邏輯服務）
* **變更範圍**：[Services/](file:///d:/EventAlertMod/Services/) 下的五大服務與狀態池（StatePool）機制。
* **Accountable (A) 審查**：由**ARCH**審查服務層的資料-視圖解耦度與事件主動機制。
* **實務與諮詢**：由 **LUA** 負責分配零 StatePool 的實務與GC防禦。由 **SEC** 諮詢資料讀取是否安全，**PERF** 諮詢事件節流與頻率控制。各職業專精智囊提供解答專精能量與動作時間同步的商業諮詢，移植 **DATA** 諮詢與 SavedVariables加載關聯的相容防禦。

### 3. UI / 渲染器（渲染與佈局引擎）
* **變更範圍**：[UI/Renderer.lua](file:///d:/EventAlertMod/UI/Renderer.lua), [UI/IconPool.lua](file:///d:/EventAlertMod/UI/IconPool.lua), 7 偏移量偏移框架與大偏移框架與大標座的成長框架與大標座成長框架的大偏移框架與大偏移框架。
* **Accountable (A)審查**：由**UI**負最終責任，審核貨架的標準化狀態消耗、按鍵文字綁定解綁與幀級別覆蓋。
* **實踐與諮詢**：由 **PERF** 佈局負責靜態關聯偏量算術的實踐，以消除分區尋找飢餓。由 **UX** 諮詢框架的預設座標與流行病輝光的承載形式，四大專業玩家提供實戰預警與框架防盜提示的設定諮詢。

### 4. 安全防禦與污點控制
* **變更範圍**：[Core/Util.lua](file:///d:/EventAlertMod/Core/Util.lua)中的三個檢查，所有OnUpdate倒數、表格索引、`InCombatLockdown()`延遲後防禦。
* **Accountable (A) 審查**：由**SEC** 審查100%的秘密邊界安全，確保不會因元方法崩潰或污點污染鏈導致行動高峰（Action Blocked）。
* **實務與諮詢**：由 **AUD** 負責 `C_TooltipInfo` 降級、`ShadowHostService` 吸附等高階疏導進行安全審計與實務。由 **ARCH** 諮詢 UIParent 下框架創設與屬性修改安全性。

### 5. Config & UI Panel（設定面板）
* **變更範圍**：[UI/Options.lua](file:///d:/EventAlertMod/UI/Options.lua), [Locale/](file:///d:/EventAlertMod/Locale/小地圖。
* **Accountable (A) 審查**：由**DATA**負最終責任，審核UI設定值的存檔搭建性與輸入合法性。
* **實務與諮詢**：由**UI**負責選項滑桿、能量表單、下拉篩選選單的實務。 **UX**與Pro玩家提供設定佈局的分析性與便利性諮詢。

### 6. Class DB (職業與英雄天賦資料庫)
* **變更範圍**：[Data/SpellArray.lua](file:///d:/EventAlertMod/Data/SpellArray.lua), 13 職業與 28 英雄天賦預設監控。
* **Accountable (A)審查**：由**UX**在大範圍M+或團本實戰中的循環負載下讀取磁帶庫，避免版面雜亂。
* **實務與諮詢**：由**SPEC**負責實踐藥劑ID、技能分類、以30%大流行秒數的整理與寫入。由**SCRAPER**負責解析日誌戰鬥動態數據，隱藏或被覆蓋的Buff ID作為數據校驗。

### 7.資源與發布（發布與資料夾）
* **變更範圍**：[Tools/Build-CurseForgePackage.ps1](file:///d:/EventAlertMod/Tools/Build-CurseForgePackage.ps1), [Tools/CheckLuaSyntax.ps1](file:///d1600cffCOD.發布排除清單。
* **Accountable (A)審查**：由**ARCH**審核版本號規範、TOC內容、壓縮目錄結構。
* **實務與諮詢**：由 **DEVOPS** 負責自動化預算與發布工具腳本的開發實踐，確保過濾排除路徑乾淨，並諮詢 **SEC/AUD** 是否存在漏洞。

### 8.測試與模擬（沙盒與模擬測試）
* **變更範圍**：本地配比測試腳本、調味API沙盒模擬環境（Mocking Layer）。
* **Accountable (A)審查**：由**MOCK**承擔最終責任，審核測試覆蓋率、測試資料模擬準確性。
* **實踐與諮詢**：由**MOCK** 實施沙盒​​與單元測試代碼，向**ARCH/SEC/PERF**諮詢核心代碼的執行語義與安全隔離點，並在預算前與 **DEVOPS**諮詢核心代碼的執行語義與安全隔離點，並在預算前與 **DEVOPS** 的 CI 整合。
### 9.資料遷移（WTF持久化與設定遷移）
* **變更範圍**：[Core/SavedVariables.lua](file:///d:/EventAlertMod/Core/SavedVariables.lua),歷史版本EA_*設定檔升級邏輯。
* **Accountable (A) 審查**：由**DATA**負最終責任，審核WTF資料遷移的損壞升級與防崩潰降級。
* **實務與諮詢**：由**DATA**負責實踐，向**ARCH**諮詢資料庫格式，向**UI**諮詢設定變更後的佈局同步。

---
## 5.後續開發遵循原則
1. **公關/實務派工守則**：
    * 在啟動任何子代理程式進行編碼之前，主代理程式必須先根據本矩陣，將任務領域的 **R** 專家分派為執行者。
2. **諮詢（C）防護守則**：
    * 在開發過程中遇到疑難問題時，必須主動向該任務領域對應的 **C** 專家發起諮詢。
3. **簽準（A）終審守則**：
* 子代理提交成果後，主代理在整合前，必須由本矩陣中該任務對應領域的 **A** 專家進行審查與簽發。