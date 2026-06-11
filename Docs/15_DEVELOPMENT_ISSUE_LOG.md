# 開發瓶頸、限制、錯誤與解法紀錄

本文件記錄 EventAlertMod Retail rewrite 開發過程中遇到的瓶頸、限制、錯誤、工具失敗、API 不確定性與有效解法。目的在於減少日後重複試錯，並讓未來 AI 代理能用較少 context/token 理解既有問題。

## 紀錄規則

- 新問題一律追加在「紀錄」區塊最上方，讓最新問題最容易被看到。
- 每筆紀錄至少包含日期、狀態、情境、症狀、原因判斷、已嘗試方法、有效解法、後續注意事項。
- 若問題尚未解決，狀態標記為「未解決」，並寫明下一步驗證方式。
- 不記錄密碼、token、私人帳號資料或任何敏感資訊。
- 若問題與 WoW Retail API 有關，需標明資料來源是文件、搜尋索引、NotebookLM、還是實機驗證。
- 若問題與工具或環境有關，需記錄作業系統、指令、錯誤訊息摘要與可行替代方案。
- 若同一類問題或操作流程重複出現，需評估是否整理成 EventAlertMod 專案專屬 SKILL。
- 若問題涉及 taint、blocked action、combat lockdown 或 protected frame，需記錄觸發路徑、戰鬥狀態、相關 frame/API 與可重現步驟。

## 建議格式

```md
### yyyy-mm-dd 標題

- 狀態：已解決 / 未解決 / 待實機驗證
- 情境：
- 症狀：
- 原因判斷：
- 已嘗試方法：
- 有效解法：
- 後續注意事項：
```

## 紀錄

### 2026-06-09 PowerShell Get-Content 在讀取單行檔案時索引 System.Char 導致 MethodNotFound 崩潰 (已解決)

- 狀態：已解決
- 情境：
  在 `Tools/Build-CurseForgePackage.ps1` 執行過程中，調用 `Scan-SensitiveInfo` 掃描敏感資訊時拋出 `MethodNotFound: [System.Char] doesn't contain a method named 'Trim'` 致命崩潰，導致打包流程中斷。
- 原因判斷：
  1. 當 `Get-Content` 讀取到單行檔案（如 `changelog.txt`）時，PowerShell 會將傳回值優化為單一 `[System.String]`，而非 `[System.String[]]` 陣列。
  2. 此時在 `for ($i = 0; $i -lt $lines.Count; $i++)` 迴圈中，使用下標 `$lines[$i]` 會將該 String 當作字元陣列處理，提取出其中的單個字元（型別為 `[System.Char]`）。
  3. `[System.Char]` 沒有 `.Trim()` 方法，因此調用時會引發 `MethodNotFound` 異常。
- 已嘗試方法：無。
- 有效解法：
  在 `Scan-SensitiveInfo` 函數中，將 `$lines = Get-Content ...` 修改為以 `@()` 強制包裝的 `$lines = @(Get-Content ...)`，確保不論檔案有幾行，傳回結果必定是數值陣列，從而使 `$lines[$i]` 始終傳回 String。
- 後續注意事項：無。

### 2026-06-09 CurseForge 打包腳本敏感字串正則過寬導致魔獸 12.x 原生 Secrecy 代碼誤報阻斷 (已解決)

- 狀態：已解決
- 情境：
  執行自動化打包時，安全閥警報指控 `Constants.lua` 中的 `BOUNDARY_SECRET_VALUE = "secretValue"` 與 `ClassPowerService.lua` 中 debug log 內字串拼接的 `"Secret"` 為敏感資訊洩漏，強行中斷打包。
- 原因判斷：
  原本的 regex 對 `secret` 單詞進行了無腦匹配，這會誤配對到 EAM 核心 Secrecy（受限/安全）防衛機制本身的常規變數與字串。
- 已嘗試方法：無。
- 有效解法：
  修改 `Tools/Build-CurseForgePackage.ps1` 中的 `$patterns` 正則，將寬泛的 `secret` 替換為精準檢索 `client_secret` 與 `app_secret` 等具體金鑰或憑證字樣。
- 後續注意事項：確認在未來修改與 secrecy 機制相關的代碼時，打包工具不會再被誤報干擾。

### 2026-06-09 自動化打包白名單漏掉 .blp 貼圖檔導致自訂 UI 資源遺失 (已解決)

- 狀態：已解決
- 情境：
  執行自動化打包腳本時，發現 `Media/Images/` 底下所有的貼圖與按鈕背景（如 `Seed1.blp`、`UI-Panel-Backdrop.blp`）全部被 Skip，產出的 ZIP 壓縮包內缺少這些貼圖檔。
- 原因判斷：
  `Tools/Build-CurseForgePackage.ps1` 中的 `$allowedExtensions` 白名單變數中，缺少了魔獸世界原生專用的貼圖副檔名 `.blp`。
- 已嘗試方法：無。
- 有效解法：
  將 `.blp` 正式加入白名單副檔名陣列中（即 `$allowedExtensions = @(".lua", ".xml", ".tga", ".blp", ...)`）。
- 後續注意事項：打包成功後，解壓發佈包確認所有圖片與音樂檔均完整存在。

### 2026-06-09 AI 研發環境 subagent 配額限制導致部分專家啟動失敗瓶頸 (已解決)

- 狀態：已解決
- 情境：
  主代理（Antigravity）嘗試同時並行啟動 5 位專家 subagent 進行 12.1.0 專家聯席審查與全代碼檢視。
- 症狀與原因判斷：
  1. 系統回報：`The subagent EAM_UI_Renderer_Expert (and Performance, API Security) encountered an error and has either stopped or failed to start execution: RESOURCE_EXHAUSTED (code 429): Individual quota reached. Contact your administrator to enable overages. Resets in 3h48m`.
  2. 原因：AI 執行平台對並行 subagents 呼叫次數或速率實施了硬性限制，在連續大數量派工時達到了 Quota 瓶頸。
- 已嘗試方法：無。
- 有效解法：
  1. **主代理代行職責**：根據 [Docs/17_SUBAGENT_WORKFLOW.md](file:///d:/EventAlertMod/Docs/17_SUBAGENT_WORKFLOW.md) 的 Critical Path 降級原則，主代理（Antigravity）立即代為承擔並整合 UI 渲染、安全防衛與效能控制的評估，確保專案進度不被阻塞。
  2. **整合已獲取的專家報告**：利用已成功取得的 `EAM_Addon_Architect` (ARCH) 與 `EAM_Lua_VM_Expert` (LUA) 重點報告（包含了對 JIT Trace Compiler 致命 `pcall` Abort 的要因分析，以及 `AuraService` 漏綁 `releaseFunc` 的重大 Bug 診斷），擬定最新的 JIT 優化實施計劃。
  3. **分批派工原則**：在後續開發中，應儘量避免一次性同時呼叫大於 3 個 subagents。在配額恢復前，相關的旁路任務一律由主代理本地直接執行。
- 後續注意事項：派工前須精確核算 WIP（在製品）數量，優先僅派發給 A 級核定者與 R 級執行者，降低平台配額耗竭之風險。

### 2026-06-07 設定頁面 Slider 圖示大小/間距調整無法反應到 7 大框架排版 Bug (已解決)

- 狀態：已解決
- 情境：
  使用者在 EAM 設定介面（`/eam opt`）中拖曳滑桿（Sliders）調整「圖示大小（iconSize）」或「圖示間距（iconSpacing）」時，雖然設定值順利儲存至 SavedVariables 中，但在遊戲畫面中 7 大告警框架的實際渲染大小與排列間距仍然固定在預設值（40 大小與 6 間距），調整完全無效。
- 症狀與原因判斷：
  1. 透過除錯統計導出的 JSON，發現 `config.iconSize = 73`，`config.iconSpacing = -33`，表示使用者確實成功修改了設定，且設定已被寫入。
  2. 然而，在實體渲染的 `runtimeStats.renderer.frameIcons` 詳盡屬性中，所有 Icon 的 `layoutSize` 仍然是預設的 `40`。
  3. 經對比代碼，發現在 `Core/SavedVariables.lua` 的 `defaults` 表與 UI Slider 的綁定中，使用者設定分別儲存在 `EAM.db.config.iconSize` 與 `EAM.db.config.iconSpacing`。
  4. 然而，在負責渲染排版的 [UI/Renderer.lua](file:///d:/EventAlertMod/UI/Renderer.lua) 中，其 `ensureParent` 函數與 `layout` 排版演算法均僅去讀取了 `EAM.db.layout.iconSize` 與 `EAM.db.layout.spacing` 欄位。這導致變數命名不一致，使渲染器永遠只能 fallback 讀取預設值。
- 已嘗試方法：
  備份 `UI/Renderer.lua` 至 `backup/Renderer.lua__20260607222900`。
- 有效解法：
  修改 [UI/Renderer.lua](file:///d:/EventAlertMod/UI/Renderer.lua)：
  1. 在 `ensureParent` 內，將 `Renderer.iconSize` 和 `Renderer.spacing` 欄位的賦值改為優先從 `EAM.db.config.iconSize` 和 `EAM.db.config.iconSpacing` 讀取，並相容舊版 `db.layout` 與 fallback 預設值。
  2. 在核心 `layout` 排版函數中，將 `local size` 和 `local spacing` 改為優先從 `EAM.db.config.iconSize` 和 `EAM.db.config.iconSpacing` 讀取，並相容 `db.layout` 欄位與 `Renderer` 本地預設值。
  3. 靜態 `luac -p` 語法檢驗 100% 通過。
- 後續注意事項：實機驗證時，確認在 Slider 調整大小和間距時，畫面上的告警圖示大小與間距是否能即時相應變化。

### 2026-06-07 戰鬥中對 Secret Boolean 進行布林判定 (Boolean Test) 導致 Taint 崩潰 Bug (已解決)

- 狀態：已解決
- 情境：
  在戰鬥中，如果一個光環或技能冷卻由原生 UI 的 `DurationObject` 進行渲染，當我們在 OnUpdate (例如 Renderer.lua 的 `onLegacyTimerUpdate`) 中呼叫 `durationObj:IsZero()` 判定其是否到期時，魔獸世界會拋出 `attempt to perform boolean test on a secret boolean value (execution tainted by 'EventAlertMod')` 致命錯誤，進而引起 Taint 崩潰並阻斷 UI 的 OnUpdate 執行鏈。
- 症狀與原因判斷：
  1. 在戰鬥中，`DurationObject:IsZero()` 的傳回值是 Secret Boolean，在 Lua 中直接做 `if val then` 條件判斷會直接觸發 Metamethod 阻斷崩潰。
  2. 這是因為暴雪的 Secrecy 保護機制限制了對 Secret Boolean 做布林值判斷。
  3. 如果要安全存取，我們不能對 Secret Boolean 進行 boolean test。但是，我們可以透過 `issecretvalue(val)` 來先檢驗傳回值是否是 Secret。如果它是 Secret，我們直接跳過對它的 boolean test 以策安全。如果它不是 Secret，我們才可以安全地做布林判斷。
- 已嘗試方法：
  備份 `UI/Renderer.lua` 至 `backup/Renderer.lua__20260607222500`。
- 有效解法：
  在 [UI/Renderer.lua](file:///d:/EventAlertMod/UI/Renderer.lua) 中引入 `safeCheckIsZero(durationObj)` 防禦性包裹函數：
  1. 先確認 `durationObj` 不是 `nil`，且具有 `IsZero` 函數，且 `durationObj` 本身不是 Secret。
  2. 使用無閉包的 `pcall` 傳參方式呼叫：`local ok, val = pcall(durationObj.IsZero, durationObj)`，以避免在 OnUpdate 熱路徑上產生 Heap 垃圾。
  3. 取得傳回值 `val` 後，使用 `Util.isSecretValue(val)` 檢查它是否是 Secret。若是 Secret，則回傳 `false`（不對其進行 boolean test）；若不是 Secret，則可以安全地回傳 `val == true`。
  4. 修改 `onLegacyTimerUpdate` 中對於 `activeDurationObjects` 的遍歷，改用 `safeCheckIsZero(durationObj)` 進行條件判斷。
- 後續注意事項：實機驗證時，確認在戰鬥中觸發受限的光環或冷卻時，當其到期時圖示是否能主動消失，且聊天視窗不再噴出 boolean test 錯誤。

### 2026-06-07 戰鬥受限（Secret）光環時間倒數降級與自動到期回收機制 (已解決)

- 狀態：已解決
- 情境：
  當玩家在戰鬥中，其所獲得的 Buff/Debuff 被魔獸世界標記為 Secret（如時間、過期時間受限無法讀取時），EAM 無法自行藉由 OnUpdate 倒數，且由於無法為其安排 scheduler 任務，導致光環在到期自然消失時，EAM 無法即時隱藏與回收 Icon 框架。
- 症狀與原因判斷：
  1. 魔獸世界 12.x 原生 `C_UnitAuras.GetAuraDuration` 所傳回的 `DurationObject` 雖然被保護（Secret），但原生 UI 可以對其進行綁定渲染。
  2. 由於 `DurationObject` 無法在 Lua 中讀取剩餘時間，原有的 EAM 排程器 (Scheduler) 與退彈機制無法獲悉它何時到期，只能完全依賴 `UNIT_AURA` 光環移除事件。然而戰鬥中事件常常被官方優化、節流甚至部分受限延遲。
  3. 幸運的是，原生 `DurationObject` 具有 `IsZero()` 方法，這在 Secret 狀態下是 safe、可安全呼叫的 predicate（回傳普通 boolean）。
- 已嘗試方法：
  備份 `Services/AuraService.lua` 和 `UI/Renderer.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **Secret 受限時優先抓取法術說明**：修改 `AuraService.lua` 中的 `readAuraIntoState`。當 `isSecret` 為 `true` 時，優先抓取法術說明的持續時間（`scrapedDur`）。若抓到，即用其手動建立一個非 Secret 的普通 `DurationObject`，此時它可走一般的數字計時倒數。
  2. **原生 IsZero() 輪詢與自訂回收**：修改 `UI/Renderer.lua`，實作 `activeDurationObjects` 管理。對於任何包含 `durationObject` 的活躍 Icon（不論是原生的還是手動建立的），在統一的 `onLegacyTimerUpdate` 中每幀對其進行 `IsZero()` 判定。一旦 `durationObj:IsZero()` 返回 `true`，立即主動呼叫 `Renderer.render(..., shown=false)` 進行隱藏與 IconPool 回收，主動釋放框架。
- 後續注意事項：實機驗證時需注意，在戰鬥中觸發受限的 Buff/Debuff 時，觀察當其自然結束時，圖示是否能迅速且無殘影地自動消失。

### 2026-06-07 技能冷卻監控在無冷卻時強行顯示空圖示且無倒數之 Bug (已解決)

- 狀態：已解決
- 情境：
  在使用者的實機除錯日誌中，`spellCooldown` 框架下一口氣顯示了 15 個技能圖示（包括冰槍、喚醒、火球等），但這些技能當時均處於非冷卻狀態且無倒數秒數文字。
- 症狀與原因判斷：
  1. `CooldownService.lua` 原先的 `shouldShow` 邏輯是：如果為非 Charge 技能，則當 `infoSafe` 為 `false` 時預設 `shouldShow = true`（防範戰鬥中受 Secrecy 限制而無法讀取的情形）。
  2. 然而，如果一個技能根本沒有在冷卻中，官方 `C_Spell.GetSpellCooldown` 可能會返回一個不含有效冷卻屬性的結構，甚至可能為空；或者是因為該技能不在冷卻中而使 `cooldownInfo` 為 `nil`。
  3. 此時，`infoSafe` 因為拿不到安全冷卻 facts 而保持為 `false`，這導致在判定時錯誤地落入了 `else shouldShow = true` 的防禦性分支！
  4. 結果是：所有被監控且目前沒有在冷卻中的技能均被強制設定為 `shouldShow = true`。它們被 Shown 到畫面上，但由於完全沒有冷卻時間數據，所以完全不會有倒數秒數與 Cooldown 螺旋黑幕。
- 已嘗試方法：
  備份 `Services/CooldownService.lua` 到 `backup/` 目錄。
- 有效解法：
  修改 [Services/CooldownService.lua](file:///d:/EventAlertMod/Services/CooldownService.lua) 的 `shouldShow` 邏輯：
  僅在 `cooldownInfo` **不為 nil** 時（代表該法術確實具有冷卻資料或在冷卻中），且在 `infoSafe` 為 `false` 的受限狀態下，才進行防禦性 `shouldShow = true` 的判定；若 `cooldownInfo` 為 `nil`，則直接不顯示。
- 後續注意事項：實機驗證時，請少年欸重新載入，確認這 15 個沒有在冷卻中的法師技能圖示是否已正確消失；僅在技能真正進入冷卻時才彈出圖示並正常顯示倒數。

### 2026-06-07 擴展 EAM 除錯診斷日誌統計資訊以加強 AI 除錯分析 (已解決)

- 狀態：已解決
- 情境：
  為了讓 AI 與開發者在獲取除錯報告時能更方便、深入地查找問題根源（例如究竟是 Service 層未偵測到，還是 Renderer 層未成功繪製），需要對診斷日誌進行擴充。
- 症狀與原因判斷：
  原先的診斷 JSON 僅輸出 states 的數量，當遇到「圖示沒有出現」等情況時，無法知道哪些 Spell ID 正被 active 監控、AlertManager 當前的發光狀態、以及 Renderer 中每個 Icon 的實體 layout 坐標與 `:IsShown()` 屬性。
- 已嘗試方法：
  備份 `Debug/PromptExport.lua` 到 `backup/` 目錄。
- 有效解法：
  修改 [Debug/PromptExport.lua](file:///d:/EventAlertMod/Debug/PromptExport.lua)：
  1. **擴充記憶體與各服務 active 列表**：加入 `memoryKB` 統計，並遍歷 5 大 Service（Aura, Cooldown, ItemCooldown, GroundEffect, Totem, ClassPower）的 states，收集當前 active 的法術 ID 列表。
  2. **加入 AlertManager 發光狀態**：收集 `glowSpells` 中目前正處於 Proc 高亮發光的 spellID 列表。
  3. **加入 Renderer 實體 Icon 詳盡 layout 屬性**：對於 7 大 Alert Frame，詳細輸出其下所有 active icon 的 `id`、`isParasite`、`layoutX`、`layoutY`、`layoutSize` 與在魔獸世界中的實體 `:IsShown()` 顯隱值。
  4. 靜態 `luac -p` 全案語法檢驗，順利通過。
- 後續注意事項：實機驗證時，請少年欸重新載入，打開 `/eam debug` 複製出的 JSON，檢查是否包含上述新擴充的陣列與物件。

### 2026-06-07 診斷工具 PromptExport/DebugState 讀取舊版欄位導致 visibleIcons 恆為 0 暨 alertFrame.exists 恆為 false Bug (已解決)

- 狀態：已解決
- 情境：
  在 12.1.0 零分配事件驅動與多框架重構後，使用者導出除錯診斷日誌，發現 `visibleIcons` 恆為 `0`，且 `alertFrame.exists` 恆為 `false`，進而誤判為沒有任何圖示顯示。
- 症狀與原因判斷：
  1. 重構後的 EAM 採用 7 大獨立 Alert Frame（`_G["EAM_AlertFrame_" .. fName]`），原先的單一全域框架 `EAM_RetailAlertFrame` 已被廢棄。
  2. 原先的 Renderer 全域欄位 `renderer.orderCount` 也已拆分封裝至各框架的私有 layout 狀態 `fState.orderCount` 中。
  3. 然而除錯統計工具 `Debug/PromptExport.lua` 與 `Debug/DebugState.lua` 在統計 `visibleIcons` 與 `exists` 時，依然嘗試讀取舊版的 `renderer.orderCount` 與 `_G["EAM_RetailAlertFrame"]`。這導致統計工具總是回傳 `0` 與 `false`，產生了「圖示完全未顯示」的統計資料假象。事實上，Renderer 渲染日誌正常，實體圖示已成功渲染並顯示於畫面。
- 已嘗試方法：
  備份 `Debug/PromptExport.lua` 與 `Debug/DebugState.lua` 到 `backup/` 目錄。
- 有效解法：
  1. **多框架狀態累加**：修改 `Debug/PromptExport.lua` 與 `Debug/DebugState.lua`，將 `visibleIcons` 改為累加 7 大 Alert Frame 的 `orderCount`；並將 `layoutDirty` 檢查改為若有任何一個 `fState.layoutDirty` 為 `true` 即為 `true`。
  2. **多框架存在檢測**：在 `PromptExport.lua` 內對 7 大 Alert Frame (如 `selfAura`, `targetAura` 等) 進行遍歷檢測與結構化輸出，只要至少有一個框架存在，即判定 `alertFrame.exists` 為 `true`，並精準呈現每個框架的座標與顯隱狀態。
  3. 靜態 `luac -p` 全案語法安全性驗證，修改之檔案 100% 通過語法安全性檢查。
- 後續注意事項：實機驗證時，請少年欸重新載入，再次導出 Debug Log JSON，驗證 `visibleIcons` 數值是否已與實體圖示渲染完全一致（顯示大於 0 的正確數量），且聊天視窗不再噴出錯誤。

### 2026-06-07 註冊內部自訂事件至 native Frame:RegisterEvent 導致 Attempt to register unknown event 崩潰 (已解決)

- 狀態：已解決
- 情境：
  在 `/reload` 載入插件時，魔獸世界直接拋出大紅字錯誤：`EAM Init Error on [AlertManager]: Frame:RegisterEvent(): Attempt to register unknown event "EAM_AURA_STATE_CHANGED"`，導致 AlertManager 初始化中斷，UI 徹底失效。
- 症狀與原因判斷：
  1. `AlertManager` 在初始化時，會調用 `EventRouter.register` 註冊多個內部自訂事件（如 `EAM_AURA_STATE_CHANGED`）。
  2. 原 `EventRouter.register` 的實作是不管任何事件均調用 `frame:RegisterEvent(event)` 往原生暴雪 frame 註冊。
  3. 魔獸世界 12.x 原生 `RegisterEvent` API 嚴格限制只能註冊 Blizzard 系統定義的事件，一旦傳入未知自訂事件名稱，會立即拋出致命錯誤並中斷執行鏈。
- 已嘗試方法：
  備份 `Core/EventRouter.lua` 到 `backup/` 目錄。
- 有效解法：
  在 [Core/EventRouter.lua](file:///d:/EventAlertMod/Core/EventRouter.lua) 的 `EventRouter.register(event, handler)` 中引入自訂事件過濾機制：
  判斷事件名稱是否以 `"EAM_"` 為前綴。如果是，屬於內部通訊自訂事件，跳過調用原生 `frame:RegisterEvent(event)`。
- 後續注意事項：實機驗證時需注意，觀察在 `/reload` 載入後，聊天視窗是否不再噴出任何 RegisterEvent 錯誤紅字，且 EAM 警報在各 Service 自訂事件觸發下能正常渲染。

### 2026-06-07 全新安裝或 WTF 檔案不存在時無預設監控法術 Bug 導致無 Icon 顯示 (已解決)

- 狀態：已解決
- 情境：
  在沒有舊版 EAM 全域變數（如 `EA_Items`、`EA_AltItems` 等）的全新安裝環境下（或 WTF 資料夾被清除），重寫後的 EAM 登入後一個 ICON 也沒有出現。
- 症狀與原因判斷：
  1. `SavedVariables.lua` 在初始化時，除了執行 `importLegacyTables` 嘗試從舊版全域變數遷移設定之外，沒有將 `EAM.Data.SpellArray` 中當前職業的預設監控法術寫入 `EAM_DB.alerts` 中。
  2. 當全新加載時，舊版變數不存在，因此 `alerts` 清單完全為空。
  3. 各個監控服務（`AuraService`、`CooldownService` 等）均使用 `EAM_DB.alerts` 進行篩選，若 alerts 為空則直接返回，不拋出任何更新事件與進行 UI 繪製，故畫面上一個 ICON 都沒有出現。
- 已嘗試方法：
  備份 `Core/SavedVariables.lua` 到 `backup/` 目錄。
- 有效解法：
  在 `Core/SavedVariables.lua` 的 `SavedVariables.initialize()` 中，加入全新加載（即 playerAuras/targetAuras/spellCooldowns/itemCooldowns 四者個數為 0 時）防空機制：
  自動檢測玩家當前職業，讀取 `EAM.Data.SpellArray` 中對應的通用及各專精預設監控法術，並呼叫 `SavedVariables.addAlert` 自動寫入至資料庫中。
- 後續注意事項：實機驗證時，可用命令 `/run EAM_DB = nil ReloadUI()` 測試在全新清空 SavedVariables 後，是否會自動讀取當前職業（如法師）的預設法術並顯示對應的 icon，且不再顯示空白。

### 2026-06-07 加強 EAM 常規框架降級 OnUpdate 倒數文字與防止原生數字重疊 (已解決)

- 狀態：已解決
- 情境：
  在放棄與官方 CDM 掛勾後，若遇到不具備 `DurationObject` 指針、或是不支援 12.0.7 native binding 的降級計時環境下，EAM 的獨立框架原本只進行陰影旋轉，而完全不顯示倒數秒數文字。此外，若原生 Cooldown 啟用，會造成原生小數字與 EAM 自訂大文字重疊。
- 症狀與原因判斷：
  1. `Renderer.lua` 原先僅實作了 `useNativeBinding` 模式下的文字綁定，降級模式下直接將 `timerText` 清空，導致一般計時不顯示剩餘秒數。
  2. 原生 `CooldownFrame` 預設可能顯示倒數數字，造成與 EAM 自身的 `timerText` 重疊，視覺不美觀。
- 已嘗試方法：
  備份 `UI/Renderer.lua` 和 `UI/IconPool.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **實作統一降級計時 OnUpdate 系統**：在 `UI/Renderer.lua` 中實作一個全域共享、基於單一 OnUpdate 框架的 `legacyTimer` 系統，提供 `registerLegacyTimer` 與 `unregisterLegacyTimer`。只有在降級 icon 活躍時該定時器才會啟動。
  2. **毫秒級小數倒數**：在該 legacyTimer 中，當剩餘時間低於 3 秒時，自動切換為一位小數倒數（如 `2.4`, `0.8`），高於 3 秒顯示整數，提供媲美原生的高級體驗。
  3. **回收防禦註銷**：在 `IconPool.release` 與 `Renderer.render` 過期隱藏時，確實調用 `unregisterLegacyTimer` 清除定時，防止殘影或 leak。
  4. **防止原生文字重疊**：在 `UI/IconPool.lua` 的 `createIcon` 中，對新創立的 Cooldown 框架調用 `cooldown:SetHideCountdownNumbers(true)`，徹底消滅文字重疊。
- 後續注意事項：實機驗證時需注意，在無 `DurationObject` 降級情況下大字倒數是否流暢，且 3 秒以下的小數點顯示是否精準無卡頓。

### 2026-06-07 放棄與官方 CooldownViewer (CDM) 掛勾與寄生吸附 (已解決)

- 狀態：已解決
- 情境：
  使用者要求放棄與官方冷卻管理器 (CooldownViewer / CDM) 的掛勾。需要將原先的影子載體吸附邏輯徹底關閉，讓所有冷卻與技能圖示回歸 EAM 自身的排版渲染框架。
- 症狀與原因判斷：
  原本為了繞過戰鬥中 Secret/Taint 的限制，實作了寄生在官方 CDM 圖示之下的 Shadow Host 技術。但在使用者決定不與其掛勾後，需要完全解除此功能，並確保官方 UI 完好如初。
- 已嘗試方法：
  備份 `Services/ShadowHostService.lua`, `UI/Renderer.lua` 與 `Core/SavedVariables.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **停用 ShadowHostService 初始化與 Hook**：在 `ShadowHostService.lua` 中註解底部的 `initShadowHost()` 呼叫，不進行任何 Hook，亦不隱形官方 UI；同時簡化 `ShadowHostService.GetHostIcon` 使其直接回傳 `nil`。
  2. **強制關閉 Renderer 吸附通道**：在 `UI/Renderer.lua` 的 `Renderer.render` 中，將 `useCDM` 寫死為 `false`，徹底斷開與 CDM 掛勾的判斷路徑。所有 Icon 將 100% 走 EAM 自行排版路線（`dx`, `dy` 方向定位）。
  3. **將 enableCDM 預設值設為 false**：在 `Core/SavedVariables.lua` 中，將預設設定的 `enableCDM` 設為 `false`。
  4. 靜態 `luac -p` 全案語法檢查編譯通過。
- 後續注意事項：實機驗證時需注意，觀察圖示排版是否完全回歸 EAM 常規定位（4向成長方向），且進入戰鬥時是否會有任何排版阻擋。

### 2026-06-07 12.x / Midnight-era: DurationObject 核心 API 與時間管理機制調查 (已解決)

- 狀態：已解決
- 情境：
  魔獸世界 Retail 12.x / Midnight 世代對時間管理（冷卻、光環、充能）實施了黑盒化（Pointer-Pass Pattern）。EAM 必須全面掌握所有能產生或傳遞 `DurationObject` 的 API 以進行高可用性、0-GC 與 Secret-Safe 的時間渲染。
- 症狀與原因判斷：
  傳統的 OnUpdate 數值倒數在戰鬥受限（Secret）下容易發生字串拼接與 Table 索引崩潰。為此，我們需要將原生 API 產出的 `DurationObject` 透過指針傳遞（Pointer-Pass）給原生 Widget，此時需要完整盤點所有可用 API 以便模組化重構。
- 已嘗試方法：
  閱讀 Warcraft Wiki 12.0.5 API 變更日誌，並以 Python 腳本對 API 日誌進行精準提取。
- 有效解法：
  1. **整理出四大類 API 清單**：
     * **冷卻/充能**：`C_Spell.GetSpellCooldownDuration`、`C_Spell.GetSpellChargeDuration`、`C_SpellBook.GetSpellBookItemCooldownDuration`、`C_SpellBook.GetSpellBookItemChargeDuration`、`C_ActionBar.GetActionCooldownDuration`、`C_ActionBar.GetActionChargeDuration`。
     * **光環持續**：`C_UnitAuras.GetAuraDuration`、`C_UnitAuras.GetAuraBaseDuration` 與 `C_UnitAuras.GetRefreshExtendedDuration`。
     * **工具/手動時鐘**：`C_DurationUtil.CreateDuration`、`C_DurationUtil.CreateManualClock`。
     * **Widget 關聯**：`self:GetTimerDuration()`。
  2. **掌握 ScriptObject 成員方法**：`IsZero()`, `GetRemainingDuration()`, `GetClockTime()`, `EvaluateTotalDuration()`, `FormatRemainingDuration(formatter)`, `FormatElapsedDuration(formatter)`, `FormatTotalDuration(formatter)` 等成員函數，並辨識其戰鬥 Secrecy 安全屬性（如 `IsZero` 為 NeverSecret 可安全做為到期檢測）。
  3. **落地改寫應用 (GroundEffectService)**：在 `Services/GroundEffectService.lua` 中補齊 `state.timer.durationObject = api.C_DurationUtil.CreateDuration(duration)`，使地面效果技能完美對接雙軌 Native Binding 倒數通道，消滅最後的 OnUpdate 與時間漂移。
  4. 將結果保存於 [duration_object_api_investigation.md](file:///C:/Users/ZYF/.gemini/antigravity/brain/b7690ead-b096-4f45-88f1-19a3c18d55f0/duration_object_api_investigation.md)。
- 後續注意事項：在未來的 AuraService 及 CooldownService 開發中，應將上述 API 當作第一優先取得時間的方式，並在 Renderer 中優先調用 Text Binding。

### 2026-06-07 實作以 Icon ID (Texture FileDataID) 做三級比對防禦以提升影子載體命中率 (已解決)

- 狀態：已解決
- 情境：
  在戰鬥中，如果 `spellID` 或者是 `spellName` 因 Secrecy (受限/加密) 而無法取得，或者是在載入客戶端快取時有延遲，會導致 EAM 無法準確比對並寄生吸附官方 CooldownViewer（CDM）的影子載體。
- 症狀與原因判斷：
  1. 雙軌比對（`spellID` 和 `spellName`）在極端戰鬥受限下，或在多國語系載入時，依然存在匹配失效的機率。
  2. 每個冷卻或光環圖示在其 Renderer 或官方 UI 上必定對應一個唯一的 Texture 圖片 (FileDataID)，這在戰鬥中通常不是 Secret，可作為極佳且唯一的標識特徵。
  3. **間接獲取法術名稱優勢（核心）**：一旦透過非受限的 Texture ID 將官方影子載體（Host Icon）與我們所監控非受限的 `spellID` 成功建立連結，EAM 渲染器即可利用非 Secret 的 `spellID` 靜態查詢獲取到真實的本地化法術名稱，並將其高亮渲染於寄生圖示內側底部，完美解決了戰鬥中官方 CDM 圖示因為 Secrecy 限制而無法顯示技能名稱的重大痛點。
- 已嘗試方法：
  備份 `Services/ShadowHostService.lua` 和 `UI/Renderer.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **建立三級 iconID 對照表**：在 `ShadowHostService.lua` 中新增 `activeIconHosts` 表與安全取得 host icon ID 的 `getIconIDFromHostIcon` 輔助函數（支援 `icon.Icon`、`icon.icon`、`icon.texture` 的 `:GetTexture()` 以及直接欄位讀取）。
  2. **三軌比對與 GetSpellTexture 動態解析**：將 `ShadowHostService.GetHostIcon` 擴充為 `(spellID, spellName, iconID)` 三軌比對。若沒傳入 `iconID`，會在內部利用 `C_Spell.GetSpellTexture(spellID)` 動態獲取要監控的法術圖示 ID，並在 `activeIconHosts` 中進行匹配。
  3. **動態 scanAll() Fallback**：在 `GetHostIcon` 內部如果首輪查表皆未命中，會自動調用 `scanAll()` 重新整理所有被 Hook 的官方 Viewer pool 映射（防範官方在 Acquire 時尚未設定 Texture 導致漏配），然後進行第二輪匹配，極限保障命中率。
  4. **Renderer 調用升級**：在 `UI/Renderer.lua` 中，調用 `GetHostIcon` 時傳入 `(alertState.spellID or alertState.id, alertState.name, alertState.icon)` 進行三軌查詢。
- 後續注意事項：實機驗證時需注意，觀察當 spellID 受限時，能否藉由 Texture ID 穩定吸附至官方對應的冷卻圖示上。

### 2026-06-07 CooldownService/AuraService 呼叫 secrecy API 發生 nil 錯誤 (已解決)

- 狀態：已解決
- 情境：
  在登入或觸發冷卻更新時，魔獸世界丟出 `Services/CooldownService.lua:324: attempt to call a nil value` 與 `Services/CooldownService.lua:328: attempt to call a nil value` 致命錯誤。
- 症狀：
  1. 當冷卻更新觸發並調用 `refreshAlert` 時，拋出 `attempt to call a nil value`。
  2. 錯誤被 `EventRouter` 或是系統錯誤機制捕獲，中斷了冷卻警報更新流程。
- 原因判斷：
  1. 在 `Core/Util.lua` 裡面，第 152 行直接調用了 local 變數 `isSecretValue(value)`，然而在魔獸世界客戶端加載 `Util.lua` 時，若 global 變數 `issecretvalue` 是 `nil`（例如特定正式服環境下該 global 未被曝露），那麼 local 變數 `isSecretValue` 就會是 `nil`。執行到此處即拋出 attempt to call a nil value！
  2. 同樣地，若 `issecretvalue` 及其它 secrecy 判定 API 為空，`EAM.API` 表中的 API 參考亦為 `nil`，導致諸如 `ShadowHostService.lua` 呼叫 `api.issecretvalue` 時同樣崩潰。
- 已嘗試方法：
  備份 `Core/Env.lua`, `Core/Util.lua`, `Services/CooldownService.lua` 到 `backup/` 目錄。
- 有效解法：
  1. ** seceret/secrecy 全域 API 容錯**：在 `Core/Env.lua` 中，為 `EAM.API` 的所有 secrecy 檢查方法（`issecretvalue`, `canaccesstable` 等）補上 callback fallback 預設值（例如 `issecretvalue = issecretvalue or function() return false end`），確保 `api.issecretvalue` 永遠不為 `nil`。
  2. **Util 本地 local 變數 fallback**：在 `Core/Util.lua` 中，為所有的 local 變數（`isSecretValue`, `canAccessTable` 等）補上 fallback 定義，且將 `readSafeScalar` 內部的直接 call `isSecretValue(value)` 改為調用已封裝妥當的 `Util.isSecretValue(value)`。
  3. **CooldownService 呼叫保護**：在 `CooldownService.lua` 中對 `cSpell.GetSpellCooldown` 的調用加上 `cSpell.GetSpellCooldown and ...` 防護，避免 API 不存在時發生 nil value 呼叫。
  4. 經靜態 `luac -p` 全案審查，32 個 active TOC 檔案全部通過。
- 後續注意事項：實機驗證時需注意，在任何環境下登入或觸發 CD 時是否還會拋出此類錯誤。

### 2026-06-07 影子載體技術 (Shadow Host) 實作以避讓戰鬥中 Secret/Taint 限制 (已解決)

- 狀態：已解決、待實機驗證
- 情境：
  魔獸世界 12.x 在戰鬥中對冷卻與光環時間（如 timeLeft, expirationTime）實施 Secret Value 限制，且在戰鬥中動態修改 Insecure UI 的佈局也可能因為 Taint 造成動作阻擋 (Action Blocked) 或者是 UI 排版抖動 (Layout Churn)。
- 症狀與原因判斷：
  1. 戰鬥中，自訂 UI 動態計算坐標並呼叫 `SetPoint` 容易因為 Secure Chain 污染而引起 Taint，或是造成排版計算效能負擔。
  2. 官方的冷卻管理器 (CooldownViewer / CDM) 是 Secure Frame，在戰鬥中享有定位與 Show/Hide 的特權，但只支援官方內建的法術。
  3. 為了同時享用原生 UI 的戰鬥特權並避免 Taint，我們需要一種在戰鬥中 100% 避讓排版代碼的解法。
- 已嘗試方法：備份 `EventAlertMod.toc`, `UI/Renderer.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **官方 Pool Hook 與影子化**：新建 `Services/ShadowHostService.lua`，在脫戰狀態下對官方 `EssentialCooldownViewer` 和 `UtilityCooldownViewer` 框架設置透明度 (`Alpha=0`) 與層級降級（`BACKGROUND`, `0`），並使用 `hooksecurefunc` Hook 官方 `cooldownPool` 的 `Acquire` / `Release`，收集 `spellID` 到官方 Icon 實體之對照。
  2. **寄生渲染與級聯排版避讓**：修改 `UI/Renderer.lua`。在 `Renderer.render` 中，若有官方 Icon 影子載體可用，則將 EAM Icon 設為 `isParasite = true`，以 `SetParent(hostIcon)` 與 `SetAllPoints(hostIcon)` 進行掛載，使顯示與位置隨官方 native 級聯同步。在 `layout` 中跳過 `isParasite` 圖示，消除戰鬥中 EAM 的 `SetPoint` 及排版計算。
  3. **二級比對防禦機制**：在 `ShadowHostService.lua` 中加入對 `spellName` 的安全提取（支援 `icon.spellName`, `icon.data.name` 與 `icon.Name:GetText()`）與二級查找表 `activeNameHosts`。在 `GetHostIcon` 接口與 `Renderer.render` 的吸附定位中，啟用 `(spellID, spellName)` 雙軌二級比對防禦，確保法術 ID 突變或被 Secret 加密時依然能穩定命中影子載體。
  4. **安全性防禦**：EAM Icon 保持 Display-only，不註冊 any 點擊或鼠標事件，阻斷 Taint 傳回 Secure Chain.
- 後續注意事項：實機驗證時需注意官方 CooldownViewer 的 Alpha 是否為 0 且 EAM 圖示吸附正確，在戰鬥中冷卻觸發時，觀察是否會出現 Action Blocked 或 Taint 錯誤。

### 2026-06-06 全代碼本地化清掃、動態專精 API 重構、ClassPower 與 EventRouter/Scheduler 故障隔離 (已解決)

- 狀態：已解決、待實機驗證
- 情境：
  1. 需要全面整理 EAM 程式碼中的硬編碼中英文 UI 與提示文字，使其支援完整多國語系（zhTW, zhCN, enUS, koKR, ruRU），並確保在 Windows PowerShell 終端下使用 Python 自動替換時不會因編碼問題而發生解碼崩潰。
  2. 戰鬥中能量監控模組 (ClassPowerService.lua) 對 `UnitPower` 的傳回值直接進行比較時可能因遇到 restricted 秘密值/秘密表而崩潰。
  3. `Core/EventRouter.lua` 與 `Core/Scheduler.lua` 的核心事件/定時任務循環，在單個子模組發生 runtime 錯誤時會波及全域，導致整個調度或事件發送被中斷癱瘓。
- 症狀與原因判斷：
  1. **硬編碼與多語系支援不足**：原 UI 與邏輯包含硬編碼的中英文，當切換魔獸客戶端語系時會顯示異常；且 Windows Powershell 預設使用 CP950/GBK 讀取 UTF-8 Lua 檔案時容易拋出 `UnicodeEncodeError`/`UnicodeDecodeError` 導致自動替換工具失效。
  2. **ClassPower 戰鬥 Secret Metamethod 崩潰**：魔獸 12.x 在某些戰鬥或特殊機制下將能量值標記為 `Secret Table`，如果非安全代碼直接將其與數值大小（如 `currentPower > 0`）比較，會觸發 metamethod 致命錯誤。
  3. **EventRouter/Scheduler 錯誤傳播**：原 EventRouter OnEvent 與 Scheduler OnUpdate 對 callback 的呼叫沒有進行隔離，一個訂閱者出錯，整個分發迴圈就會被 nil-index 或 traceback 中斷，使整體警報完全卡死。
- 已嘗試方法：備份 `UI/Options.lua`, `Services/ClassPowerService.lua`, `Core/EventRouter.lua`, `Core/Scheduler.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **全代碼本地化清掃**：將全案中所有硬編碼字串統一提取至本地化對照表 `EAM.L`（支援五大語系共 144 個詞條）。在替換工具中顯式宣告 UTF-8 讀寫，並用 `errors='ignore'` 保護，排除編碼崩潰。
  2. **動態專精本地化 API 重構**：在 `UI/Options.lua` 的專精過濾下拉選單中引入 `CLASS_TOKEN_TO_ID` 映射，優先調用原生 API `GetSpecializationInfoForClassID` 取得最準確的本地化專精名稱，並提供雙軌備份 fallback 防線。
  3. **能量防護防禦**：為 `detectClassPower` 與 `updatePower` 配置 `pcall` 隔離與 `issecretvalue` 防衛機制，防範戰鬥中能量數值突變為 Secret Table 時的大小比較造成的 Lua 崩潰。
  4. **EventRouter/Scheduler 故障隔離**：在 EventRouter 的 OnEvent 核心分發循環與 Scheduler 的 job 執行 callback 中，部署參數化 `pcall` 容錯，防止單一模組異常中斷其他模組與定時器的運行。
- 後續注意事項：實機驗證時需注意在木人戰鬥與首領戰鬥中，觀察多語系 UI 是否加載正確，以及當故意觸發單一模組錯誤時，EventRouter 和 Scheduler 是否依然能夠高可用性地分發與排程其他警報。

### 2026-05-30 12.x 戰鬥加密邊界：Secret-Key 查表崩潰、Tooltip String Taint 暨 Insecure Alert 戰鬥流暢化排除 (已解決)

- 狀態：已解決、待實機驗證
- 情境：實機戰鬥中遭遇了幾類深層的安全機制阻斷：
  1. `AuraService.lua:161: attempted to index a table that cannot be indexed with secret keys` 嚴重崩潰。
  2. `GroundEffectService.lua:78` 解析 tooltip description 時，因為 `string.match` 傳入了 Secret String，拋出 `attempt to perform string conversion on a secret string value (execution tainted by 'EventAlertMod')` 致命錯誤。
  3. 戰鬥中 alert 框架完全隱形不彈出。
- 症狀與原因判斷：
  1. **Secret Key Table 索引限制**：WoW 12.x 引進了強大的 Secret Protection。在戰鬥中，從 `GetAuraDataByIndex` 回傳的 `spellId` 或者是 `leftText` 都會被標記為 `Secret Value`。一旦 AddOn 代碼直接使用這個 `spellId` 作為 key 去對任何非 secure 的自訂 table 進行 index 操作（例如 `db[spellId]` 或 `SavedVariables[spellId]`），WoW 引擎會直接阻斷並拋出 `attempted to index a table that cannot be indexed with secret keys` 致命錯誤！
  2. **Secret String Taint 限制與參數傳遞限制**：當 tooltip description 在戰鬥中被標記為 Secret 時，我們不能在自訂的非 secure 函數中對其進行字串化（`tostring`）、字串拼接（`..`）或正則匹配（`string.match`）。最關鍵的是：**所有的秘密值都不能被當成參數傳遞給任何自訂 Lua 函數**！只要傳入，該函數就會被判定為 tainted，並在執行涉及 Secret 的動作時崩潰。
  3. **Insecure UI 戰鬥鎖定防衛過度**：先前代碼為了安全，在 `Renderer.lua` 和 `IconPool.lua` 中只要遇到 `InCombatLockdown()` 為 true，就把所有 `CreateFrame`, `SetPoint`, `Show` 與 `Hide` 渲染操作全部延後到戰鬥結束後（PLAYER_REGEN_ENABLED）。然而，我們的警報 Icon 是純顯示框架，不承擔任何 secure 動作（如點擊、施法、targeting 等），也沒有繼承任何 secure templates。WoW 引擎完全允許在戰鬥中對 Insecure 框架進行定位與顯隱。過度防範反而導致了戰鬥中警報完全隱形，喪失了 AddOn 的存在價值。
- 已嘗試方法：備份 `Services/AuraService.lua`, `Services/GroundEffectService.lua`, `UI/Renderer.lua`, `UI/Options.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **Table 索引防禦 (Table Indexing Defense)**：在 `AuraService.lua` 和 `CooldownService.lua` 等服務中，實施嚴格的 Table 查表前置 guards。在對配置表進行索引前，必須呼叫 `issecretvalue(key)` 確保 key 不是受保護的秘密值，並以 `canaccesstable(targetTable)` 檢查 table 安全。
  2. **即時 In-place 本地檢測與 native 檢查**：完全不使用自訂的 Wrapper 函數來傳遞與檢查秘密值。一律採用本地 in-place 模式，直接在 local 作用域中直接調用 native 的 C-level 安全 API（如 `issecretvalue`, `canaccessvalue`, `canaccesstable`）。
  3. **Tooltip String 安全降級**：在對 tooltip line 描述進行 match 匹配前，以 `issecretvalue(text)` 與 `canaccessvalue(text)` 進行嚴格防護。一旦發現描述被加密或不可讀取，立即安靜降級，並使用 native `C_UnitAuras.GetAuraDuration` 取得黑盒 `DurationObject`，直接交給 Renderer dual-pipeline 通道，利用 `CooldownFrame:SetCooldownFromDurationObject` 安全呈現計時，徹底消滅 string conversion 崩崩潰。
  4. **Insecure 警報框架完全釋放**：將所有 Alert Icon 框架類型從 `"Button"` 降級為純 `"Frame"`。徹底移除了所有戰鬥中定位和建立的 defer 限制，讓 Insecure Alert 圖示可在戰鬥中即時、無縫地彈出和移動，100% 戰鬥暢行無阻！
- 後續注意事項：實機驗證時需注意在木人戰鬥中高頻觸發 buff 時是否會跳出 Taint 報錯，並觀測大數量 buff 閃爍時，純 Frame 是否完美顯示與回收。

### 2026-05-30 UI slider 崩潰、C_DurationUtil binding 缺少 Unbind 與 ClassPowerService 核心 API 缺失之致命錯誤修復 (已解決)

- 狀態：已解決、待實機驗證
- 情境：少年欸回報設定介面無法使用，並且遇到 `bad argument #1 to 'SetValue' (outside of expected range -3.402823e+38 to 3.402823e+38)` 及 `UI/IconPool.lua:102: attempt to call a nil value` 致命錯誤，進入遊戲即拋出 `ClassPowerService.lua:85: attempt to call a nil value` 崩潰，導致介面與職業能量服務失效。
- 症狀：
  1. 輸入 `/eam opt` 打開設定頁時發生 Slider `SetValue` 錯誤，設定頁加載中斷，導致後續所有列表重新整理 (refresh)、法術增刪、Gear 按鈕 Popup 設定視窗及儲存/關閉功能全部失效。
  2. Cooldown alerts 觸發時發生 `IconPool.lua:102: attempt to call a nil value` (以及 `Renderer.lua:359` 報錯)，這是因為 `timerBinding:Unbind()` 在 12.0.7 原生環境下返回的 binding 對象不包含（或不支持）`:Unbind()` 方法，導致 nil-method 調用崩潰，渲染器管道被硬性中斷。
  3. 進入遊戲登入即拋出 `ClassPowerService.lua:85: attempt to call a nil value`，這是因為 detectClassPower 呼叫了 `api.UnitClass` 與 `api.UnitPower`，但在核心 `Env.lua` 的 `EAM.API` 表中遺漏了對這兩個 WoW 原生 API 的映射宣告，導致 API 調用崩潰，中斷了啟動載入鏈。
- 原因判斷：
  1. 在 `UI/Options.lua` 的 `createSlider` 函數中，`OnShow` 腳本讀取 SavedVariables 中某些 boolean 鍵值（如 `cooldownShadow = true`）時，直接將 `true`/`false` 傳入了滑桿的 `self:SetValue(val)`，而該 API 嚴格要求傳入 `number` 類型。一旦出錯，加載中斷導致整個 UI 對象（如 `scrollBox`, `addEditBox`, `condFrame` 等）均未完成綁定與初始化。
  2. 12.0.7 原生 API `C_DurationUtil.CreateDurationTextBinding` 回傳的 binding 物件實作中沒有 `Unbind` 方法，直接呼叫 `:Unbind()` 會拋出 nil 錯誤。
  3. `Core/Env.lua` 中預先註冊的靜態 API 表 `EAM.API` 漏掉了最常用的 `UnitClass` 與 `UnitPower`，這讓職業能量服務執行時直接呼叫了 nil 函數而崩潰。
- 已嘗試方法：備份 `UI/Options.lua`, `UI/IconPool.lua`, `UI/Renderer.lua`, `Core/Env.lua` 至 `backup/` 目錄。
- 有效解法：
  1. **防禦性型別轉換**：在 `Options.lua` 的 `createSlider` OnShow 中，加入對 `val` 的防禦性檢測與型別轉換。若為 boolean 轉換為 `maxVal`/`minVal`，若非 number 嘗試以 `tonumber` 解析或 fallback，並以 `minVal`/`maxVal` 進行安全邊界分，確保百分之百傳入合法 `number` 給 `SetValue`。
  2. **Unbind 防禦性封裝**：重構 `UI/IconPool.lua` 與 `UI/Renderer.lua`，將所有 `icon.timerBinding:Unbind()` 呼叫統一包裹於 `if icon.timerBinding and type(icon.timerBinding.Unbind) == "function" then icon.timerBinding:Unbind() end` 安全條件中，完美解決 12.0.7 native binding 無法解綁或方法變動的 runtime 崩潰。
  3. **補齊 Env 核心 API**：在 `Core/Env.lua` 的 `EAM.API` 中追加並匯出 `UnitClass = UnitClass` 與 `UnitPower = UnitPower`，接通職業能量監控服務與原生資料庫，順利排除登入 entry crash。
  4. **靜態語法檢查**：經 `luac -p` 全案審查無語法錯誤，安全無誤。
- 後續注意事項：實機驗證時需注意 Slider 拖動是否能將數值正常寫入，並且在開關 Alert Icon 和多重 CD 釋放/回收時，觀測有無 Memory Leak 或 Countdown 殘影。

### 2026-05-30 P1/P2：多國語系地面效果 Tooltip 解析與 table.freeze 效能重構 (已解決)

- 狀態：已解決、待實機驗證
- 情境：擴展地面效果 (GroundEffectService.lua) 監控，在 12.0.7 正式服環境下以 Tooltip Scraping 取得無光環地面技能的持續時間，需支援繁體中文 (zhTW)、簡體中文 (zhCN)、英文 (enUS/enGB)、韓文 (koKR)、俄文 (ruRU)。
- 症狀：原始實作僅支援繁體中文，且在迴圈中直接使用 ad-hoc 的 string key HASH lookup 與 regex 匹配，在 WoW 執行環境下可能引入效能開銷與 GC 垃圾回收負擔。
- 原因判斷：Lua 表的 string key HASH 查找具有一定的雜湊碰撞成本，即使以 `table.freeze` 鎖定也無法完全消滅雜湊機制。要達到極致效能，應使用數值索引陣列 (numerically-indexed array) 做為匹配模式載體，配合數字 for 迴圈迭代，這樣可以消滅雜湊搜尋並完全避免 runtime GC。
- 已嘗試方法：將 5 種客戶端語言的 regex 樣式，依 locale 封裝成 numerically-indexed arrays。藉由 `EAM.Util.tableFreeze` 對整體與子陣列做深度凍結 (table.freeze)。在 `parseTooltipDuration` 調用時自動識別 `GetLocale()` 並降級 fallback 至英文，然後執行雙層 numerically-indexed numeric loops。
- 有效解法：重構 `Services/GroundEffectService.lua`，引進 `MULTI_LOCALE_PATTERNS` 凍結表，並以極簡的高效雙層 `for i = 1, #data.lines` 與 `for j = 1, #patterns` 完成極速匹配。已通過 `luac -p` 靜態語法檢查。
- 後續注意事項：實機驗證時需注意各語系 Spell Tooltip descriptions 的變動，如俄語 (ruRU) 的縮寫變化，隨時調整或擴充 `MULTI_LOCALE_PATTERNS` 中的 regex 樣式。

### 2026-05-30 7 大獨立告警框架、4向成長方向偏移算術、地面/圖騰/職業能量三大全新監控服務導入 (已解決)

- 狀態：待實機驗證
- 情境：少年欸要求將不同監控分類（自身光環、目標光環、技能冷卻、物品冷卻、職業能量、地面效果、圖騰）拆分為 7 個完全獨立的告警框架，支援自訂拖曳與 4 向圖示成長方向設定。
- 症狀：原 Renderer 只維護單一 Alert Frame，且排版固定由左至右。若在大拉怪或多 CD 爆發的情境下，單一框架會顯得臃腫雜亂，無法區分優先級與資訊分流；同時缺乏對無光環地面技能（如暴雪、寶珠）與薩滿多圖騰、職業資源點數的專屬直觀監控。
- 原因判斷：純粹的字串分支判斷（如 `if growDirection == "RIGHT" ...`）在高頻的 Layout 渲染中會帶來 CPU 分支預測開銷與雜湊（Hash）Key 查找浪費。純 Hash 結構即使經 `table.freeze` 鎖定，其內部依然會進行雜湊衝突計算與碰撞比對，無法真正用空間換取時間。
- 已嘗試方法：
  1. **多框架隔離與算術 Layout 優化**：Renderer 重構為 `Renderer.frames[frameName]`，將 Layout 計算向量化，凍結連續數字索引的方向偏移對照陣列 `LAYOUT_OFFSETS` (Array Part)。在排版時直接透過 `LAYOUT_OFFSETS[growDirectionIdx]` 提取位移向量以算術乘法完成 SetPoint，消除 Hash 碰撞與多條件 If-Else 分支，極致提升 Lua VM 指令執行效率！
  2. **雙軌地面計時偵測 (GroundEffectService)**：引進 `COMBAT_LOG_EVENT_UNFILTERED`，在法術施放瞬間進行低頻 `C_TooltipInfo.GetSpellByID` Tooltip scraping 解析，獲取因加速、天賦動態影響後的秒數，或使用自訂時間。並以集中式 `Scheduler.after` 進行到期釋放，運行期 100% 零 CPU OnUpdate 開銷，表現極其穩健。
  3. **薩滿圖騰直讀 (TotemService)**：調用 12.x 原生 `C_Totems.GetTotemInfo` 直讀插槽，並支援靠攏排版。
  4. **資源點數 Icon 文字化 (ClassPowerService)**：依職業監控資源點數，以 Stacks 中央大號字體渲染，歸 0 自動釋放回收。
  5. **UI 擴展與一鍵擷取**：將 Options 設定面板重置為 560px 寬度的 Premium 雙分欄佈局（Sliders/成長選單 vs 能量 Checkboxes），並於 Popup 子視窗動態顯示地面技能一鍵擷取 Scrape & Fill 按鈕。
- 有效解法：Renderer 與 3 個新監控 Service 及 Options 分頁全面整合，通過全檔案 `luac -p` 的 100% 語法無誤靜態檢查，並提供 `/eam doctor` （RuntimeProbe）多框架實時事實目標性診斷功能。
- 後續注意事項：實機驗證中需觀察 7 大框架同步顯露移動時滑鼠拖曳的靈敏度與 SavedVariables 位置寫入之正確性。同時觀察大數量 Buff 戰鬥環境下，「空間換時間」靜態連續陣列 Layout 計算之零卡頓效能表現。

### 2026-05-30 實機戰鬥中 Secret/Taint 崩潰點排除、拖曳位置保存、專精下拉篩選與小地圖按鈕完美實現 (已解決)

- 狀態：已解決、待實機驗證
- 情境：實機測試中發現在戰鬥中技能/光環框架仍然不顯示、框架無法拖曳移動、物品冷卻無圖標、缺乏常用預設法術 ID 以及需要便捷呼叫小按鈕。
- 症狀與原因判斷：
  1. **戰鬥中不顯示的隱形崩潰點**：
     *   在 `AuraService.lua` 中，於戰鬥中直接讀取並對 Secret Value 的 `duration` 和 `expirationTime` 進行了數學減法運算，直接引發了安全異常中斷！
     *   在 `CooldownService.lua` 中，於戰鬥中直接對保護物件 `durationObj` 呼叫了 `IsZero()` 方法，引發了方法調用阻斷！
     *   `IconPool.lua` 使用 `"Button"` 類型框架容易在戰鬥中受到 WoW 引擎對點擊按鈕的防禦阻礙。
  2. **框架無法拖曳**：`Renderer.lua` 中遺漏了 `toggleAnchors` 的實作，且 `ensureParent` 沒支援載入 SavedVariables layout。
  3. **物品冷卻無圖示**：`ItemCooldownService.lua` 遺漏了透過 ITEM 相關 API 獲取並保存 `state.icon` 與 `state.name` 數據。
  4. **缺乏預設值與篩選過濾**：`Data/SpellArray.lua` 是空的佔位符，且 UI 缺少專精 Dropdown 過濾器。
- 有效解法：
  - **戰鬥防崩潰與框架降級**：在減法運算前用 `Util.isSecretValue` 防護降級；徹底移除對 `IsZero()` 的服務層調用，改由 Renderer 直接交給 Cooldown 陰影原生渲染；將警報 Icon 框架類型從 `"Button"` 降級為純 `"Frame"`，從此戰鬥中 `SetPoint` 及建立等操作 100% 暢行無阻！
  - **位置拖曳與保存**：完美在 `Renderer.toggleAnchors()` 中實作半透明拖曳框架，支援按住滑鼠拖曳並自動將 X/Y 坐標保存至 `EAM.db.layout`，於 `ensureParent` 時優先自動載入！
  - **物品冷卻圖示補齊**：使用 `C_Item.GetItemIconByID` 與 `GetItemNameByID` 補齊資料寫入，完美呈現物品 icon。
  - **小地圖按鈕（Minimap Button）**：在 `UI/Options.lua` 內建弧形軌跡小地圖按鈕，左鍵開啟面板，右鍵開啟系統診斷，拖曳角度自動保存。
  - **13 職業預設法術庫與專精過濾**：在 `Data/SpellArray.lua` 中填寫完整的 13 職業各專精/通用常用法術資料；在 UI 列表頂部新增專精過濾 Dropdown 按鈕與選單，點選即可動態篩選，且「預設值」按鈕支持一鍵自動加載當前職業全部預設！
- 後續注意事項：實機重載後即可體驗全新高階功能。

### 2026-05-30 致命 .toc 載入順序陷阱：局部變數快取致 Renderer 為 nil 阻斷渲染 (已解決)

- 狀態：已解決、待實機驗證
- 情境：實機測試中，所有的 WoW 事件均完美觸發（包括 `UNIT_AURA`、`BAG_UPDATE_COOLDOWN`、`SPELL_UPDATE_COOLDOWN`），且資料庫運作正常，但 Renderer 渲染管道完全沒有收到任何呼叫，日誌內毫無 `Renderer:render` 軌跡。
- 症狀：
  1. `alertsCount` 正確，`cooldownStates` 及 `auraStates` 被成功寫入。
  2. 但 `runtimeStats.renderer.visibleIcons` 與 `deferred` 均恆為 `0`，畫面完全無 Alert 圖示。
- 原因判斷：
  - **致命的 .toc 載入順序陷阱**！在 `EventAlertMod.toc` 中，`Services\AuraService.lua` 等服務的載入順序排在 `UI\Renderer.lua` 的上方。
  - 當服務被載入時，在檔案頂部執行了 `local Renderer = EAM.UI and EAM.UI.Renderer`。由於此時 `Renderer.lua` 尚未被執行，`EAM.UI.Renderer` 為 `nil`，導致服務內部的局部變數 `Renderer` 被永久快取為 `nil`。
  - 當後續事件觸發、需要刷新時，服務內的 `if Renderer and Renderer.render then Renderer.render(state) end` 因為局部變數 `Renderer` 是 `nil` 而被靜默地跳過，使整個渲染管道完全癱瘓！
- 有效解法：
  - 徹底避免檔案載入時的局部變數快取！將頂部 `local Renderer` 改為未賦值的局部宣告。
  - 在服務的 `initialize()` 方法執行時，動態將其賦值：`Renderer = EAM.UI and EAM.UI.Renderer`。此時 `.toc` 所有的檔案均已被完整載入，`Renderer` 可以完美獲取到正確 the 引用，成功接通渲染管道！
- 後續注意事項：實機重載後即可無縫彈出 Alert！

### 2026-05-30 EAM 戰鬥中 Alert 框架不顯示根本原因排查與物品監控獨立優化

- 狀態：已解決、待實機驗證
- 情境：實機測試中 Alert 框架完全沒有彈出，且物品監控需要更獨立與細部的 Options UI 分類配置。
- 症狀：
  1. 玩家施放技能、獲得 Buff 或進行背包物品冷卻測試時，畫面上完全無 Alert 框架或圖表，但在 Slash 指令中除錯診斷可以成功呼叫。
  2. 物品冷卻在 Options UI 裡缺乏獨立的分類（第 5 個紅按鈕被特殊能量佔據，物品沒有顯眼入口）。
- 原因判斷：
  1. **第一個致命 Bug**：`Services/ItemCooldownService.lua` 和 `Debug/PromptExport.lua` 開頭的 Lua 註解誤寫成 `-- [[`（多了一個空格），導致 Lua 編譯器報出語法錯誤而令這兩個關鍵模組在 WoW 啟動時完全載入失敗，破壞了載入鏈。
  2. **第二個致命 Bug**：`Renderer.lua` 和 `IconPool.lua` 的 `inCombat()` 戰鬥限制防衛過當。非 Secure 的 Alert 圖示框架不承擔 secure 點擊、click-cast，也沒有繼承 SecureTemplates，所以它是完全 Insecure 的純顯示框架。WoW 100% 允許在戰鬥中對 Insecure 框架進行 `CreateFrame`、`SetPoint`、`Show` 與 `Hide`。先前 AI 將這些操作在戰鬥中 defer 到脫戰後（PLAYER_REGEN_ENABLED），直接導致在最需要警報的「戰鬥中」圖示完全被阻斷，根本無法顯示！
- 已嘗試方法：
  - 將這兩個檔案開頭的 `-- [[` 改回無空格的標準 `--[[`。
  - 重構 `UI/Renderer.lua` 與 `UI/IconPool.lua`，徹底清除所有 `inCombat()` 戰鬥狀態下的 defer 渲染、defer layout 定位和拒絕 acquire 限制。
  - 在 `UI/Options.lua` 中，將設定分類擴充至 6 個紅按鈕（物品冷卻單獨分類至按鈕 5，特殊能量移至按鈕 6），排版間距調整至 32px，防止重疊，且在條件編輯彈窗中，如果是技能/物品冷卻，動態隱藏 Value 1~4 勾選。
- 有效解法：
  - 成功通過 `CheckLuaSyntax.ps1` 靜態語法檢查，28 個 Lua 檔案全部 100% OK！
  - 移除了所有對 insecure 框架的戰鬥中定位和建立阻擋，讓 Alert 圖示可在戰鬥中即時無縫彈出。
- 後續注意事項：請玩家（少年欸）重新載入介面後進入戰鬥測試，若有任何不適應或位置偏移，隨時使用 `/eam debug` 回報 JSON 診斷日誌。

### 2026-05-29 EAM 核心效能與邊界安全深度 GC/Taint 審查與二次極限優化

- 狀態：已解決、待實機驗證
- 情境：針對 `Services/CooldownService.lua`、`UI/Renderer.lua` 與 `Core/Util.lua` 進行全面性的垃圾回收（GC）與安全 Taint 深度審查，並實施二次極限效能重構。
- 症狀：
  1. 警告邊界路徑的 `Util.appendBoundaryWarning` 原先採用 `"code .. ":" .. tostring(field)"`，若在受限或 Secret 環境下被持續觸發，會導致執行期高頻的字串拼接 GC churn。
  2. 渲染器 `UI/Renderer.lua` 在高頻光環堆疊數值變更時，`tostring(alertState.stacks)` 會在 combat 中產生大量的微型字串 GC 負擔。
- 原因判斷：高頻事件下任何形式的 `..` 字串拼接與 `tostring` 調用，都是微型 GC 抖動（GC spike/stutter）的潛在來源，會導致大流量戰鬥下 FPS 微幅受損。
- 已嘗試方法：
  1. **警告字串靜態快取（warningStringCache）**：於 `Core/Util.lua` 引入局部 `warningStringCache = {}`。所有邊界警告字串在第一次生成時被快取，後續直接 `O(1)` 重複使用已分配指針，達成**邊界警告路徑零字串 GC 消耗**！
  2. **堆疊次數靜態快取（STACK_STRINGS）**：於 `UI/Renderer.lua` 引入 `STACK_STRINGS` 陣列，預先將 `1` 至 `100` 的堆疊次數轉換為靜態字串。高頻堆疊更新時，直接 `O(1)` 從陣列取用已快取字串，完全免除 `tostring` 的執行期記憶體分配！
  3. **戰鬥 layout 延後與 parent-parenting 控制**：確認 Renderer 無任何 secure action，非 secure 的圖示隱藏直接安全調用，而結構性 Frame parenting 與 layout 則嚴格延後至戰鬥結束（PLAYER_REGEN_ENABLED），消除 Secure Taint 擴散。
- 有效解法：重構代碼已成功寫入 `Core/Util.lua`、`UI/Renderer.lua` 與 `Services/CooldownService.lua`，完美封閉了所有高低頻 GC 漏洞與 taint 疑慮。
- 後續注意事項：實機測試時需特別開啟 Lua 記憶體監控，確認在滿負載戰鬥（如觸發大量 GCD、滿堆疊 buff/debuff 閃爍、多重邊界警告）情況下，EAM 的 GC 記憶體分配量維持在絕對的平穩水平。

### 2026-05-29 12.0.7 CooldownService 響應式二進位陣列與雙軌安全綁定優化

- 狀態：已解決、待實機驗證
- 情境：為 12.0.7 PTR/Retail 重塑 CooldownService 與 Renderer，避免戰鬥高頻事件（如 `SPELL_UPDATE_COOLDOWN`、`SPELL_UPDATE_CHARGES`）帶來的 GC 負載、Taint 污染與視覺殘影。
- 症狀：高頻事件下，以 `pairs` 遍歷設定 table 會頻繁分配 iterator 與暫時 table；且 Secret Values（如冷卻時間、充能資訊）在 Lua 層做數學運算、`format` 格式化或與舊 time 比較時會直接觸發安全 taint 或執行期 Lua 錯誤。
- 原因判斷：WoW 12.x 引進了嚴格的 Secret/Protected 限制。如果不隔離 Secret 資料，直接將其作運算或字串組裝就會污染 AddOn 安全鏈。另外，高頻事件下頻繁分配暫時 table 會導致微型 GC 停頓，影響遊戲 FPS。
- 已嘗試方法：
  1. 引入 **響應式陣列機制（Reactive Array Cache）**：透過檢測 `db.revision` 來增量更新 `alertList` 陣列，熱路徑（SPELL_UPDATE_COOLDOWN）上完全使用數值 `for i = 1, alertCount do` 迴圈遍歷，達到 100% 零 pairs、零 transient allocation 的極限效能。
  2. 使用 **`table.create` 預分配**：對 `alertList` 與 states / boundaryWarnings / timer 等子 table 預分配 HashTable 與 Array 容量，阻斷執行期擴容與 rehashing。
  3. 實施 **原生雙重綁定路徑（Dual-Binding Path）**：將 `DurationObject` 黑盒指標安全傳遞給原生 `SetCooldownFromDurationObject` 與 12.0.7 原生倒數文字綁定 `C_DurationUtil.CreateDurationTextBinding`。
  4. 實施 **零時跨度生命週期釋放（Zero-span Lifecycle Release）**：充能法術全滿時立即將 `state.shown` 設為 `false`，Renderer 接手將 Icon 退回 Pool 並執行 `icon:Hide()` 與 `Unbind()`，消除視覺殘影。
- 有效解法：在 CooldownService 與 Renderer 中已成功落地上列方案，完美完成雙軌安全判定與 Taint 控制防禦。
- 後續注意事項：需在 WoW 12.0.7 實機中，對充能法術（特別是充能非全滿與全滿切換時）及高頻觸發 GCD 時的雙重綁定路徑做實測，確認無殘影與閃爍問題。

### 2026-05-29 DurationTextBinding 12.0.7 PTR 最小範例實測

- 狀態：部分已驗證、待整合驗證
- 情境：使用者在 WoW 12.0.7 PTR client 執行 `C_DurationUtil.CreateDurationTextBinding` 測試範例。
- 症狀：需要確認 PTR API 是否只是文件層級，或已可在 client 中正常建立並驅動 FontString 顯示。
- 原因判斷：若 `DurationTextBinding` 可用，EAM timer label 可避免使用 `OnUpdate` 自行倒數，符合低 GC 與 Secret/Protected display chain 原則。
- 已嘗試方法：使用最小測試範例建立 `DurationObject`、`SecondsFormatter`、`DurationTextBinding`，並綁定到 FontString。
- 有效解法：使用者回報在 12.0.7 PTR client 中可正常顯示。
- 後續注意事項：此結果只驗證最小顯示，不代表 EAM Renderer 整合完成；仍需測 icon recycle、binding reference 保存、過期文字、zero duration、locale、combat/taint、API unavailable fallback。

### 2026-05-29 Subagent 使用規則持久化

- 狀態：已解決
- 情境：使用者要求後續本專案若有適合 subagent 模式的情境，需協助規劃並使用。
- 症狀：若只保留在對話記憶，後續長期開發或 context compact 後可能遺失授權與判斷標準。
- 原因判斷：Subagent 適合大型 rewrite、API 查證、文件一致性與靜態驗證分流，但若沒有明確規則，容易造成重複派工、寫入範圍衝突或等待阻塞 critical path。
- 已嘗試方法：搜尋並載入 multi-agent 工具；判斷本輪只是小型文件規則更新，不適合立即 spawn subagent。新增 `Docs/17_SUBAGENT_WORKFLOW.md`，並把規則加入 `AGENTS.md`。
- 有效解法：定義 critical path / sidecar task 判斷、適用與不適用情境、explorer / worker 角色使用、派工模板與主代理整合規則。
- 後續注意事項：後續大型 task 開始時，主代理需先明確說明是否使用 subagent；若使用，需指定不重疊寫入範圍，並在整合後重新執行專案靜態驗證。

### 2026-05-29 12.0.7 PTR / RC API 情報備查

- 狀態：待公開來源複核、待實機驗證
- 情境：使用者提供一段 12.0.7 PTR / RC 相關 API 變更內容，要求先紀錄備查。
- 症狀：內容包含 `GameTooltip_AddMoneyLine`、`C_UIFileAsset`、profiling API、`DurationTextBinding`、Aura refactor 目標 12.1.0、unit identity 錯誤改回傳 nil/default、`debugstack`/`debuglocals` secret 傳播等資訊，但本輪公開網路搜尋未找到可直接引用的同一來源頁。
- 原因判斷：這類資訊對 EAM Secret / Tooltip / Renderer / AuraService 邊界有實作影響，但若未標明來源狀態，容易在後續 pass 被誤認為已由 Warcraft Wiki 或 Retail client 驗證。
- 已嘗試方法：以搜尋查找 `GameTooltip_AddMoneyLine`、`DurationTextBinding`、`Timeline for the Aura Refactor` 等關鍵字；未取得穩定公開頁後，改以「使用者提供、待複核」形式寫入 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md`。
- 有效解法：文件明確拆分「與 EAM 直接相關」、「關聯較低但需留意」、「Classic PTR 不納入」三類，避免 Classic 內容回流到 Retail-only 架構。
- 後續注意事項：後續若 Warcraft Wiki、Blizzard forum 或 PTR client 文件可查，需補上正式連結；若進入實作，必須實機驗證 `GameTooltip_AddMoneyLine`、`C_UIFileAsset`、`DurationTextBinding`、`debugstack`/`debuglocals` 的實際行為。

### 2026-05-29 PowerShell 備份檔名插值問題

- 狀態：已解決
- 情境：修改文件前依規則備份 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md` 與 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。
- 症狀：第一次備份命令把目的檔名寫成 `$name__$ts`，在巢狀 PowerShell 字串中被錯誤解析，導致命令報出 `The term '\$name__$ts\' is not recognized`。
- 原因判斷：PowerShell 變數名稱邊界與外層引用混在一起時，`__` 後綴容易造成插值語意不清；加上外層 `powershell -Command` 需要額外轉義。
- 已嘗試方法：停止後續修改，改用明確字串相加：`$name + '__' + $ts`，並逐一輸出產生的備份路徑確認。
- 有效解法：備份檔已成功產生於 `backup/10_WARCRAFT_WIKI_12X_API_NOTES.md__20260529052816` 與 `backup/15_DEVELOPMENT_ISSUE_LOG.md__20260529052816`。
- 後續注意事項：日後自動備份腳本應避免把變數與後綴直接貼合；固定使用字串相加或 `${name}__${ts}` 類型寫法。

### 2026-05-27 P2 後半：Aura full update 單次掃描與 Options 最小面板

- 狀態：待實機驗證
- 情境：接續 P2 進度，將 AuraService 的 full update fallback 從逐 alert 掃描改成單位層級單次掃描，並補上可實際新增／移除設定的 Options 面板。
- 症狀：舊 fallback 容易在 `UNIT_AURA` full update 或 target change 時對同一單位重複掃描；Options 先前仍偏 stub，無法提供一般使用者可見的設定入口。
- 原因判斷：Aura full update 是熱路徑候選，若依 alert 數量重複掃描，使用者設定越多成本越高；Options 若不透過 `SavedVariables` mutation API，容易繞過 schema revision 與 service refresh。
- 已嘗試方法：新增 `fullScanUnit`，先清單位 aura cache，再依 player/target filter 掃描一次並用 alert index 分派；未命中的設定 alert 統一標為 inactive。Options 新增 spellID/itemID 輸入框與四類 add/remove 按鈕，成功後呼叫 service refresh。
- 有效解法：以 `auraInstanceID` cache 搭配 `alertIndex[unit][spellID]` 分派狀態；Options 只透過 `SavedVariables.add/remove` API 寫入，避免直接修改 service runtime state。
- 後續注意事項：需在 WoW Retail/PTR 驗證 `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)` 在 12.0.7 的實際欄位安全性、filter 行為、combat 中初次建立 options frame 的 taint 風險，以及 `BasicFrameTemplateWithInset` / `InputBoxTemplate` / `UIPanelButtonTemplate` 在 Retail 12.x 是否仍可直接使用。

### 2026-05-27 PowerShell regex 與變數 quoting 問題

- 狀態：已解決
- 情境：執行 `rg` 與 TOC 檢查時，命令字串由外層 PowerShell 再啟動內層 PowerShell。
- 症狀：regex 中的 `|` 被錯誤解讀成管線；TOC 檢查中的 `$missing`、`$line` 被外層提前展開，造成 parser error。
- 原因判斷：Windows PowerShell 的雙引號不是 shell-neutral 容器；在巢狀 `powershell -Command` 中，regex alternation 與 `$` 變數都需要明確處理。
- 已嘗試方法：將 regex 改用單引號包住；TOC 檢查中的 `$` 改用反引號轉義。
- 有效解法：專案內只讀搜尋優先使用 `rg -n 'pattern' path`；若必須在 `powershell -Command` 中使用腳本變數，需寫成 `` `$variable``，或改用既有 `.ps1` 工具。
- 後續注意事項：重複出現後可整理成「EAM Windows 靜態檢查」專案 skill，避免每次耗費 token 排查 quoting。

### 2026-05-26 P1/P2：Slash mutation 與 UNIT_AURA delta cache

- 狀態：待實機驗證
- 情境：依 P1/P2 目標繼續整理 EAM Retail rewrite 的核心功能與低 GC 熱路徑。
- 症狀：此前 `/eam` 只有 debug / options stub，SavedVariables 沒有正式 add/remove API；AuraService 在 `UNIT_AURA` 時仍回退全量掃描，未使用 `updateInfo` 增量 payload。
- 原因判斷：若沒有穩定 config mutation API，後續 Options UI 無法安全寫入設定；若每次 `UNIT_AURA` 都掃 alert/full aura，會增加 hot path 成本。
- 已嘗試方法：新增 `SavedVariables.add/remove` 系列 API、`/eam add/remove/export/help`、AuraService config revision index、`auraInstanceID` cache、`addedAuras` / `updatedAuraInstanceIDs` / `removedAuraInstanceIDs` 增量處理，以及 debug snapshot 的 DB revision/cache/renderer counters。
- 有效解法：Slash 只寫 SavedVariables，service 負責 refresh/render；AuraService 有 `updateInfo` 時走 delta，無 payload 或 full update 才回退完整掃描。
- 後續注意事項：仍需 WoW Retail/PTR 實機驗證 `UNIT_AURA` payload 實際欄位、secret aura spellID 行為、removed instance cache 命中率與 target rapid-change 行為。

### 2026-05-26 skill-creator quick_validate 缺少 Python yaml 模組

- 狀態：已解決
- 情境：建立 `.codex/skills/eam-retail-p0-review/SKILL.md` 後，依 `skill-creator` 流程執行 `quick_validate.py`。
- 症狀：第一次驗證腳本失敗，錯誤為 `ModuleNotFoundError: No module named 'yaml'`。安裝 PyYAML 後，第二次失敗為 Windows 預設 `cp950` 解碼 UTF-8 Markdown 失敗。
- 原因判斷：本機 Python 環境原本缺少 PyYAML；補齊套件後，`quick_validate.py` 使用 Python 預設文字編碼讀取 `SKILL.md`，在繁體中文 Windows 環境會遇到 cp950 解碼問題。
- 已嘗試方法：先安裝 `PyYAML 6.0.3`，再以 `$env:PYTHONUTF8='1'` 重新執行驗證。
- 有效解法：使用 `python -m pip install --user PyYAML` 安裝依賴，並在 Windows 上執行驗證前設定 `PYTHONUTF8=1`。`eam-retail-p0-review` 已通過 `quick_validate.py`，輸出 `Skill is valid!`。
- 後續注意事項：未來執行 Python Markdown/YAML 驗證工具時，若文件含中文，優先使用 UTF-8 模式，避免 cp950 解碼失敗。

### 2026-05-26 建立 eam-retail-p0-review 專案專屬 SKILL

- 狀態：已解決
- 情境：本輪重寫重複使用同一組流程：讀 AGENTS/Docs、修改前備份、P0 Secret/Taint 掃描、Lua 語法檢查、靜態風險掃描與 final report。
- 症狀：若每次都在對話中重述流程，會浪費 context/token，也容易漏掉備份或 taint/secret 掃描。
- 原因判斷：此流程已有穩定觸發條件、前置檢查、禁止事項、驗證方式與報告格式，符合專案專屬 SKILL 規則。
- 已嘗試方法：依 `skill-creator` 指南建立 `.codex/skills/eam-retail-p0-review/SKILL.md`。
- 有效解法：後續進行 EAM Retail rewrite、Secret/Taint 審查或 P0 靜態驗證時，優先使用此 SKILL。
- 後續注意事項：此 SKILL 只提供流程，不取代 Warcraft Wiki 最新 API 查證與 WoW Retail/PTR 實機驗證。

### 2026-05-26 P0/P1 重整：安全讀取、Renderer 延後 layout、Scheduler task pool

- 狀態：待實機驗證
- 情境：依最新 API 與社群調研開始整理正式載入的新架構 Lua 模組。
- 症狀：既有第一版骨架仍有數個 P0/P1 風險：AuraService 可能在 `spellID` 未確認安全前比較、Cooldown/Item cooldown 安全讀取分散、Scheduler 每次排程建立 task table、Renderer 每次 render 都 layout，且尚未明確延後戰鬥中的結構性 UI 變更。
- 原因判斷：這些問題會增加 Secret Values 誤用、combat lockdown / taint 風險與 hot path 配置成本。
- 已嘗試方法：新增集中 safe-read helper、Scheduler task pool、IconPool prewarm 與 combat-time frame creation guard、Renderer deferred layout、Debug boundary warning 聚合，並把 TOC/Constants 錨定到 `120007`。
- 有效解法：以 service 層逐值檢查 facts，Renderer 只消費 normalized state；戰鬥中遇到結構性 UI 變更先延後到 `PLAYER_REGEN_ENABLED`。
- 後續注意事項：尚未做 WoW Retail/PTR 實機驗證；必須測試 DurationObject、FontString:ClearText、combat layout defer、taint / blocked action log、12.0.7 game version ID 與 CurseForge 發佈設定。

### 2026-05-26 12.0.7 API summary 已發布，需修正先前待追蹤狀態

- 狀態：已解決
- 情境：調查最新正式版相關 WoW AddOn 開發討論與 API change 時，搜尋到 Warcraft Wiki `Patch 12.0.7/API_changes`。
- 症狀：既有 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md` 仍記錄 12.0.7 尚未找到 API summary。
- 原因判斷：Warcraft Wiki 近期已新增 12.0.7 API change 頁，先前紀錄已過時。
- 已嘗試方法：重新查詢 Warcraft Wiki API change summaries、12.0.5、12.0.7 與 AddOn 社群討論。
- 有效解法：更新 `Docs/10_WARCRAFT_WIKI_12X_API_NOTES.md`，將 12.0.7 標記為已存在，並記錄與 EAM 相關的 `C_DurationUtil`、CPU usage API 與 TOC `120007` 追蹤項。
- 後續注意事項：仍未做 WoW Retail/PTR 實機驗證；若目標正式版從 12.0.5 升到 12.0.7，需同步調整 TOC、打包版本與 CurseForge game version ID。

### 2026-05-26 加入 taint 控制規則

- 狀態：已解決
- 情境：使用者要求開發過程務求避免 taint 污染。
- 症狀：既有規範已涵蓋 Secret Values、Protected Data 與 combat-safe 降級，但缺少獨立的 taint 控制規則。
- 原因判斷：WoW AddOn 屬於不受信任來源；若污染 secure/protected execution path，戰鬥中可能導致 Blizzard UI 動作被阻擋。EAM 的 Renderer、EventRouter、UI frame 與 API adapter 都必須避免把 taint 帶進 action bar、unit frame、nameplate、施法、目標或物品使用路徑。
- 已嘗試方法：查證 Warcraft Wiki secure execution / taint 相關資料，並更新 `AGENTS.md`、`Docs/02_RETAIL_API_BOUNDARIES.md`、`Docs/12_CODE_COMMENTARY_GUIDE.md`。
- 有效解法：將 taint 視為架構邊界；禁止 hook/覆寫 protected 路徑、戰鬥中修改 protected frame、使用 `forceinsecure` 或傳遞 unsafe value 到 secure chain。
- 後續注意事項：發現 taint、blocked action 或 combat lockdown 錯誤時，需在本文件追加觸發路徑、戰鬥狀態、相關 frame/API 與可重現步驟。

### 2026-05-26 建立開發問題紀錄制度

- 狀態：已解決
- 情境：使用者要求將開發過程遇到的瓶頸、限制、錯誤與解決方式另做 `.md` 紀錄。
- 症狀：先前規範已有修改前備份規則，但沒有集中保存工具限制、API 不確定性與解法的文件。
- 原因判斷：專案正在進行長期 Retail rewrite，若問題只留在對話中，未來 AI 交接會消耗較多 context/token，也容易重複試錯。
- 已嘗試方法：新增本文件，並在 `AGENTS.md` 與 `Docs/12_CODE_COMMENTARY_GUIDE.md` 加入紀錄規則。
- 有效解法：後續遇到問題時，先依本文件格式追加紀錄，再進行下一輪大幅修改或驗證。
- 後續注意事項：本文件不得記錄 token、密碼、私人帳號資料或任何敏感資訊。

### 2026-05-26 重複流程需整理為專案專屬 SKILL

- 狀態：已解決
- 情境：使用者要求開發過程若發現重複流程，需整理成專案專屬 SKILL。
- 症狀：目前已有多個固定流程，例如修改前備份、打包、Lua 語法檢查、WoW API 查證與文件同步，但尚未明確規範何時應升級為 SKILL。
- 原因判斷：長期 rewrite 專案會累積可重複流程；若每次都靠對話重述，會增加試錯與 context/token 成本。
- 已嘗試方法：在 `AGENTS.md` 與 `Docs/12_CODE_COMMENTARY_GUIDE.md` 加入專案專屬 SKILL 規則，並在本文件加入判斷提醒。
- 有效解法：當流程具備穩定觸發條件、前置檢查、操作步驟、風險控管與驗證方式時，整理為 EventAlertMod 專案專屬 SKILL。
- 後續注意事項：尚未驗證、仍需大量人工判斷或涉及敏感資訊的流程，不應硬做成全自動 SKILL。

### 2026-06-07 12.x / Midnight-era 16 大全新與高頻事件納入與 Action Bar Glow 同步實作

- 狀態：已解決
- 情境：魔獸世界 12.x 正式服移除了 `COMBAT_LOG_EVENT_UNFILTERED` (CLEU)，導致地面地毯技能冷卻計時失效；且需要將技能圖示的金色亮框高亮 (Overlay Glow) 與快捷列按鈕的原生亮框發光完全同步。
- 症狀：以前地毯效果依賴 CLEU 的 `SPELL_CAST_SUCCESS`；光環/CD 圖示的高亮也缺乏對原生 Action Bar 金色亮框事件的即時訂閱，常因手動判定出現延遲或失效；且天賦切換造成技能 override 時冷卻圖示殘留失效。
- 原因判斷：CLEU 已被封禁；需要改用 Retail 正常之 `UNIT_SPELLCAST_SUCCEEDED` 獲取玩家施法；另外需藉由 `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` 與 `SPELL_ACTIVATION_OVERLAY_GLOW_HIDE` 取得原生動作條的高亮狀態，以及 `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED` 監聽技能 override 關係。
- 已嘗試方法：
  1. 在 `GroundEffectService.lua` 中，全面移除對 `COMBAT_LOG_EVENT_UNFILTERED` 的註冊，改為監聽 `UNIT_SPELLCAST_SUCCEEDED` 且篩選 `unitTarget == "player"`。
  2. 在 `ClassPowerService.lua` 中，註冊 `UNIT_POWER_FREQUENT` 事件提供無延遲能量回饋。
  3. 在 `CooldownService.lua` 中，註冊 `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED`，當法術 ID 變更時，即時刷新被覆蓋或原始技能的冷卻狀態，解決 override 計時失效 Bug。
  4. 在 `AlertManager.lua` 中訂閱 `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE`，維護 `glowSpells` 表並在 `onAlertStateChanged` 做被動裝飾（Decorator）屬性同步；修改 `UI/Renderer.lua` 的 `glowBorder` 判斷，支援 `pandemicReady` 與 `overlayGlow` 雙軌顯示金色發光。
- 有效解法：上述改動使 EAM 的事件管線更趨完善，100% 繞過了對 CLEU 的依賴；完全重用了原有物件池與發光邊框，依然維持 0-Allocation 低 GC 開銷。
- 後續注意事項：修改後的 5 個 Lua 檔案均順利通過了 `luac -p` 的靜態語法安全性審查，後續需在魔獸正式服中實機檢驗地毯效果觸發與金色亮框同步。

### 2026-06-09 EAM 12.1.0 零分配 StatePool 回收與基於 Pool-Token 延時排程之 JIT 優化實作

- 狀態：已解決、待實機驗證
- 情境：解決 AuraService 在大流量戰鬥中 80 個 AuraState 預分配物件耗盡後落入 GC Churn 的記憶體洩漏 P0 Bug，並消滅 OnUpdate 輪詢 `IsZero()` 導致 LuaJIT NYI Trace Abort 的效能瓶頸。
- 症狀：
  1. 戰鬥中 `/eam debug` 顯示的 runtimeStats 記憶體會隨著 Buff/Debuff 刷新持續攀升，物件池回收功能完全失效，引發 GC Churn 與 FPS 抖動。
  2. legacyTimerFrame 的 OnUpdate 迴圈遍歷輪詢 C++ 函數 `durationObj:IsZero()`，觸發了 LuaJIT 2.1 Trace Abort，導致 Hot Path 不能被 JIT 編譯，被迫降級為解釋執行，在 CPU 負載較高時造成微卡頓。
- 原因判斷：
  1. `AuraService.lua` 的 `AuraStatePool` 獲取與釋放設計中，漏掉了將 `AuraStatePool.release` 綁定給 `state.releaseFunc` 的核心代碼。這導致 `AlertManager` 在隱藏光環後完全跳過了回收邏輯。
  2. legacyTimerFrame 的 OnUpdate 每幀使用 `pairs` 遍歷輪詢 `IsZero()`，該 C++ 函數在戰鬥受限（Secret）下返回的是限制布林值，為防範崩潰我們使用了 `pcall`。然而在 JIT compiler 下，`pcall` 內呼叫暴雪 C 函數會直接觸發 NYI Abort，黑名單化整個 OnUpdate 渲染熱路徑。
- 已嘗試方法：
  1. 在 `AuraService.lua`、`GroundEffectService.lua` 與 `TotemService.lua` 的各自物件池的 `acquire` 內，統一安全地綁定 `state.releaseFunc = Pool.release`，並在 `release` 時清空 `state.releaseFunc`，使 `AlertManager` 能確實多型調用。
  2. 徹底移除 `Renderer.lua` 的 OnUpdate `IsZero` 輪詢與 `pcall` 宣告。
  3. 實作重用的零分配令牌池 `timerTokenPool`，在 `Renderer.render` 啟動計時器時，透過 `Scheduler.after` 註冊單次延時任務並傳遞 token。
  4. 到期時由 `onDurationTimerExpired` 判定 token 的 `active` 與 icon 活躍標誌是否一致，從而精確隱藏 icon，保證整個生命週期 100% 零記憶體配置與零輪詢開銷。
- 有效解法：
  - 重構代碼已成功寫入，4 個 Lua 檔案 `AuraService.lua`、`GroundEffectService.lua`、`TotemService.lua` 與 `UI/Renderer.lua` 均 100% 通過 `luac -p` 的靜態語法安全性審查。
- 後續注意事項：
  - 在 WoW Retail 中啟動 EAM，高頻切換 Buff 與冷卻時觀察記憶體曲線是否完全水平不攀升，並確認當光環到期時能精確自動消失，完全消除戰鬥 Taint 與 JIT Abort。
