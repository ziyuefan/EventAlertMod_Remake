<!-- EAM_DOCUMENTATION_SOURCE: zh-TW -->
# 子代理程式工作流程規劃

本文件定義 EventAlertMod 開發時規劃並使用子代理程式。目標是讓大型工作可額外、可延期、可控制風險；不是把任務全部外包，也不是所有不必要的協調成本增加。

## 基本原則

- 只有在使用者已授權子代理、且任務可拆除時才能使用明確的邊界。
- 主代理先判斷關鍵路徑（關鍵路徑）：下一步立即停止的工作必須由主代理自己處理。
- 子代理程式處理 sidecar 任務（旁路任務）：可完成、具體、可驗收、不停止主代理下一步。
- 不重複派工；同一問題存在子代理結果時，除非有新證據或不同角度，不再派第二個做同樣分析。
- 程式修改型子代理程式必須有明確的書寫範圍，避免多個代理程式改同一個檔案。
- 所有分代理結果均需由主代理整合與最終判斷，不直接視為已驗證事實。

## 適合使用子代理人的姿勢

- 大型重寫頻道中，可精密互不重疊模組：
  - `Services/AuraService.lua`
  - `Services/CooldownService.lua`
  - `UI/Renderer.lua`
  - `Debug/PromptExport.lua`
- API 查詢與文件整理可和本地實作家具，例如：
- 12.x API 更改來源複核。
  - 秘密價值/污染討論整理。
  - DurationObject / DurationTextBinding 實踐方式比較。
- 驗證與掃描可與修復零件，例如：
  - 搜尋舊API直接呼叫。
  - 檢查`table.freeze`錯誤用。
  - 檢查 `C_Timer.After(function() ...)` 熱路徑。
  - 對 Docs 與 AGENTS 進行一致性檢查。
- 大量文件中文化、術語統一、測試清單補齊。
- Package / CurseForge 發布流程的旁路檢查，例如排除清單、TOC 版本、zip 命名規則。

## 不適合使用子代理人的姿勢

- 小型單檔修改，主代理可直接完成。
- 下一步完全依賴該結果，等待子代理改為拖慢關鍵路徑。
- 需要立即判斷使用者意圖、風險或授權的操作。
- 涉及刪除、搬遷、覆寫大量檔案，而尚未備份與範圍確認。
- 高修改連接，例如同時改變 `SavedVariables` schema、migration、Options UI、Slash command 且尚未開始開始範圍。
- 尚無明確的探索性問題。

## 角色使用建議

- explorer：用於特定問題的複雜調查，例如「尋找活動 Lua 中所有冷卻時間 API 通話」。
-worker：用於可分割的實作，例如「只修改UI/Options.lua，新增某個設定欄位，不碰SavedVariables」。
除非任務有明確理由，子代理程式使用預設繼承模型；不指定較昂貴或不同模型。

## 派工模板
```text
你是 EventAlertMod Retail rewrite 的 subagent。

範圍：
- 只能處理：<檔案或問題範圍>
- 不得修改：<明確排除範圍>

必要規則：
- Retail only。
- 不支援 Classic / MOP / Cata / Wrath / Era。
- 不繞過 Secret / Protected Data。
- 避免 taint；不 hook secure/protected chain。
- 修改任何既有檔案前需先備份到 backup/。
- 不還原他人變更。

輸出：
- 完成事項。
- 修改檔案。
- 驗證方式與結果。
- 未驗證事項。
- 風險與建議。
```
## 主代理整合規則

- 分代理完成後，主代理需快速審查結果與文件差異。
- 若子代理程式修改方案代碼，主代理程式仍需執行專案靜態驗證。
- 若子代理提供 API 資訊，主代理人需標明來源系統：
  - 官方文件或魔獸爭霸Wiki。
  - 用戶提供。
  - 搜尋索引。
  - 實機驗證。
- 若子代理程式遇到工具限制、API不確定性或錯誤，需追加至`Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- **Markdown 絕對事實與 HTML 轉換守則**：
  - 本專案與子代理程式開發協作的絕對指導文件，一律以 `AGENTS.md` 及其內文指名之 `.md` 檔案為唯一事實與 Facts-of-Truth 參考。
  - HTML 版本人類好讀與預覽使用。子代理執行開發、唯讀分析與回寫時，必須一律以 `.md` 原檔為唯一事實基準，不得以 HTML 文件作為事實參考。
- 任務若修改了文件下的 `.md` 檔案或 `AGENTS.md`，必須於修改後執行轉換工具，更新 `docs_html/` 下對應的 `.html` 檔案以確保一致性。

## RACI 專家分工與PR審查原則

為了讓 16 位 AI 專家在不同開發任務的定位明確，專案實施 RACI (Responsible, Accountable, Consulted, Informed) 分工定位。

詳細RACI矩陣配置與原則見：[Docs/21_RACI_EXPERTS_MATRIX.md](file:///d:/EventAlertMod/Docs/21_RACI_EXPERTS_MATRIX.md)。
後續所有子代理派工時需注意：
1. **R (Responsible)**：派工時，應指定被屬於該任務領域 **R** 的專家作為子代理的角色與職能（例如修改 Class DB 時指派 `EAM_Class_Expert`）。
2. **A (Accountable)**：子代理提交 PR 或結果後，主代理必須遷移到該任務領域 **A** 的專家進行審查與批准。
3. **C（諮詢）**：子代理在開發中遇到疑難問題時，必須主動向該任務領域被來自 **C** 的專家諮詢。

## 專案品質管制與要因分析原則

為確保程式碼品質與開發的嚴謹性，本專案導入5 Whys (WHY-WHY要因分析)、魚骨圖、對策評估矩陣與PDPC異常防禦機制。

詳細QC規格與指引請見：[Docs/22_QC_ROOT_CAUSE_ANALYSIS_GUIDE.md](file:///d:/EventAlertMod/Docs/22_QC_ROOT_CAUSE_ANALYSIS_GUIDE.md)。
後續開發遵循要求：
1. **Bug診斷**：遇到任何運行時崩潰或邏輯Bug，必須先執行**5個為什麼分析**與**魚骨圖要因分析**，追查根本原因，並讀取問題記錄中。
2. **對策擬定**：設計複雜方案時，必須在 `implementation_plan.md` 提出至少兩個候選方案，並以對策矩陣從效果、吸力、感覺、安全等維度進行量化評分。
3. **相依排程**：`task.md` 任務必須標示依賴（關係甘特圖精神），確保任務開發不會發生衝突。

## EAM 專案優先使用案例

1. Retail API 變更覆核與 Docs 回寫。
2. Secret / taint 風險審查。
3. AuraService 12.1.0 重構前置調查。
4. 渲染器 / DurationObject / DurationTextBinding 實作比較。
5. SavedVariables 遷移測試案例整理。
6. 預算與 CurseForge 發布檢查。

---

## 預定義子代理專家目錄 (預定義子代理專家)
本專案預先配置了16個子代理專家角色，封面API安全、執行優化、Lua基礎、UI渲染與13個職業的實戰監控專家團。主代理與開發者可在需要時，直接透過專家的職務定位進行派工與呼叫：

### 1. 核心開發與架構專家
* **EAM_API_Security_Expert (API 與安全防禦專家)**
* **職責**：專注12.x API邊界與Secret/Protected值限制審查，解析安全原則讀取（`issecretvalue`、`canaccessvalue`、`canaccesstable`）、`DurationObject`雙軌安全通道與Tooltip Scraping降級預警。
* **EAM_Performance_Expert（符合污染控制專家）**
    * **職責**：主導Hot Path零GC（零時分配）控制、Taint避讓策略（非安全框架隔離、InCombatLockdown限制延遲）、以及`IconPool`框架重複使用最佳化。
* **EAM_UI_Renderer_Expert（UI 與渲染架構專家）**
    * **職責**：專注UI與資料嚴格分離（渲染器只消費歸一化狀態）、`IconPool`與`CooldownFrame`渲染管理、選項選單版面與12.0.7原生文字綁定的實作。
* **EAM_Addon_Architect (插件開發與架構專家)**
    * **職責**：魔獸世界插件開發專家，熟悉FrameXML、Taint 、安全模板、SavedVariables結構與主流插件協作架構。
* **EAM_Lua_VM_Expert (Lua虛擬機器與編譯最佳化專家)**
    * **職責**：關注0-GC演算、閉包優化、記憶體管理、本地Inline pcall 匿名閉包開銷與底層元表機制評估。
* **EAM_Security_Auditor (安全性與 Taint 稽核專家)**
* **職責**：針對「原生ScrollingMessageFrame原始解密法」、「一鍵硬體事件提權宏」、「官方UI資料爬蟲（UI Scraping）」等高漏洞漏洞進行生命防週期阻塞與優化平穩降級稽核。

### 2.玩家體驗與實戰監控專家
* **EAM_UX_Gameplay_Expert（玩法與UX體驗專家）**
* **職責**：熟悉12.x各職業、疫情機制刷新點提示、DOT/BUFF監控、視覺疲勞優化與戰鬥場景動態載入避讓。
* **EAM_Class_Expert (職業專精專家代表)**
    * **職責**：代表13個職業、39個專精進行實戰監控配置與最佳化，提供30%的疫情臨界秒數與資源防災閾值。
* **EAM_Class_Tanks (坦克專精智庫)**
* **職責**：代表血DK、復仇DH、防騎、防戰、酒僧、熊德6大坦克，針對主動減傷、生存Buff與Boss尖峰傷害減傷預警給予配置建議。
* **EAM_Class_Healers (治療專精智庫)**
* **職責**：代表補德、神/戒牧、補僧、補薩、補騎、恩補喚能師6大治療，針對多目標HoT覆蓋、隨機觸發過程與團隊框架藍耗提供實戰建議。
* **EAM_Class_Melee (近戰DPS專精智庫)**
    * **職責**：代表賊、戰、DH、聖騎、DK、武僧、增強薩、貓德，針對能量/符文連續資源節奏與DOT流血的流行病刷新提供建議。
* **EAM_Class_Ranged（遠端DPS專精智庫）**
    * **職責**：代表法、術、暗牧、鳥德、要素薩、獵、喚能師，針對多目標DoT維持、過程瞬時發置頂與移動可用技能引導提供建議。
* **EAM_Tank_Pro (頂尖坦克玩家代表)**、**EAM_Healer_Pro (頂尖治療玩家代表)**、**EAM_Melee_DPS_Pro (近戰輸出玩家代表)**、**EAM_Ranged_DPS_Pro (遠程輸出玩家代表)**
* **職責**：分別代表各個目標，以高玩實戰視角為EAM提供極限狀態監控與視線優先級建議。