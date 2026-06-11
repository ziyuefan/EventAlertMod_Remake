# EventAlertMod 品質管制與要因分析指引 (QC & Root Cause Analysis Guide)

少年欸！為確保 EAM 在重構與日後開發中的程式碼品質，避免在同一個 Bug 上反覆栽跟頭，本文件正式將企業管理學的品質管制（TQM）、新 QC 七大手法、5 Whys（WHY-WHY 分析）、魚骨圖要因分析、對策矩陣評估與甘特圖時程相依精神，全面導入 EAM 的開發與 Bug 診斷流程中。

後續所有 subagent 進行問題排查、方案設計（Implementation Plan）與 PR 審查，均須遵循此 QC 指引。

---

## 1. 5 Whys (WHY-WHY 要因分析) 實施規範

當 EAM 出現任何 Bug、Taint 阻斷或 Lua 報錯時，主代理與 subagent 不得直接嘗試修改程式碼，必須先在 `Docs/15_DEVELOPMENT_ISSUE_LOG.md` 紀錄中進行 **5 Whys 分析**，連續追問 5 次「為什麼」，直到找出根本原因（Root Cause）。

### 範例：戰鬥中 IsZero() 布林判定崩潰分析
*   **Why 1 (一問)**：為什麼 OnUpdate 執行時插件崩潰並阻斷 UI？
    *   *答*：因為在 `Renderer.lua:97` 對 `durationObj:IsZero()` 的傳回值進行了直接布林判斷（`if durationObj:IsZero() then`）。
*   **Why 2 (二問)**：為什麼 `IsZero()` 會引發崩潰？
    *   *答*：因為該 `DurationObject` 代表的光環在戰鬥中受到 Secrecy 限制，其 `IsZero()` 方法返回的是一個受保護的 `Secret Boolean`。
*   **Why 3 (三問)**：為什麼受保護的 `Secret Boolean` 不能做布林判斷？
    *   *答*：因為魔獸世界 12.x 引擎為了防止 AddOn 藉由 API 判定來輔助戰鬥決策，嚴禁在 Lua 中對 Secret Boolean 執行布林跳轉指令（Boolean Test）。
*   **Why 4 (四問)**：為什麼我們非得要在 OnUpdate 中呼叫 `IsZero()`？
    *   *答*：因為戰鬥中 `UNIT_AURA` 事件會被官方節流，且 Secret 狀態下我們無法取得剩餘時間以預排 Scheduler，必須在 Renderer 輪詢該 Predicate 以便在光環消失時主動回收 Icon。
*   **Why 5 (五問/根本原因)**：為什麼之前沒有防護？
    *   *答*：因為 Renderer 缺乏對 Secret Value 的前置檢測與安全包裹，且不知道 `IsZero()` 的傳回值也會是 Secret。
*   **根本對策**：引入 `safeCheckIsZero`，利用 `Util.isSecretValue` 過濾返回值，若為 Secret 則絕不對其進行 Boolean Test。

---

## 2. 魚骨圖 (Ishikawa Diagram) 要因分析模板

在遭遇複雜系統性問題時（例如「一個 ICON 都沒出現」或「高頻戰鬥中 UI 嚴重卡頓」），須使用魚骨圖從以下五個維度進行分析：

```text
  【人 (Agent)】                   【機 (Client/WoW API)】         【料 (SavedVariables/Data)】
  - 載入順序快取 nil 漏配           - 12.x Secrecy 加密與限制       - 舊 SavedVariables 資料遷移失效
  - 靜態變數被提早快取             - 事件節流與 CLEU 事件停用       - 預設 Alerts 表為空 (WTF遺失)
          \                             \                               \
           \                             \                               \
            --------------------------------------------------------------------> [ 系統異常/Bug ]
           /                             /                               /
          /                             /                               /
  - 戰鬥中 layout 頻繁重排         - 戰鬥中 InCombatLockdown 限制
  - 輪詢 pcall 產生 Heap 垃圾       - 脫戰後 defer 釋放機制
  【法 (Algorithm/邏輯)】          【環 (Environment/戰鬥狀態)】
```

*   **人 (Agent / Developer)**：AI 代理的代碼載入順序、快取邏輯、靜態變數使用不當。
*   **機 (Client / WoW API)**：魔獸客戶端 API 的行為變更、加密限制、事件節流。
*   **料 (SavedVariables / Data)**：資料庫 Schema、Defaults 設定檔、本地化字串。
*   **法 (Algorithm / 邏輯流程)**：演算法開銷、迴圈設計、事件訂閱、GC 垃圾產生率。
*   **環 (Environment / 遊戲狀態)**：戰鬥中/非戰鬥中、低 FPS、大數量 Buff 特殊情境。

---

## 3. 對策擬定與評估矩陣 (Countermeasure Matrix)

在 `implementation_plan.md` 中設計複雜方案時，必須提出至少 **兩個候選對策**，並以矩陣圖形式進行量化打分評估（1~5 分，5 分為最優），最終選取綜合得分最高者。

### 範例：解決戰鬥中 Secret 倒數問題的對策評估

| 對策方案 | 效果 (Effectiveness) | 可行性 (Feasibility) | 效能開銷 (Low GC/CPU) | 安全風險 (Low Taint/Secret) | 綜合得分 | 決策 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **對策 A：強行利用 Tooltip Scraping 在每幀 OnUpdate 爬取時間** | 2 | 4 | 1 (頻繁字串 GC) | 2 (極易 tainted) | **9** | 淘汰 |
| **對策 B：使用 Shadow Host 寄生吸附官方 CooldownViewer** | 5 | 3 | 5 (100% 避讓佈局) | 4 (安全隔離) | **17** | **採納 (備用)** |
| **對策 C：AuraService 說明解析 + Renderer 雙軌 IsZero 判定回收** | 5 | 5 | 4 (僅在倒數時輪詢) | 5 (利用 safeCheck 阻斷) | **19** | **首選採納** |

---

## 4. 甘特圖排程與相依性精神 (Gantt Spirit)

在 `task.md` 中，必須體現甘特圖的**相依性（Dependencies）**與**關鍵路徑（Critical Path）**，以防止並行開發的 subagent 發生「因前置代碼未就緒而空轉」或「高耦合代碼衝突」。

### 排程原則：
1.  **Dependency Guard (相依性守衛)**：在 `task.md` 中明確標註前置依賴。例如：
    *   `[ ] 任務 C (AuraService 重構) [依賴：任務 A (EventRouter 改版)]`
2.  **Critical Path First (關鍵路徑優先)**：將決定架構穩定性（如 Core, SavedVariables）的任務排在最前，分配最昂貴的資源與 A 級審查專家。
3.  **Milestone Gate (里程碑關卡)**：每個階段結束時，必須設定 Milestone 進行品質查核（如：`luac -p` 檢查，`/eam doctor` 診斷通過），否則不得進入下一階段。

---

## 5. 新 QC 七大手法在 EAM 的落地

1.  **關係圖法 (Relations Diagram)**：
    *   *應用*：理清 EAM 內部事件（如 `EAM_AURA_STATE_CHANGED`）與原生 WoW 事件（如 `UNIT_AURA`）之間的因果傳播網絡，防止事件風暴與無限遞迴。
2.  **系統圖法 (Systematic Diagram)**：
    *   *應用*：將宏大的重構目標（如 "12.1.0 零分配"）層層分解為子模組變更（AuraService 池化、CooldownService 池化、AlertManager 回收、Renderer 多型渲染）。
3.  **矩陣圖法 (Matrix Diagram)**：
    *   *應用*：即本案已落地的 **[Docs/21_RACI_EXPERTS_MATRIX.md](file:///d:/EventAlertMod/Docs/21_RACI_EXPERTS_MATRIX.md)**，用來理清專家與開發任務的責任對照。
4.  **PDPC 法 (Process Decision Program Chart / 過程決定計劃圖)**：
    *   *應用*：在代碼編寫前，預測所有可能的異常路徑（如：官方 API 返回 nil、資料未快取、戰鬥中 restricted 限制），並在程式碼中預先布置 `pcall` 故障隔離、`safeCheckIsZero` 與 `Util.isSecretValue` 等 fallback 備援對策。
5.  **箭條圖法 (Arrow Diagram)**：
    *   *應用*：理清 subagent 的並行工作順序，避免多個代理同時寫入同一個檔案，確保版本分支的平滑合併。
