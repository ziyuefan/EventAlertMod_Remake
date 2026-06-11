# Subagent 工作流規劃

本文件定義 EventAlertMod 開發時何時規劃並使用 subagent。目標是讓大型工作可並行、可追溯、可控風險；不是把所有任務都外包，也不是增加不必要的協調成本。

## 基本原則

- 只有在使用者已授權 subagent、且任務可拆成清楚邊界時才使用。
- 主代理必須先判斷 critical path（關鍵路徑）：下一步立即阻塞的工作由主代理自己處理。
- Subagent 適合處理 sidecar task（旁路任務）：可並行、具體、可驗收、不阻塞主代理下一步。
- 不重複派工；同一問題已有 subagent 結果時，除非有新證據或不同角度，不再派第二個做同樣分析。
- 程式修改型 subagent 必須有明確寫入範圍，避免多個代理改同一批檔案。
- 所有 subagent 結果都需由主代理整合與最終判斷，不直接視為已驗證事實。

## 適合使用 subagent 的情境

- 大型 rewrite pass 中，可切成互不重疊模組：
  - `Services/AuraService.lua`
  - `Services/CooldownService.lua`
  - `UI/Renderer.lua`
  - `Debug/PromptExport.lua`
- API 查證與文件整理可和本地實作並行，例如：
  - 12.x API change 來源複核。
  - Secret Values / taint 討論整理。
  - DurationObject / DurationTextBinding 實作方式比較。
- 驗證與掃描可與修補並行，例如：
  - 搜尋舊 API 直接呼叫。
  - 檢查 `table.freeze` 誤用。
  - 檢查 `C_Timer.After(function() ...)` 熱路徑。
  - 對 Docs 與 AGENTS 進行一致性檢查。
- 大量文件中文化、術語統一、測試清單補齊。
- Package / CurseForge 發佈流程的旁路檢查，例如排除清單、TOC 版本、zip 命名規則。

## 不適合使用 subagent 的情境

- 小型單檔修改，主代理可直接完成。
- 下一步完全依賴該結果，等待 subagent 反而拖慢 critical path。
- 需要即時判斷使用者意圖、風險或授權的操作。
- 涉及刪除、搬移、覆寫大量檔案，而尚未完成備份與範圍確認。
- 高耦合修改，例如同時改 `SavedVariables` schema、migration、Options UI、Slash command 且尚未界定寫入範圍。
- 尚未有明確驗收條件的探索性問題。

## 角色使用建議

- explorer：用於具體問題的只讀調查，例如「找出 active Lua 中所有 cooldown API 呼叫」。
- worker：用於可分割的實作，例如「只修改 UI/Options.lua，新增某個設定欄位，不碰 SavedVariables」。

除非任務有明確理由，subagent 使用預設繼承模型；不主動指定更昂貴或不同模型。

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
- 未驗證項目。
- 風險與建議。
```

## 主代理整合規則

- Subagent 完成後，主代理需快速審查結果與檔案差異。
- 若 subagent 修改程式碼，主代理仍需執行專案靜態驗證。
- 若 subagent 提供 API 資訊，主代理需標明來源層級：
  - 官方文件或 Warcraft Wiki。
  - 使用者提供。
  - 搜尋索引。
  - 實機驗證。
- 若 subagent 遇到工具限制、API 不確定性或錯誤，需追加到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- **Markdown 絕對事實與 HTML 轉換守則**：
  - 本專案與 subagent 開發協作的絕對指導文件，一律以 `AGENTS.md` 及其內文指名之 `.md` 檔案為唯一事實與 Facts-of-Truth 參考。
  - HTML 版本僅為人類好讀與預覽使用。Subagent 執行開發、唯讀分析與回寫時，必須一律以 `.md` 原檔為唯一事實基準，不得以 HTML 檔案作為事實參考。
  - 任務若修改了 docs 下的 `.md` 檔案或 `AGENTS.md`，必須於修改後執行轉換工具，更新 `docs_html/` 下對應的 `.html` 檔案以確保一致性。

## RACI 專家分工與 PR 審查原則

為了使 16 位 AI 專家在不同開發任務的定位明確，專案實施 RACI (Responsible, Accountable, Consulted, Informed) 分工定位。

詳細 RACI 矩陣配置與原則見：[Docs/21_RACI_EXPERTS_MATRIX.md](file:///d:/EventAlertMod/Docs/21_RACI_EXPERTS_MATRIX.md)。

後續所有 subagent 派工時需注意：
1. **R (Responsible)**：派工時，應指定被列為該任務領域 **R** 的專家作為 subagent 的 Role 與職能（例如修改 Class DB 時指派 `EAM_Class_Expert`）。
2. **A (Accountable)**：Subagent 提交 PR 或成果後，主代理必須交給被列為該任務領域 **A** 的專家進行審查與批准。
3. **C (Consulted)**：Subagent 在開發中遇到疑難問題時，必須主動向該任務領域被列為 **C** 的專家諮詢。

## 專案品質管制與要因分析原則

為確保代碼品質與開發的嚴謹性，本專案導入 5 Whys (WHY-WHY 要因分析)、魚骨圖、對策評估矩陣與 PDPC 異常防禦機制。

詳細 QC 規範與指引見：[Docs/22_QC_ROOT_CAUSE_ANALYSIS_GUIDE.md](file:///d:/EventAlertMod/Docs/22_QC_ROOT_CAUSE_ANALYSIS_GUIDE.md)。

後續開發遵循要求：
1. **Bug 診斷**：遇任何 runtime 崩潰或邏輯 Bug，必須先執行 **5 Whys 分析** 與 **魚骨圖要因分析**，追查根本原因，並寫入問題紀錄中。
2. **對策擬定**：設計複雜方案時，必須在 `implementation_plan.md` 提出至少兩個候選方案，並以對策矩陣從效果、可行性、效能、安全等維度進行量化打分。
3. **相依排程**：`task.md` 任務必須標明依賴關係（甘特圖精神），確保並行開發不發生衝突。

## EAM 專案優先使用案例

1. Retail API 變更複核與 Docs 回寫。
2. Secret / taint 風險審查。
3. AuraService 12.1.0 refactor 前置調查。
4. Renderer / DurationObject / DurationTextBinding 實作比較。
5. SavedVariables migration 測試案例整理.
6. 打包與 CurseForge 發佈檢查。

---

## 預定義 subagent 專家目錄 (Predefined Subagent Experts)

本專案預先配置了 16 個 subagent 專家角色，涵蓋 API 安全、效能優化、Lua 底層、UI 渲染與 13 個職業的實戰監控智囊團。主代理與開發者可在需要時，直接透過專家的職能定位進行派工與呼叫：

### 1. 核心開發與架構專家
*   **EAM_API_Security_Expert (API 與安全防禦專家)**
    *   **職責**：專注 12.x API 邊界與 Secret/Protected values 限制審查，解析安全讀取原則（`issecretvalue`, `canaccessvalue`, `canaccesstable`）、`DurationObject` 雙軌安全通道與 Tooltip Scraping 降級防範。
*   **EAM_Performance_Expert (效能與 Taint 控制專家)**
    *   **職責**：主導 Hot Path 零 GC（零時 allocation）控制、Taint 避讓政策（非 secure frame 隔離、InCombatLockdown 限制延後）、以及 `IconPool` frame 復用優化。
*   **EAM_UI_Renderer_Expert (UI 與渲染架構專家)**
    *   **職責**：專注 UI 與資料嚴格分離（Renderer 只消費 normalized states）、`IconPool` 與 `CooldownFrame` 渲染管理、Options 選單佈局與 12.0.7 native text binding 的實作。
*   **EAM_Addon_Architect (插件開發與架構專家)**
    *   **職責**：魔獸世界插件開發專家，熟悉 FrameXML、Taint 機制、安全模板、SavedVariables 結構與主流插件架構協作。
*   **EAM_Lua_VM_Expert (Lua 虛擬機與編譯優化專家)**
    *   **職責**：專注 0-GC 演算、閉包優化、記憶體管理、本地 Inline pcall 匿名閉包開銷與底層元表機制評估。
*   **EAM_Security_Auditor (安全與 Taint 稽核專家)**
    *   **職責**：針對「私有 ScrollingMessageFrame 原生解密法」、「一鍵硬體事件提權巨集」、「官方 UI 數據爬蟲 (UI Scraping)」等高難度繞過漏洞進行生命週期防堵與優化平穩降級稽核。

### 2. 玩家體驗與實戰監控專家
*   **EAM_UX_Gameplay_Expert (玩法與 UX 體驗專家)**
    *   **職責**：熟悉 12.x 各職業機制、Pandemic 刷新點提示、DOT/BUFF 監視、視覺疲勞優化與戰鬥場景動態載入避讓。
*   **EAM_Class_Expert (職業專精智囊代表)**
    *   **職責**：代表 13 個職業、39 個專精進行實戰監控配置與優化，提供 30% Pandemic 臨界秒數與資源防溢出閾值。
*   **EAM_Class_Tanks (坦克專精智囊團)**
    *   **職責**：代表血DK、復仇DH、防騎、防戰、酒僧、熊德 6 大坦克，針對主動減傷、生存 Buff 與 Boss 尖峰傷害減傷預警給予配置建議。
*   **EAM_Class_Healers (治療專精智囊團)**
    *   **職責**：代表補德、神/戒牧、補僧、補薩、補騎、恩補喚能師 6 大治療，針對多目標 HoT 覆蓋、隨機觸發 Procs 與團隊框架藍耗提供實戰建議。
*   **EAM_Class_Melee (近戰 DPS 專精智囊團)**
    *   **職責**：代表賊、戰、DH、聖騎、DK、武僧、增強薩、貓德，針對能量/符文連續資源節奏與 DOT 流血的 Pandemic 刷新提供建議。
*   **EAM_Class_Ranged (遠程 DPS 專精智囊團)**
    *   **職責**：代表法、術、暗牧、鳥德、元素薩、獵、喚能師，針對多目標 DoT 維持、Procs 瞬發置頂與移動可用技能引導提供建議。
*   **EAM_Tank_Pro (頂尖坦克玩家代表)**、**EAM_Healer_Pro (頂尖治療玩家代表)**、**EAM_Melee_DPS_Pro (近戰輸出玩家代表)**、**EAM_Ranged_DPS_Pro (遠程輸出玩家代表)**
    *   **職責**：分別代表各個職能，以高玩實戰視角為 EAM 提供極限狀態監控與視覺優先級建議。
