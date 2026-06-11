# 程式檔註解與理念規範

本文件是 EventAlertMod Retail rewrite 的開發參照。所有正式載入的程式檔都必須包含「檔案層級註解」，用來保存模組理念、責任邊界與日後維護判斷依據。

## 核心規則

- 每個正式載入的 `.lua` 檔案都要在檔案開頭放置模組註解。
- 註解需說明「這個檔案為什麼存在」，不只描述「這個檔案做什麼」。
- 註解要記錄資料所有權、可變狀態、不可跨越的模組邊界。
- 熱路徑、Secret Values、Protected Data、SavedVariables、UI frame mutation 相關檔案，必須明確寫出限制。
- 註解應保持簡潔、可維護；不要寫成與程式脫節的長篇宣言。
- 當模組責任改變時，必須同步更新檔案註解與 `Docs/04_MODULE_CONTRACTS.md`。

## 建議格式

```lua
--[[
EventAlertMod Retail Rewrite
Module: Core/EventRouter

理念:
- 集中管理 Blizzard event dispatch，避免各模組自行建立事件 frame。
- 使用孤兒 frame，降低 UIParent 與戰鬥保護互動風險。

責任:
- 擁有唯一事件 frame。
- 將 event 分派給已註冊 module handler。

邊界:
- 不讀取 aura/cooldown API。
- 不建立 UI icon。
- 不寫入 SavedVariables。

維護注意:
- 不在註冊熱路徑配置 closure。
- 不使用 RegisterAllEvents。
]]
```

## 必須記錄的項目

- `Module`：模組名稱與路徑。
- `理念`：設計理由與取捨。
- `責任`：此檔案擁有哪些狀態與行為。
- `邊界`：此檔案不能做什麼。
- `效能注意`：若在熱路徑上，說明 allocation、loop、string、UI write gating 策略。
- `Retail API 注意`：若使用 WoW API，記錄版本假設與實機驗證需求。
- `Secret/Protected Data 注意`：若接觸 aura/cooldown/unit data，記錄安全讀取與降級策略。
- `Taint 注意`：若接觸 UI frame、Blizzard frame、combat lockdown、protected route，記錄如何避免污染 secure/protected 路徑。

## 不需要的註解

- 不要註解顯而易見的單行賦值。
- 不要在熱路徑加入大量敘事註解。
- 不要用註解承諾尚未實作或尚未驗證的功能。
- 不要宣稱 WoW Retail 實機驗證，除非確實已載入測試。

## 對未來開發的要求

新增或重構任何正式載入檔案時，需先補齊檔案層級註解，再實作邏輯。若某個檔案只是 `LegacyReference`、`ReferenceLibs` 或外部保留資料，可保留原貌，但不得作為新架構風格範本。

## 修改前備份規則

任何檔案在刪除、搬移、覆寫或修改前，都必須先備份到專案根目錄的 `backup/` 資料夾。備份檔名使用原始檔名加上 `__yyyyMMddHHmmss` 後綴，例如 `Renderer.lua__20260526122904`。

這條規則的目的不是取代版本控制，而是提供本專案在尚未建立完整提交歷史前的低成本回溯來源。批次操作時，應先完成所有相關檔案備份，再開始實際修改；若原始檔案不存在，需先回報，不得建立空白備份。

## 開發問題紀錄規則

開發過程遇到的瓶頸、限制、錯誤、工具失敗、API 不確定性與解決方式，都必須追加記錄到 `Docs/15_DEVELOPMENT_ISSUE_LOG.md`。這份紀錄用來減少日後重複試錯，並在 AI 交接時節省 context/token。

紀錄時應保留足夠判斷資訊：日期、情境、症狀、原因判斷、已嘗試方法、有效解法與後續注意事項。未解決問題需明確標記為「未解決」，避免未來代理誤判為已完成。

## 專案專屬 Skill 規則

若開發過程中發現某個流程反覆出現，且流程已穩定到可以描述觸發條件、前置檢查、操作步驟、風險與驗證方式，應整理成 EventAlertMod 專案專屬 SKILL。這類 SKILL 用來降低重複指令說明、減少 context/token 消耗，並讓未來代理能一致執行專案慣例。

適合轉成 SKILL 的流程包含打包發佈、Lua 靜態驗證、WoW API 查證、SavedVariables migration 檢查、Secret boundary 審查、文件同步與語系檔同步。尚未驗證、仍需大量人工判斷或涉及敏感資訊的流程，不應硬做成自動化 SKILL。

## Taint 控制註解規則

涉及 UI frame、Blizzard frame、combat lockdown、secure/protected route 的檔案，檔案層級註解必須說明 taint 風險與避免方式。常見重點包含：是否使用孤兒 frame、是否接觸 UIParent、是否會在戰鬥中改 anchor/visibility/attribute、是否可能傳入 secret/protected value、是否會 hook Blizzard frame。

若程式碼刻意避免某個 Blizzard API 或 hook 方式，應在註解中保留原因，避免未來重構時把 taint 風險重新引入。
