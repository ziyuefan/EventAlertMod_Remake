# Retail AddOn 調研與 EventAlertMod 優化路線

本文件整理 2026-05-26 對 Warcraft Wiki、Blizzard forum、WoWInterface、CurseForge 與 Reddit AddOn 討論的調研結果，規劃 EventAlertMod Retail rewrite 的優化項目與目標。

本文件不是實機驗證報告。所有 Retail 12.x 行為仍需在 WoW Retail / PTR client 中載入測試。

## 調研來源

- Warcraft Wiki：`API_change_summaries`、`Patch_12.0.0/API_changes`、`Patch_12.0.5/API_changes`、`Patch_12.0.7/API_changes`、`Secret_Values`。
- Blizzard forum：UI and Macro、Bug Report 中關於 Secret Values、UnitHealth、movement speed、PvP scoreboard、blocked action / taint 的討論。
- WoWInterface：Cell、TweaksUI: Cooldowns、Threat Plates、ViksUI、Item Upgrade Quality Icons 等 Midnight changelog。
- CurseForge：Midnight Sensei、MidnightSimpleAuras、Cooldown Cursor Manager、Cooldown Manager Loader、MidnightCD、Enhance QoL 等專案頁與 changelog。
- Reddit：r/wow、r/WowUI、r/wowaddons、r/CompetitiveWoW 中關於 12.0 / 12.0.5 / Midnight AddOn API 的使用者與作者回饋。

## 最新 API 結論

- 12.0.0 是 Secret Values 與 AddOn combat API 限制的核心起點。
- 12.0.5 對 EAM 最重要：API predicates、`table.freeze`、`table.isfrozen`、formatter、DurationObject、aura 欄位 secrecy 調整、cooldown duration `ignoreGCD`。
- 12.0.7 API summary 已存在，TOC 為 `120007`；目前對 EAM 的直接核心影響較小，但新增 `C_DurationUtil.CreateDurationTextBinding`、`C_DurationUtil.CreateManualClock`，並移除 `C_DurationUtil.GetCurrentTime`。
- `GetEventCPUUsage`、`GetFunctionCPUUsage`、`GetScriptCPUUsage` 可作 on-demand profiling 候選，不可放入 hot path。
- Secret Values 不是單一欄位問題，而是 tainted execution path 下的普遍限制；不能靠 `pcall`、比較失敗 fallback 或 tooltip scraping 繞過。

## 社群與插件趨勢

- 作者普遍從「讀 aura/cooldown 數值後自行判斷」轉向「讓 Blizzard widget / DurationObject 顯示」。
- 多個插件改為逐值 `issecretvalue` 檢查，不再只依 context flag 判斷是否受限制。
- 一些 aura uptime 類插件放棄 combat aura spellID comparison，改用 cast event 與安全窗口估算，但必須標記為 derived，不可冒充 aura fact。
- Cooldown 類插件明顯往 Blizzard Cooldown Manager 整合、DurationObject、cursor/HUD 顯示與 CDM profile 輔助發展。
- Nameplate、unit frame、PvP scoreboard、unit name / GUID / UnitIsUnit、movement speed、health/power 類資料在 Midnight 中風險高，EAM 不應把它們納入核心 alert matching。
- Tooltip 文字也可能包含 secret value；tooltip parsing 必須低頻、逐行檢查、失敗安靜降級。
- Taint / blocked action 仍是常見痛點；避免污染 protected frame 比事後壓制錯誤更重要。

## EAM 優化總目標

1. 保持 EAM 的輕量定位：簡單、spellID 導向、比 WeakAuras 容易。
2. 把資料層改成「safe facts / derived / displayOnly / boundaryWarnings」明確分離。
3. Renderer 以 Blizzard widget / DurationObject 為優先，避免 Lua 自行倒數與字串格式化。
4. 對 Secret Values 採逐值安全檢查，不依賴單一 context guard。
5. 儘量支援 Blizzard Cooldown Manager 生態，但不硬依賴外部 addon。
6. 降低 taint 風險：不接 secure action、不改 protected frame、不 hook Blizzard protected chain。
7. 所有 debug / profiling / export 都採 on-demand，不進 hot path。

## 優先級 P0：安全與相容底線

- TOC 目前已錨定 `120007`；發佈前需同步確認打包工具、CurseForge game version ID 與實機驗證。
- 對 AuraService、CooldownService、ItemCooldownService 建立統一 secret-safe read adapter，避免各服務散落判斷。
- 禁止 aura `spellID` 直接比較前未檢查 secret；若不安全，狀態轉為 `boundaryLimited`。
- 禁止 tooltip line 未檢查就 `string.match`。
- Renderer 不讀回 Cooldown frame getter 作為 facts。
- Combat lockdown 下延後任何可能影響 frame 結構的 layout mutation。

## 優先級 P1：核心功能穩定化

- Player aura：先支援安全可讀的 self buff/debuff；不安全時顯示 icon/name 或 protected timer。
- Target aura：只追蹤 `target`，避免 targettarget / focus target / nameplate 延伸。
- Spell cooldown：使用 `C_Spell` structured returns；優先 `DurationObject`；支援 `ignoreGCD`。
- Item cooldown：直接 itemID 監控；不做大範圍 item scan。
- State model：每個 alert 明確標示 `factsSafe`、`timer.mode`、`source.api`、`boundaryWarnings`。
- Debug snapshot：輸出 facts / derived / boundaryWarnings / environment，不輸出 unsafe raw value。

## 優先級 P2：效能與低 GC

- 將 Scheduler task table 加入 pool，避免重複排程配置。
- AuraService 掃描改為「delta 優先 + full update 單位層級單次掃描」，避免每個 alert 重複掃描同一單位。
- Renderer 對 `SetText`、`SetTexture`、`SetCooldown`、`SetPoint` 全面 value gating。
- 將 icon state 與 service state 物件重用，避免每次 render 建新 table。
- on-demand profiling 可研究 12.0.7 CPU usage API，但預設關閉。

## 優先級 P3：使用者體驗

- 保留 `/eam add spellID`、`/eam remove spellID`、`/eam debug` 這種簡單語意。
- Options 只做必要功能：player aura、target aura、spell cooldown、item cooldown 的新增/刪除與啟用切換。
- 加入「資料受保護」的簡短 UI 狀態，不顯示錯誤堆疊給一般使用者。
- 可選擇提供 CDM 相關輔助：開啟 Blizzard Cooldown Viewer、提示使用者由 CDM 管理不適合 EAM 讀取的 cooldown。

## 優先級 P4：文件、測試與發佈

- 更新 `Docs/06_TEST_PLAN_RETAIL.md`：新增 12.0.7、DurationObject、secret tooltip、taint log、combat lockdown 測試。
- 建立專案專屬 SKILL 候選：
  - EAM 打包與版本同步。
  - EAM WoW API 查證與文件回寫。
  - EAM Secret / Taint 審查。
  - EAM Lua 靜態驗證與熱路徑掃描。
- 每次遇到工具限制或 API 陷阱，追加到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。

## 不納入目標

- 不做 combat automation。
- 不做 WeakAura scripting engine。
- 不做 PvP enemy clickable frames。
- 不靠 combat log 重建 secret facts。
- 不在 combat 中重建 protected layout。
- 不把 tooltip scraping 當核心資料來源。
- 不支援 Classic / MOP Classic / Cata / Wrath / Era。

## 下一步建議

1. 已完成 P0 safe-read、Renderer combat defer、Scheduler task pool。
2. 已完成 P1/P2 初版：SavedVariables add/remove API、Slash add/remove、AuraService `UNIT_AURA` delta-aware cache、debug snapshot 增補。
3. 已完成 P2 後半：AuraService full update 單位層級單次掃描、Options 最小可用 add/remove 面板。
4. P3 已有一項實測結果：使用者於 12.0.7 PTR client 確認 `C_DurationUtil.CreateDurationTextBinding` 最小範例可正常顯示。
5. 下一步應繼續實機驗證 `UNIT_AURA` delta/full payload、DurationObject / DurationTextBinding 整合、combat layout defer、Options template taint log。
6. 實機確認後再補舊 EAM group/special power 行為、Options 啟用切換與 CurseForge `120007` game version ID。
