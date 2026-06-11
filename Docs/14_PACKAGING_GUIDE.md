# CurseForge 打包指南

本文件定義 EventAlertMod Retail rewrite 的發佈打包規則。

## 快捷指令

日後使用者只要輸入：

```text
打包
```

就執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-CurseForgePackage.ps1
```

或者使用者只要輸入：

```text
打包開發版
```

就執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-CurseForgePackage.ps1 -DevMode
```

除非使用者另外指定參數，否則不需要再次詢問。

## 版本命名

TOC 版本名稱必須符合：

```text
EventAlertMod_資料片簡稱_打包年月日
```

目前資料片簡稱固定為：

```text
MN
```

範例：

```text
## Version: EventAlertMod_MN_20260504
```

## 打包檔名

zip 檔名必須符合：

```text
EventAlertMod_資料片簡稱_打包年月日_打包時分秒.zip
```

範例：

```text
EventAlertMod_MN_20260504_205216.zip
```

## 預設打包內容

- `EventAlertMod.toc`
- `README.md`
- `readme.html`
- `changelog.txt`
- `Core/`
- `Services/`
- `UI/`
- `Debug/`
- `Data/`
- `Locale/`
- `Media/`

## 預設排除內容

- `LegacyReference/`
- `ReferenceLibs/`
- `Tools/`
- `backup/`
- `.github/`
- `.vscode/`
- `Docs/`
- `Dist/_stage/`

## 可選參數

包含 Docs 與 AGENTS：

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-CurseForgePackage.ps1 -IncludeDocs
```

跳過 Lua 語法檢查：

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-CurseForgePackage.ps1 -SkipLuaCheck
```

開發版打包（將整個專案資料夾打包，不過濾，排除 .git/ 與 Dist/）：

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-CurseForgePackage.ps1 -DevMode
```

## 驗證要求

打包流程必須完成：

- TOC 路徑驗證。
- Lua 語法檢查，除非明確使用 `-SkipLuaCheck`。
- zip 排除檢查，確認沒有 legacy/reference/tools/backup/dev folders。

## HTML 說明文件轉換

- 對於 `Docs/` 下或根目錄 `AGENTS.md` 涉及表格、圖像、心智圖與流程圖的 Markdown 檔案，應執行 HTML 轉換工具，在 `docs_html/` 底下生成一份同名的 `.html` 檔案（例如 `filename.md.html`）。
- 開發與 AI 自動協作時，一律以 `.md` 檔案為絕對的 Facts-of-Truth 參考。`.html` 版本僅供人類好讀與預覽使用，不可被用作 AI 開發的配置或程式碼邏輯之依據。

## 注意事項

- 打包成功不代表 WoW Retail 實機驗證完成。
- 若 TOC `## Version` 與當日日期不一致，打包工具會停止。
- 發佈前仍需依 `Docs/06_TEST_PLAN_RETAIL.md` 做 Retail 實機測試。
