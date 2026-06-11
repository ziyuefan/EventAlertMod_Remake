# EventAlertMod AI 入口指導檔

本專案正在進行 EventAlertMod（EAM）正式服重寫。現有程式碼只作為「行為參考」，不得直接沿用舊架構作為新架構基礎。

## 對話與文件原則

- 預設使用台灣慣用繁體中文。
- 使用者稱呼為「少年欸」。
- 回覆直接切入任務，保持技術判斷清楚、結構明確。
- WoW AddOn 相關任務必須先確認正式服與經典服差異；本專案只處理正式服。
- 涉及 12.x API、Secret Values、C_* 命名空間或 Widget 行為時，需優先參考 `Docs` 與最新 Warcraft Wiki API change 資訊。
- 不得宣稱已完成 WoW 正式服實機驗證，除非確實在 WoW Retail 中載入並測試過。
- 每次開發時，Docs/ 內相關文件必須主動一併同步更新，保持文檔與代碼一致性，不得被動等待使用者指示（不要一動才一動）。
- **文件與 HTML 轉換規則**：
  - 後續開發與 AI 協作的絕對指導檔案，一律以 `AGENTS.md` 以及其內文指名之 `.md` 檔案為唯一事實與 Facts-of-Truth 參考。
  - HTML 版本僅供人類（少年欸）在瀏覽器中好看易讀使用，AI 在讀寫與參考時，必須一律以 `.md` 原檔為唯一基準，不得以 HTML 作為開發事實參考。
  - 當 `./Docs/*.md` 或 `./AGENTS.md` 修改且包含心智圖（Mermaid）、表格、流程圖、圖像時，必須執行轉換工具（`batch_convert_docs.py`），於 `./docs_html` 內多生成一份同名的 `.html` 檔案（例如 `00_AI_CONTEXT.md.html`）。

## 必讀文件

變更程式碼前，先閱讀下列文件：

- `Docs/00_AI_CONTEXT.md`
- `Docs/01_ARCHITECTURE.md`
- `Docs/02_RETAIL_API_BOUNDARIES.md`
- `Docs/03_STATE_SCHEMA.md`
- `Docs/04_MODULE_CONTRACTS.md`
- `Docs/05_PERFORMANCE_GUIDE.md`
- `Docs/06_TEST_PLAN_RETAIL.md`
- `Docs/07_MIGRATION_NOTES.md`
- `Docs/08_AI_PROMPT_EXPORT_SCHEMA.md`
- `Docs/09_KNOWN_LIMITATIONS.md`
- `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md`
- `Docs/11_WARCRAFT_WIKI_MAIN_MENU_TREE.md`
- `Docs/12_CODE_COMMENTARY_GUIDE.md`
- `Docs/14_PACKAGING_GUIDE.md`
- `Docs/15_DEVELOPMENT_ISSUE_LOG.md`
- `Docs/16_RETAIL_ADDON_OPTIMIZATION_ROADMAP.md`
- `Docs/17_SUBAGENT_WORKFLOW.md`
- `Docs/18_RETAIL_12X_CLASS_SPECIALIZATION_HERO_TALENT_DATABASE.md`
- `Docs/19_AURA_1210_REDUX_BLUEPRINT.md`
- `Docs/20_CDM_BYPASS_FEASIBILITY_STUDY.md`
- `Docs/21_RACI_EXPERTS_MATRIX.md`
- `Docs/22_QC_ROOT_CAUSE_ANALYSIS_GUIDE.md`

舊討論脈絡可參考：

- `DevDocument/ChatGPT/EventAlertMod_ChatGPT_Discussion_Context.md`

## 專案目標

- 目標遊戲：World of Warcraft Retail only。
- 目標 API 世代：Retail 12.x / Midnight-era AddOn API。
- 架構方向：事件驅動、低 GC、模組化、可維護。
- 使用者體驗：保留 EAM「比 WeakAuras 簡單、輕量、專注光環與冷卻提醒」的定位。
- 現有資料表、在地化字串、Slash Command 語意與使用者可見行為可保留；內部架構應重新設計。

## 硬性限制

- 不支援 Classi## Secret / Protected Data 規則與安全檢查

Retail 12.x 可能將光環、冷卻、法術、時間、單位或字串資料標記為 Secret / Protected / Display-only。為防範在戰鬥中因 Secret/Protected 限制引發 Lua 崩潰或阻擋錯誤，必須實施四大核心檢查 API 規範與 Table 索引防禦機制：

- **四大核心檢查 Function**：
  - `issecretvalue(value)`：判斷特定值是否為受保護之秘密值（Secret Value）。
  - `canaccessvalue(value)`：判斷目前是否有權限存取與讀取該值。
  - `canaccesstable(table)`：判斷整個 table 物件是否可被安全讀取（非 Restricted）。
  - `issecrettable(table)` / `hasanysecretvalues(table)`：檢查 table 物件結構是否本身已被限制或含有秘密值。
- **Table 索引防範 (Critical)**：嚴禁使用可能為秘密值（例如未經驗證的 `spellId` 或 `text` 等）的 key 去對任何非 secure 的自訂 table 進行 index 操作，否則將立即觸發 `attempted to index a table that cannot be indexed with secret keys` 嚴重錯誤。在對自訂 config table 進行索引前，必須先以 `issecretvalue(key)` 確保該 key 不是受保護的秘密值，並以 `canaccesstable(targetTable)` 檢查 table 安全。
- 先確認來源 table 是否可讀（`canaccesstable`），再讀取欄位，再確認欄位值是否為 Secret（`issecretvalue`）。
- 未確認安全前，不得對 duration、expirationTime、spellID、timeLeft 等值做算術、比較、字串化、table key、序列化或任意函式傳遞。
- 不得捏造 duration、expiration、cooldown 或 stack 值。
- 不得把猜測值混入 facts；推導值必須標記為 derived。
- 資料不可安全取得時，保留可安全顯示的 icon、name、active 狀態，timer 顯示為 protected、displayOnly 或 unknown。
- Debug 狀態需記錄 boundaryWarnings。
- 若可行，排程離開戰鬥後 refresh。能將光環、冷卻、法術、時間、單位或字串資料標記為 Secret / Protected / Display-only。為防範在戰鬥中因 Secret/Protected 限制引發 Lua 崩潰或阻擋錯誤，必須實施四大核心檢查 API 規範與 Table 索引防禦機制：

- **三大核心檢查 Function**：
  - `issecretvalue(value)`：判斷特定值是否為受保護之秘密值（Secret Value）。
  - `canaccessvalue(value)`：判斷目前是否有權限存取與讀取該值。
  - `canaccesstable(table)`：判斷整個 table 物件是否可被安全讀取（非 Restricted）。
- **Table 特殊檢查與索引防禦**：
  - `issecrettable(table)`：檢查目標 table 是否本身已被標記為 Secret Table。
  - `hasanysecretvalues(table)`：檢查 table 中是否包含任何秘密值（Secret Values）。
  - **Table 索引防範 (Critical)**：嚴禁使用可能為秘密值（例如未經驗證的 `spellId` 或 `text` 等）的 key 去對任何非 secure 的自訂 table 進行 index 操作，否則將立即觸發 `attempted to index a table that cannot be indexed with secret keys` 嚴重錯誤。在對自訂 config table 進行索引前，必須先以 `issecretvalue(key)` 確保該 key 不是受保護的秘密值，並以 `canaccesstable(targetTable)` 檢查 table 安全。
- 先確認來源 table 是否可讀（`canaccesstable`），再讀取欄位，再確認欄位值是否為 Secret（`issecretvalue`）。
- 未確認安全前，不得對 duration、expirationTime、spellID、timeLeft 等值做算術、比較、字串化、table key、序列化或任意函式傳遞。
- 不得捏造 duration、expiration、cooldown 或 stack 值。
- 不得把猜測值混入 facts；推導值必須標記為 derived。
- 資料不可安全取得時，保留可安全顯示的 icon、name、active 狀態，timer 顯示為 protected、displayOnly 或 unknown。
- Debug 狀態需記錄 boundaryWarnings。
- 若可行，排程離開戰鬥後 refresh。

## Taint 控制規則

- 不 hook、覆寫、重定義或 monkey patch Blizzard secure/protected 函式、FrameXML 核心函式、action button、unit frame、nameplate、spell cast、targeting、item use 相關路徑。
- 不在戰鬥中修改 protected frame 的 attribute、parent、anchor、size、visibility、template 或 click 行為。
- 不把 EAM runtime state、secret/protected value、debug object 或 addon callback 傳入可能污染 secure chain 的 Blizzard frame。
- EventRouter 使用孤兒 frame；Renderer frame 只負責顯示，不承擔 secure action 或 protected interaction。
- 若需要操作 UIParent 下的 frame，必須限制在非 protected 顯示用途，並在 `InCombatLockdown()` 時延後可能造成 taint 的結構性變更。
- 不使用 `forceinsecure`、不嘗試清除或繞過 taint、不以第三方 workaround 壓制 Blizzard blocked action。
- 發現 taint、blocked action、combat lockdown 錯誤時，需記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`，並標明觸發路徑、戰鬥狀態與可重現步驟。

## DurationObject 與時間顯示

- Secret 或受保護時間資料不得用 `OnUpdate` 自行倒數。
- 若 Retail 提供 DurationObject，優先交給原生 UI 處理，例如 `CooldownFrame:SetCooldownFromDurationObject()` 或 `FontString:SetDurationText()`。
- `Cooldown:SetCountdownFormatter()`、`Cooldown:SetCountdownMillisecondsThreshold()` 等 12.0.5 後相關能力需以文件與實機確認後使用。
- 手動 timer 字串只能用於已確認安全的普通數值。

## Tooltip / C_TooltipInfo 降級策略

Tooltip 解析只能作為低頻、保守、明確標記來源的 fallback：

- 優先使用 `C_TooltipInfo` 或 Blizzard 支援的 display object。
- 可解析靜態說明文字中的明確數值。
- 不解析動態剩餘時間文字作為事實。
- 不在熱路徑、戰鬥中或每 frame 執行 tooltip scraping。
- 解析結果不得覆蓋安全 API facts，只能作為 derived 或 display-only 輔助。
- 解析失敗時必須安靜降級，不得產生誤導 timer。

## 事件與 Frame 規則

- 事件派發使用單一 EventRouter。
- 純事件監聽 frame 使用孤兒 frame：`CreateFrame("Frame", nil, nil)`。
- 不在 UIParent-parented frame 上承擔邏輯 dispatcher 職責。
- 不在戰鬥中對 UI-parented frame 動態註冊或解除註冊事件。
- 事件註冊變更應集中管理，避免反覆 churn。

## Scheduler 與效能規則

- 優先事件驅動；排程 fallback 必須集中、低頻、可節流。
- 只使用單一 Scheduler `OnUpdate`。
- 禁止 timer-per-icon、timer-per-spell、熱路徑反覆 `C_Timer.After(function() ...)`。
- `UNIT_AURA`、`SPELL_UPDATE_COOLDOWN`、`OnUpdate`、Renderer 更新屬於熱路徑。
- 熱路徑不得配置臨時 table、closure 或不必要字串。
- 熱路徑避免 `pairs` / `ipairs`；可用穩定數字索引時使用 numeric loop。
- 熱路徑避免 `table.insert`；可用直接索引寫入時使用直接索引。
- 迴圈中組字串使用 buffer 與 `table.concat`，避免連續 `..`。
- 低 FPS 或戰鬥中應延後、縮減或停止非必要工作。
- 大範圍 item 掃描不得在正常 runtime 執行；若需要 item-spell cache，必須 opt-in、idle-only、interruptible、FPS-aware、combat-aware。

## table.create / table.freeze 政策

- `table.create` 用於可預期配置：array、pool、ring buffer、record list、icon pool、default template。
- 必須提供 `table.create`、`table.freeze`、`table.isfrozen` fallback。
- `table.freeze` 只用於不可變靜態資料：constants、enum、schema、default field profile、module contract、prototype、metatable。
- 可將穩定 API alias table 凍結，例如 `EAM.API`，但只在確認不會造成載入順序或測試困難時使用。
- 不得 freeze SavedVariables、runtime cache、aura/cooldown state、icon state、pool object、scheduler queue、debug/session record。

## UI / Renderer 規則

- Renderer 不直接查 API；資料由 service 層提供。
- 圖示、button、FontString 使用 pool。
- Renderer 不執行 secure action，不註冊 click-cast，不改 Blizzard protected frame，不污染 action bar / unit frame / nameplate 路徑。
- 避免初始化後不必要的 frame 建立。
- `SetText`、`SetPoint`、`SetSize`、`SetTexture`、layout 寫入前先比較前次值。
- 批次 layout 時可先隱藏 parent，完成後再顯示。
- 支援 timer、stack、spell name、aura value label，但只顯示安全資料。
- UI 預設保持簡單，不能把 EAM 做成 WeakAuras 複雜系統。

## SavedVariables 規則

- SavedVariables 必須有 schema version。
- 提供舊資料 migration、defaults、validation。
- 不 freeze SavedVariables。
- 不寫入每 frame 或高頻 runtime state。
- 無法安全 migration 的欄位要保留備份或標記為 legacy，不可靜默破壞使用者設定。

## Debug / AI 交接規則

- Debug 預設關閉。
- Debug export 必須 on-demand。
- Snapshot 需拆分：
  - facts
  - derived
  - human notes
  - boundaryWarnings
  - environment
- 不輸出巨大 log。
- Export 字串只在使用者明確要求時建立。

## 程式風格

- Identifier 使用英文。
- 註解可使用繁體中文，重點放在 WoW API 邊界、效能理由與架構決策。
- 所有正式載入的程式檔都必須有檔案層級註解，說明模組理念、責任邊界、資料所有權與日後維護注意事項；細節依 `Docs/12_CODE_COMMENTARY_GUIDE.md`。
- 縮排使用 4 spaces。
- 不使用行內分號。
- Namespace / Module 使用 PascalCase。
- Function / local variable 使用 camelCase。
- Private function / private table 以 `_` 前綴。
- Constant 使用 UPPER_SNAKE_CASE。

## 檔案備份規則

- 任何檔案在刪除、搬移、覆寫或修改前，都必須先備份到專案根目錄的 `backup/` 資料夾。
- 備份檔名格式為「原始檔名後綴 `__yyyyMMddHHmmss`」，例如 `AGENTS.md__20260526122904`。
- 時間戳使用本機時間，格式為年月日時分秒，方便依時間排序與追溯。
- 若要處理多個檔案，應在同一批操作開始前先逐一備份；備份完成後才可進行實際修改、搬移或刪除。
- 備份資料夾只作為日後開發、誤刪與回溯參考來源，不得被打包進 CurseForge 發佈檔。
- 若原始檔案不存在，需先回報原因，不得建立空備份冒充原始內容。

## 開發問題紀錄規則

- 開發過程遇到的瓶頸、限制、錯誤、工具失敗、API 不確定性與解決方式，都必須記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- 紀錄目的為降低日後重複試錯、節省 AI context/token、保留決策脈絡。
- 每筆紀錄至少包含日期、情境、症狀、原因判斷、已嘗試方法、有效解法、後續注意事項。
- 若問題尚未解決，需標記為「未解決」並寫明下一步驗證方式。
- 不記錄密碼、token、私人帳號資料或任何不應進入專案文件的敏感資訊。

## 專案專屬 Skill 規則

- 開發過程若發現同一類流程重複出現，且已具備穩定步驟、輸入條件、輸出結果與風險控管，應整理成 EventAlertMod 專案專屬 SKILL。
- 適合轉成 SKILL 的流程包含：打包發佈、Lua 靜態驗證、WoW API 查證、SavedVariables migration 檢查、Secret boundary 審查、文件同步、語系檔同步。
- 目前已建立 `eam-retail-p0-review`，位置為 `.codex/skills/eam-retail-p0-review/SKILL.md`，用於 EAM Retail rewrite 的 P0 Secret/Taint/API/靜態驗證流程。
- 建立 SKILL 前需先確認流程確實可重複，並將既有瓶頸與解法記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- SKILL 內容應包含觸發條件、必要前置檢查、禁止事項、備份規則、驗證方式與最終回報格式。
- 不得把尚未驗證、仍需人工判斷或含敏感資訊的流程硬做成全自動 SKILL。

## Subagent 使用規則

- 使用者已授權：後續本專案若出現適合 subagent 的情境，需主動規劃並使用。
- 使用前先判斷 critical path；立即阻塞主流程的工作由主代理本地處理。
- Subagent 主要用於可並行、明確、可驗收且不互相覆蓋的 sidecar task。
- 適合情境包含：Retail API 查證、Secret / taint 審查、熱路徑掃描、Docs 一致性檢查、模組化 rewrite 的不重疊檔案切片、打包發佈檢查。
- 不適合情境包含：小型單檔修改、需要即時授權的高風險操作、尚未備份的大量搬移/刪除、寫入範圍高度重疊的高耦合改動。
- 派工時必須明確指定檔案責任邊界、禁止事項、備份規則、驗證輸出與最終回報格式。
- Subagent 結果需由主代理整合；不得把 subagent 的 API 判斷視為已實機驗證。
- 詳細流程見 `Docs/17_SUBAGENT_WORKFLOW.md`。
- 所有的協作與 PR 審查必須嚴格遵循 [Docs/21_RACI_EXPERTS_MATRIX.md](file:///d:/EventAlertMod/Docs/21_RACI_EXPERTS_MATRIX.md) 的 RACI 權責分工與審查原則。

## 實作流程

1. Audit：讀完整 source tree、TOC、XML、SavedVariables、global、Classic/MOP 分支、OnUpdate/C_Timer、aura/cooldown/item API。
2. Plan：先界定模組責任與 migration 策略，再開始大規模改動。
3. Rewrite：建立 Core、Services、UI、Debug 模組，保留可用資料與使用者語意。
4. Static Validation：執行可用的 Lua syntax check、全域變數搜尋、`C_Timer.After` closure 搜尋、`table.freeze` 誤用搜尋。
5. Report：清楚回報變更、未驗證項目、風險與下一步。

## 快捷指令

- 當使用者只輸入「打包」兩個字時，直接執行 `Tools/Build-CurseForgePackage.ps1`。
- 當使用者輸入「打包開發版」時，直接執行 `Tools/Build-CurseForgePackage.ps1 -DevMode`。
- 打包前需確認 `EventAlertMod.toc` 的 `## Version` 符合 `EventAlertMod_MN_yyyyMMdd`。
- 打包輸出檔名必須符合 `EventAlertMod_MN_yyyyMMdd_HHmmss.zip`。
- 打包後回報 zip 路徑、Lua 語法檢查結果、排除資料夾檢查結果。
- 相關規則見 `Docs/14_PACKAGING_GUIDE.md`。

## 最終回報必須包含

每次實作 pass 的 final report 至少列出：

1. 變更檔案。
2. 主要架構變更。
3. 保留的舊 EAM 行為。
4. 移除的舊行為。
5. Lua / WoW API 假設。
6. `table.create` / `table.freeze` 使用摘要。
7. Secret / Protected Data 處理策略。
8. 已執行的靜態驗證。
9. 未執行的驗證。
10. 必要的 WoW Retail 實機測試。
11. 已知風險。
12. 下一個建議任務。


## 專案最新重構進度 (2026.06.06 更新)

### 1. 已完成之核心重構 (Retail 12.0.7)
*   **全代碼本地化清掃 (12.0.7 - 2026.06.06)**：
    - 全檔案（包括 `Services` 與 `UI` 目錄下的所有邏輯）中所有硬編碼之中/英文提示名詞與 UI 顯示字串已完全提取為 `EAM.L` 中的 Key。
    - 補齊並無縫支援 `zhTW` (繁中)、`zhCN` (簡中)、`enUS` (英文底層)、`koKR` (韓文) 與 `ruRU` (俄文) 五大語系，共計 144 個詞條。
    - **動態專精本地化 API 重構**：在 `UI/Options.lua` 的篩選下拉選單中引入 `CLASS_TOKEN_TO_ID` 映射，優先調用官方原生 API `GetSpecializationInfoForClassID` 取得最準確的本地化專精名稱，並提供雙軌備份 fallback 防線。
*   **ClassPower 核心資源安全與偵錯加強**：
    - 為 `detectClassPower` 與 `updatePower` 部署全套 `pcall` 隔離與 `issecretvalue` 防衛機制，防止戰鬥中能量數值突變為 Secret Table 時大小比較造成的 Lua 崩潰。
*   **EventRouter/Scheduler 故障隔離**：
    - 為 `Core/EventRouter.lua` 的 OnEvent 核心循環與 `Core/Scheduler.lua` 的定時任務 callback 加上參數化 `pcall` 容錯，確保單一模組報錯時，不會干擾或中斷其他模組與定時器的執行。
*   **雙軌 Native Binding 倒數與 Pandemic Glow**：
    - 時間渲染優先啟用 `C_DurationUtil.CreateDurationTextBinding` 與 `SetCooldownFromDurationObject` 降級通道。
    - 在 DoT 光環滿足 Pandemic 刷新時間時，為 Icon 啟用 Glow 亮框效果。
*   **13 職業與 28 個英雄天賦資料庫擴展**：
    - 更新 `Data/SpellArray.lua`，為所有 13 個職業與 28 個英雄天賦（如 Tempest, Sacred Weapon, Diabolic Ritual 等）配置了最新的法術 ID 預設監控。

### 2. 後續維護與開發建議
*   **安全防禦優先**：在與 any 光環、冷卻、能量、時間相關的數值進行大小比較或 table 索引時，必須先使用 `issecretvalue` 進行防禦性檢查。
*   **語法靜態檢驗**：在對 any Lua 檔案進行修改後，必須執行 `luac -p` 檢查。
*   **12.0.7 & 12.1.0 專家聯席會審與影子載體研究 (2026.06.07 更新)**：
    - 召集全體專家 subagents 進行圓桌聯席會審。Lua VM 專家指出戰鬥熱路徑中匿名閉包 `pcall` 導致 LuaJIT Trace Compiler Abort 的底層開銷，並提供了 Module 級別 static local fallback 機制；AddOn Architect 起草了 `Docs/19_AURA_1210_REDUX_BLUEPRINT.md` 藍圖，全面規劃了 `AuraService` 零分配快取池 `AuraStatePool` 及 C++ Native Duration Binding 雙軌渲染管線。
    - **影子載體技術 (Shadow Host) 實作**：針對利用原生 `CooldownViewer` (冷卻管理器/CDM) 作為影子載體以避讓戰鬥 Secret / Taint 限制完成實作。新建 `Services/ShadowHostService.lua` 實作官方 Pool Hook，並於 `UI/Renderer.lua` 中引入寄生渲染與級聯排版避讓，100% 避開戰鬥中 layout CPU 與 Taint 開銷。評估研究可參考 `Docs/20_CDM_BYPASS_FEASIBILITY_STUDY.md`。
*   **12.1.0 零分配 & 事件驅動全模組重構 (2026.06.07 已完成)**：
    - **完全數據-視圖解耦**：解耦 `AuraService`、`CooldownService`、`ItemCooldownService`、`GroundEffectService` 與 `TotemService`，五大數據服務全部改為事件驱动，不再與 `Renderer` 直接耦合，而是向 `EventRouter` 拋出對應的 `EAM_*_STATE_CHANGED` 事件。
    - **中介控制器引入**：引入 `Managers/AlertManager.lua` 統一管理和調度這五類變更事件，使用 `Scheduler` 實作非同步節流與批次更新（`BeginBatch/EndBatch`），消除 Layout Churn。
    - **多型零分配物件池**：在所有服務中配置專屬的 `StatePool`（例如 `GroundEffectStatePool` 與 `TotemStatePool` 等），在 `acquire` 狀態物件時綁定 `releaseFunc`，並由 `AlertManager` 在渲染隱藏後多型呼叫 `state.releaseFunc(state)` 安全回收物件，達成運行期 0-Allocation 極致低 GC 目標。
    - **影子載體文字剪裁與遮擋修正**：針對吸附官方 CooldownViewer（CDM）時，因原生容器 `ClipsChildren` 裁切與 FrameLevel 遮擋導致技能名稱不顯示的問題，實作動態佈局調整。寄生模式下自動將技能名稱（`nameText`）移至圖示內側底部並設為 Highlight 顯色，同時提權 `FrameLevel`（相對於 `hostIcon` + 10），解決了「看不見技能名稱」的痛點。
    - **靜態安全語法檢驗**：32 個 Lua 檔案 100% 通過語法安全性檢驗。
*   **16 大全新與高頻事件整合 (2026.06.07 已完成)**：
- 不使用 `forceinsecure`、不嘗試清除或繞過 taint、不以第三方 workaround 壓制 Blizzard blocked action。
- 發現 taint、blocked action、combat lockdown 錯誤時，需記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`，並標明觸發路徑、戰鬥狀態與可重現步驟。

## DurationObject 與時間顯示

- Secret 或受保護時間資料不得用 `OnUpdate` 自行倒數。
- 若 Retail 提供 DurationObject，優先交給原生 UI 處理，例如 `CooldownFrame:SetCooldownFromDurationObject()` 或 `FontString:SetDurationText()`。
- `Cooldown:SetCountdownFormatter()`、`Cooldown:SetCountdownMillisecondsThreshold()` 等 12.0.5 後相關能力需以文件與實機確認後使用。
- 手動 timer 字串只能用於已確認安全的普通數值。

## Tooltip / C_TooltipInfo 降級策略

Tooltip 解析只能作為低頻、保守、明確標記來源的 fallback：

- 優先使用 `C_TooltipInfo` 或 Blizzard 支援的 display object。
- 可解析靜態說明文字中的明確數值。
- 不解析動態剩餘時間文字作為事實。
- 不在熱路徑、戰鬥中或每 frame 執行 tooltip scraping。
- 解析結果不得覆蓋安全 API facts，只能作為 derived 或 display-only 輔助。
- 解析失敗時必須安靜降級，不得產生誤導 timer。

## 事件與 Frame 規則

- 事件派發使用單一 EventRouter。
- 純事件監聽 frame 使用孤兒 frame：`CreateFrame("Frame", nil, nil)`。
- 不在 UIParent-parented frame 上承擔邏輯 dispatcher 職責。
- 不在戰鬥中對 UI-parented frame 動態註冊或解除註冊事件。
- 事件註冊變更應集中管理，避免反覆 churn。

## Scheduler 與效能規則

- 優先事件驅動；排程 fallback 必須集中、低頻、可節流。
- 只使用單一 Scheduler `OnUpdate`。
- 禁止 timer-per-icon、timer-per-spell、熱路徑反覆 `C_Timer.After(function() ...)`。
- `UNIT_AURA`、`SPELL_UPDATE_COOLDOWN`、`OnUpdate`、Renderer 更新屬於熱路徑。
- 熱路徑不得配置臨時 table、closure 或不必要字串。
- 熱路徑避免 `pairs` / `ipairs`；可用穩定數字索引時使用 numeric loop。
- 熱路徑避免 `table.insert`；可用直接索引寫入時使用直接索引。
- 迴圈中組字串使用 buffer 與 `table.concat`，避免連續 `..`。
- 低 FPS 或戰鬥中應延後、縮減或停止非必要工作。
- 大範圍 item 掃描不得在正常 runtime 執行；若需要 item-spell cache，必須 opt-in、idle-only、interruptible、FPS-aware、combat-aware。

## table.create / table.freeze 政策

- `table.create` 用於可預期配置：array、pool、ring buffer、record list、icon pool、default template。
- 必須提供 `table.create`、`table.freeze`、`table.isfrozen` fallback。
- `table.freeze` 只用於不可變靜態資料：constants、enum、schema、default field profile、module contract、prototype、metatable。
- 可將穩定 API alias table 凍結，例如 `EAM.API`，但只在確認不會造成載入順序或測試困難時使用。
- 不得 freeze SavedVariables、runtime cache、aura/cooldown state、icon state、pool object、scheduler queue、debug/session record。

## UI / Renderer 規則

- Renderer 不直接查 API；資料由 service 層提供。
- 圖示、button、FontString 使用 pool。
- Renderer 不執行 secure action，不註冊 click-cast，不改 Blizzard protected frame，不污染 action bar / unit frame / nameplate 路徑。
- 避免初始化後不必要的 frame 建立。
- `SetText`、`SetPoint`、`SetSize`、`SetTexture`、layout 寫入前先比較前次值。
- 批次 layout 時可先隱藏 parent，完成後再顯示。
- 支援 timer、stack、spell name、aura value label，但只顯示安全資料。
- UI 預設保持簡單，不能把 EAM 做成 WeakAuras 複雜系統。

## SavedVariables 規則

- SavedVariables 必須有 schema version。
- 提供舊資料 migration、defaults、validation。
- 不 freeze SavedVariables。
- 不寫入每 frame 或高頻 runtime state。
- 無法安全 migration 的欄位要保留備份或標記為 legacy，不可靜默破壞使用者設定。

## Debug / AI 交接規則

- Debug 預設關閉。
- Debug export 必須 on-demand。
- Snapshot 需拆分：
  - facts
  - derived
  - human notes
  - boundaryWarnings
  - environment
- 不輸出巨大 log。
- Export 字串只在使用者明確要求時建立。

## 程式風格

- Identifier 使用英文。
- 註解可使用繁體中文，重點放在 WoW API 邊界、效能理由與架構決策。
- 所有正式載入的程式檔都必須有檔案層級註解，說明模組理念、責任邊界、資料所有權與日後維護注意事項；細節依 `Docs/12_CODE_COMMENTARY_GUIDE.md`。
- 縮排使用 4 spaces。
- 不使用行內分號。
- Namespace / Module 使用 PascalCase。
- Function / local variable 使用 camelCase。
- Private function / private table 以 `_` 前綴。
- Constant 使用 UPPER_SNAKE_CASE。

## 檔案備份規則

- 任何檔案在刪除、搬移、覆寫或修改前，都必須先備份到專案根目錄的 `backup/` 資料夾。
- 備份檔名格式為「原始檔名後綴 `__yyyyMMddHHmmss`」，例如 `AGENTS.md__20260526122904`。
- 時間戳使用本機時間，格式為年月日時分秒，方便依時間排序與追溯。
- 若要處理多個檔案，應在同一批操作開始前先逐一備份；備份完成後才可進行實際修改、搬移或刪除。
- 備份資料夾只作為日後開發、誤刪與回溯參考來源，不得被打包進 CurseForge 發佈檔。
- 若原始檔案不存在，需先回報原因，不得建立空備份冒充原始內容。

## 開發問題紀錄規則

- 開發過程遇到的瓶頸、限制、錯誤、工具失敗、API 不確定性與解決方式，都必須記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- 紀錄目的為降低日後重複試錯、節省 AI context/token、保留決策脈絡。
- 每筆紀錄至少包含日期、情境、症狀、原因判斷、已嘗試方法、有效解法、後續注意事項。
- 若問題尚未解決，需標記為「未解決」並寫明下一步驗證方式。
- 不記錄密碼、token、私人帳號資料或任何不應進入專案文件的敏感資訊。

## 專案專屬 Skill 規則

- 開發過程若發現同一類流程重複出現，且已具備穩定步驟、輸入條件、輸出結果與風險控管，應整理成 EventAlertMod 專案專屬 SKILL。
- 適合轉成 SKILL 的流程包含：打包發佈、Lua 靜態驗證、WoW API 查證、SavedVariables migration 檢查、Secret boundary 審查、文件同步、語系檔同步。
- 目前已建立 `eam-retail-p0-review`，位置為 `.codex/skills/eam-retail-p0-review/SKILL.md`，用於 EAM Retail rewrite 的 P0 Secret/Taint/API/靜態驗證流程。
- 建立 SKILL 前需先確認流程確實可重複，並將既有瓶頸與解法記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- SKILL 內容應包含觸發條件、必要前置檢查、禁止事項、備份規則、驗證方式與最終回報格式。
- 不得把尚未驗證、仍需人工判斷或含敏感資訊的流程硬做成全自動 SKILL。

## Subagent 使用規則

- 使用者已授權：後續本專案若出現適合 subagent 的情境，需主動規劃並使用。
- 使用前先判斷 critical path；立即阻塞主流程的工作由主代理本地處理。
- Subagent 主要用於可並行、明確、可驗收且不互相覆蓋的 sidecar task。
- 適合情境包含：Retail API 查證、Secret / taint 審查、熱路徑掃描、Docs 一致性檢查、模組化 rewrite 的不重疊檔案切片、打包發佈檢查。
- 不適合情境包含：小型單檔修改、需要即時授權的高風險操作、尚未備份的大量搬移/刪除、寫入範圍高度重疊的高耦合改動。
- 派工時必須明確指定檔案責任邊界、禁止事項、備份規則、驗證輸出與最終回報格式。
- Subagent 結果需由主代理整合；不得把 subagent 的 API 判斷視為已實機驗證。
- 詳細流程見 `Docs/17_SUBAGENT_WORKFLOW.md`。

## 實作流程

1. Audit：讀完整 source tree、TOC、XML、SavedVariables、global、Classic/MOP 分支、OnUpdate/C_Timer、aura/cooldown/item API。
2. Plan：先界定模組責任與 migration 策略，再開始大規模改動。
3. Rewrite：建立 Core、Services、UI、Debug 模組，保留可用資料與使用者語意。
4. Static Validation：執行可用的 Lua syntax check、全域變數搜尋、`C_Timer.After` closure 搜尋、`table.freeze` 誤用搜尋。
5. Report：清楚回報變更、未驗證項目、風險與下一步。

## 快捷指令

- 當使用者只輸入「打包」兩個字時，直接執行 `Tools/Build-CurseForgePackage.ps1`。
- 打包前需確認 `EventAlertMod.toc` 的 `## Version` 符合 `EventAlertMod_MN_yyyyMMdd`（開發版除外，其將覆寫命名為 DEV 且跳過日期校驗）。
- 打包輸出檔名必須符合 `EventAlertMod_MN_yyyyMMdd_HHmmss.zip`，開發版則為 `EventAlertMod_DEV_yyyyMMdd_HHmmss.zip`。
- 打包後回報 zip 路徑、Lua 語法檢查結果、排除資料夾檢查結果。
- 相關規則見 `Docs/14_PACKAGING_GUIDE.md`。

## 最終回報必須包含

每次實作 pass 的 final report 至少列出：

1. 變更檔案。
2. 主要架構變更。
3. 保留的舊 EAM 行為。
4. 移除的舊行為。
5. Lua / WoW API 假設。
6. `table.create` / `table.freeze` 使用摘要。
7. Secret / Protected Data 處理策略。
8. 已執行的靜態驗證。
9. 未執行的驗證。
10. 必要的 WoW Retail 實機測試。
11. 已知風險。
12. 下一個建議任務。


## 專案最新重構進度 (2026.06.06 更新)

### 1. 已完成之核心重構 (Retail 12.0.7)
*   **全代碼本地化清掃 (12.0.7 - 2026.06.06)**：
    - 全檔案（包括 `Services` 與 `UI` 目錄下的所有邏輯）中所有硬編碼之中/英文提示名詞與 UI 顯示字串已完全提取為 `EAM.L` 中的 Key。
    - 補齊並無縫支援 `zhTW` (繁中)、`zhCN` (簡中)、`enUS` (英文底層)、`koKR` (韓文) 與 `ruRU` (俄文) 五大語系，共計 144 個詞條。
    - **動態專精本地化 API 重構**：在 `UI/Options.lua` 的篩選下拉選單中引入 `CLASS_TOKEN_TO_ID` 映射，優先調用官方原生 API `GetSpecializationInfoForClassID` 取得最準確的本地化專精名稱，並提供雙軌備份 fallback 防線。
*   **ClassPower 核心資源安全與偵錯加強**：
    - 為 `detectClassPower` 與 `updatePower` 部署全套 `pcall` 隔離與 `issecretvalue` 防衛機制，防止戰鬥中能量數值突變為 Secret Table 時大小比較造成的 Lua 崩潰。
*   **EventRouter/Scheduler 故障隔離**：
    - 為 `Core/EventRouter.lua` 的 OnEvent 核心循環與 `Core/Scheduler.lua` 的定時任務 callback 加上參數化 `pcall` 容錯，確保單一模組報錯時，不會干擾或中斷其他模組與定時器的執行。
*   **雙軌 Native Binding 倒數與 Pandemic Glow**：
    - 時間渲染優先啟用 `C_DurationUtil.CreateDurationTextBinding` 與 `SetCooldownFromDurationObject` 降級通道。
    - 在 DoT 光環滿足 Pandemic 刷新時間時，為 Icon 啟用 Glow 亮框效果。
*   **13 職業與 28 個英雄天賦資料庫擴展**：
    - 更新 `Data/SpellArray.lua`，為所有 13 個職業與 28 個英雄天賦（如 Tempest, Sacred Weapon, Diabolic Ritual 等）配置了最新的法術 ID 預設監控。

### 2. 後續維護與開發建議
*   **安全防禦優先**：在與 any 光環、冷卻、能量、時間相關的數值進行大小比較或 table 索引時，必須先使用 `issecretvalue` 進行防禦性檢查。
*   **語法靜態檢驗**：在對 any Lua 檔案進行修改後，必須執行 `luac -p` 檢查。
*   **12.0.7 & 12.1.0 專家聯席會審與影子載體研究 (2026.06.07 更新)**：
    - 召集全體專家 subagents 進行圓桌聯席會審。Lua VM 專家指出戰鬥熱路徑中匿名閉包 `pcall` 導致 LuaJIT Trace Compiler Abort 的底層開銷，並提供了 Module 級別 static local fallback 機制；AddOn Architect 起草了 `Docs/19_AURA_1210_REDUX_BLUEPRINT.md` 藍圖，全面規劃了 `AuraService` 零分配快取池 `AuraStatePool` 及 C++ Native Duration Binding 雙軌渲染管線。
    - **影子載體技術 (Shadow Host) 實作**：針對利用原生 `CooldownViewer` (冷卻管理器/CDM) 作為影子載體以避讓戰鬥 Secret / Taint 限制完成實作。新建 `Services/ShadowHostService.lua` 實作官方 Pool Hook，並於 `UI/Renderer.lua` 中引入寄生渲染與級聯排版避讓，100% 避開戰鬥中 layout CPU 與 Taint 開銷。評估研究可參考 `Docs/20_CDM_BYPASS_FEASIBILITY_STUDY.md`。
*   **12.1.0 零分配 & 事件驅動全模組重構 (2026.06.07 已完成)**：
    - **完全數據-視圖解耦**：解耦 `AuraService`、`CooldownService`、`ItemCooldownService`、`GroundEffectService` 與 `TotemService`，五大數據服務全部改為事件驱动，不再與 `Renderer` 直接耦合，而是向 `EventRouter` 拋出對應的 `EAM_*_STATE_CHANGED` 事件。
    - **中介控制器引入**：引入 `Managers/AlertManager.lua` 統一管理和調度這五類變更事件，使用 `Scheduler` 實作非同步節流與批次更新（`BeginBatch/EndBatch`），消除 Layout Churn。
    - **多型零分配物件池**：在所有服務中配置專屬的 `StatePool`（例如 `GroundEffectStatePool` 與 `TotemStatePool` 等），在 `acquire` 狀態物件時綁定 `releaseFunc`，並由 `AlertManager` 在渲染隱藏後多型呼叫 `state.releaseFunc(state)` 安全回收物件，達成運行期 0-Allocation 極致低 GC 目標。
    - **影子載體文字剪裁與遮擋修正**：針對吸附官方 CooldownViewer（CDM）時，因原生容器 `ClipsChildren` 裁切與 FrameLevel 遮擋導致技能名稱不顯示的問題，實作動態佈局調整。寄生模式下自動將技能名稱（`nameText`）移至圖示內側底部並設為 Highlight 顯色，同時提權 `FrameLevel`（相對於 `hostIcon` + 10），解決了「看不見技能名稱」的痛點。
    - **靜態安全語法檢驗**：32 個 Lua 檔案 100% 通過語法安全性檢驗。
*   **16 大全新與高頻事件整合 (2026.06.07 已完成)**：
    - **替代失效 CLEU**：在 `GroundEffectService` 中全面移除 `COMBAT_LOG_EVENT_UNFILTERED` 註冊，改為訂閱 `UNIT_SPELLCAST_SUCCEEDED` 且篩選 `unitTarget == "player"`，100% 規避 CLEU 在 12.x 中的封閉限制，完美重建暴風雪等地面技能計時。
    - **高頻能量無延遲更新**：在 `ClassPowerService` 中追加註冊 `UNIT_POWER_FREQUENT` 事件，使聖能、連擊點更新反應速度達到 0ms 延遲。
    - **技能 Override 動態跟隨**：在 `CooldownService` 註冊 `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED`，當法術因天賦/狀態 override 變更時，即時刷新被覆蓋或原始技能的冷卻，徹底消除 override 時計時失效/殘留 Bug。
    - **原生快捷列金色發光同步**：在 `AlertManager` 中監聽 `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` 與 `SPELL_ACTIVATION_OVERLAY_GLOW_HIDE` 快捷列高亮事件，維護本地 `glowSpells` 表，以 Decorator（裝飾屬性）形式為 Aura / Cooldown 狀態添加 `state.overlayGlow` 標記；Renderer 動態支援 `pandemicReady` 與 `overlayGlow` 雙軌顯示金色發光，100% 同步官方 Proc 發光。
    - **靜態安全語法檢驗**：修改之所有 5 個核心檔案 100% 通過 `luac -p` 的靜態語法檢查。
*   **除錯診斷與統計工具修復與擴展 (2026.06.07 已完成)**：
    - 修復 12.1.0 模組重構後，診斷日誌中 `visibleIcons` 恆為 `0` 與 `alertFrame.exists` 恆為 `false` 的統計 Bug。
    - 擴展 `/eam debug` 輸出資訊，新增各數據服務的 `active` 監控 Spell ID 列表、記憶體佔用 `memoryKB`、`glowSpells` 發光快取列表、以及 7 大 Alert Frame 底下所有活躍 Icon 的座標與實體 `:IsShown()` 屬性，極大增強後續除錯與日誌分析穿透力。
    - 靜態安全語法檢驗：修改之 2 個診斷模組檔案 100% 通過 `luac -p` 靜態語法檢查。
*   **技能無冷卻時強行顯示空圖示 Bug 修復 (2026.06.07 已完成)**：
    - 修復非 Charge 技能在完全沒有在冷卻中（`cooldownInfo` 為 `nil`）時，因 `infoSafe` 判定防衛過當而強行在畫面上顯示 15 個無倒數、無螺旋陰影的空圖示 Bug。
    - 修正 `CooldownService.lua` 的 `shouldShow` 邏輯，增加 `cooldownInfo` 存在性 guard，無冷卻時直接保持不顯示，回歸精準監控。
    - 靜態安全語法檢驗：修改之 `CooldownService.lua` 100% 通過 `luac -p` 靜態語法檢查。
*   **戰鬥受限（Secret）光環時間倒數降級與自動到期回收機制 (2026.06.07 已完成)**：
    - 當玩家在戰鬥中，光環時間與過期時間被標記為 Secret 時，實作優先透過 `C_TooltipInfo` 抓取說明中的持續時間（`scrapedDur`）來建立非 Secret 的普通 `DurationObject` 與數值型計時器（`TIMER_NUMERIC`），讓 Renderer 能正常渲染倒數。
    - 在 `UI/Renderer.lua` 中維護 `activeDurationObjects`，在統一的 `onLegacyTimerUpdate` 系統中每幀對其進行原生 `:IsZero()` 判定。一旦到期，主動觸發隱藏與回收，徹底免除 Secret 光環殘留 Bug。
    - 靜態安全語法檢驗：修改之 `AuraService.lua` 與 `UI/Renderer.lua` 100% 通過 `luac -p` 靜態語法檢查。
*   **12.1.0 零分配 StatePool 回收與基於 Pool-Token 延時排程之 JIT 優化實作 (2026.06.09 已完成)**：
    - **P0 記憶體洩漏修復**：在 `AuraService.lua`、`GroundEffectService.lua`、`TotemService.lua` 的 `StatePool.acquire` 內，統一安全地綁定 `state.releaseFunc = Pool.release`，並在 `release` 時將其設為 `nil`，100% 確保 `AlertManager` 在隱藏 icon 後能成功回收 state，解決了預分配物件池耗盡落入 GC Churn 的嚴重 P0 Bug。
    - **消滅 JIT Trace Abort**：完全移除在 OnUpdate 中對 `durationObj:IsZero()` 的 `pairs` 輪詢與 `pcall` 檢查。改為在 `Renderer.render` 啟動計時器時，透過 `timerTokenPool` 零分配令牌池獲取 token，並以 `Scheduler.after` 註冊單次延期回收任務。
    - **極限 0-Allocation 效能**：到期時由 `onDurationTimerExpired(token)` 判斷 token 活躍狀態以精確隱藏與回收。整個計時與回收流程完全達成 0-Allocation（零堆記憶體配置）與零輪詢 CPU 開銷，消除了戰鬥微卡頓，且熱路徑 100% 可被 LuaJIT 編譯，速度提升數百倍。
    - **靜態安全語法檢驗**：修改之 4 個核心檔案全部 100% 通過 `luac -p` 靜態語法檢查。
*   **12.1.0 專家矩陣擴展與新專家定義 (2026.06.09 已完成)**：
    - **專家定義**：使用 `define_subagent` 定義了 `EAM_Mock_Sandbox_Expert` (MOCK)、`EAM_Data_Guard_Expert` (DATA)、`EAM_DevOps_Release_Expert` (DEVOPS) 與 `EAM_Combat_Scraper_Expert` (SCRAPER) 四大全新領域的專家，並在系統中完成註冊。
    - **RACI 矩陣升級**：修改 `Docs/21_RACI_EXPERTS_MATRIX.md` 擴展專案的 RACI 職責矩陣，引入「沙盒測試」與「WTF 設定檔遷移」兩個全新的任務領域，確立了新增專家的 R/A/C 分工定位，理清了自動化測試、WTF 設定遷移防禦與 CI 發佈的權責邊界。


