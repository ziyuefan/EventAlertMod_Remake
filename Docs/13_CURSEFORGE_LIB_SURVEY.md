# CurseForge Lib 類插件調查

本文件調查 CurseForge 上可查到、名稱或用途接近 `Lib*` 的 WoW library 類插件，評估其是否適合 EventAlertMod Retail rewrite。

## 調查原則

- 不新增硬依賴。
- 不破壞 EAM 的輕量定位。
- 不引入 Classic/MOP 相容層作為正式架構核心。
- 不引入會高頻掃描、inspect、query 或大量配置的 library。
- 若採用，只能走 opt-in 或 soft dependency。
- 所有 library 使用前仍需做 Retail 12.x 實機載入驗證。

## 結論摘要

目前最值得保留觀察的候選只有兩類：

- `LibSharedMedia-3.0`：可選，用於字型、音效、材質選單。適合 options 階段再評估。
- `LibCustomGlow`：可選，用於 icon glow 效果。專案已保留舊版參考庫，可優先借鑑概念，不建議硬依賴。

其餘 library 目前不建議納入 EAM 核心，原因多半是過重、用途不符、更新停滯、依賴鏈太長，或與 EAM 自建的 EventRouter/Scheduler/SavedVariables 方向重疊。

## 候選評估

| Library | CurseForge 狀態 | 可能用途 | 評估 | 建議 |
|---|---|---|---|---|
| Ace3 | Retail 12.0.x，有大量下載，完整 AddOn framework | lifecycle、SV、event、config、GUI | 功能完整但過重，與 EAM 自建 Core/EventRouter/Scheduler/SV 重疊 | 不採用 |
| CallbackHandler-1.0 | Retail，有 AceEvent 背景用途 | callback registry | EAM 已有 EventRouter，需求不足 | 不採用 |
| LibInit | Retail，包 Ace3 多數元件 | 簡化 Ace3 setup | 會硬帶 Ace3/LibStub/CallbackHandler/AceDB/AceGUI 等，過重 | 不採用 |
| LibSharedMedia-3.0 | Retail 12.0.5，處理 font/sound/texture | options 裡選字型、音效、材質 | 與 EAM UI 設定有關，可作 optional integration | 可選軟依賴候選 |
| LibCustomGlow | Retail 12.0.x，custom glow | icon highlight/glow | 舊 EAM 已用過類似依賴；新架構可自作簡化 glow | 參考概念，暫不硬依賴 |
| LibDataBroker-1.1 | 老牌 LDB，主要供 broker display | minimap/data broker | 需配 display ecosystem，EAM 不需要 broker 化 | 不採用 |
| LibDBIcon-1.0 | Retail 12.0.x，需 LibDataBroker | minimap icon | 可做 minimap icon，但會引入 LDB/LibStub 依賴鏈 | 不採用，優先自建簡單按鈕 |
| LibQTip-1.0 | Retail 10.0.7，multi-column tooltip | options/debug tooltip | 用途偏 debug UI，版本較舊，EAM 不需要複雜 tooltip | 不採用 |
| LibRangeCheck-3.0 | Retail 12.0.x，range check | target range gating | EAM 核心是 aura/cooldown alert，不需要 range engine | 不採用 |
| LibDeflate | Retail 8.x，壓縮/解壓 | import/export 壓縮 | 可用於大型匯入匯出，但目前不做 WA 式分享系統 | 暫不採用 |
| Lib: Serialize | 已標示 abandoned，舊版 | serialization | 停滯且用途不符 | 不採用 |
| LibDualSpec-1.0 | Retail 12.0.x，AceDB spec profile | spec-specific profile | 依賴 AceDB 思路，EAM SV 自建 schema | 不採用 |
| LibGroupInSpecT | Retail 11.x，group inspect/spec cache | group alert/spec 條件 | 會引入 inspect/communication/cache，偏重且非核心 | 不採用 |
| LibWindow-1.1 | Retail 9.x，window frame helper | movable window | 功能小但過舊，EAM UI 可自行處理 | 不採用 |

## 可採用候選細節

### LibSharedMedia-3.0

用途：

- 提供跨 AddOn 的 media registry。
- 適合日後 `UI/Options.lua` 的字型、音效、材質選單。

優點：

- CurseForge 顯示支援 Retail 12.0.5。
- 與 EAM 的 sound/font/icon texture options 有自然交集。

限制：

- 不應成為 RequiredDeps。
- 不應讓 Renderer hot path 依賴它。
- 只應在 Options 開啟時查詢 media list。

建議整合方式：

```text
OptionalDeps: LibSharedMedia-3.0
if LibStub and LibStub("LibSharedMedia-3.0", true) then
    -- options-only integration
end
```

目前決策：保留候選，不立即加入。

### LibCustomGlow

用途：

- icon glow / pixel glow / button glow。

優點：

- 舊 EAM 已有 `LibCustomGlow-1.0` 參考資料。
- 可快速還原「冷卻可用時高亮」的視覺語意。

限制：

- 目前專案已移除正式載入的 external dependency。
- 若直接加入，會回到舊 `LibStub` 依賴鏈。
- 新 Renderer 可用簡化材質或 Blizzard 原生效果替代。

建議整合方式：

- 第一階段：只參考 `ReferenceLibs/LegacyLibs/LibCustomGlow-1.0` 的概念。
- 第二階段：若自製 glow 成本過高，再討論 soft dependency。

目前決策：參考概念，不硬依賴。

## 明確不採用原因

### Ace3 / LibInit

Ace3 是完整 framework，包含 lifecycle、SavedVariables、event、config、GUI、timer 等能力。這些能力與 EAM Retail rewrite 的自建核心重疊，而且會增加載入成本。LibInit 又是 Ace3 包裝層，會硬帶更多模組。

EAM 目前需要的是簡單、可控、低 GC 的 event-driven 架構，不需要 framework 化。

### LibDataBroker / LibDBIcon

Minimap icon 可以自建。引入 LDB/DBIcon 會把簡單功能變成 LibStub + LDB + DBIcon 依賴鏈，不符合目前「無硬依賴」方向。

### LibQTip

EAM 不需要 multi-column tooltip。Debug export 應輸出 compact text，不需要複雜 tooltip frame。

### LibRangeCheck / LibGroupInSpecT

這些 library 都有額外查詢、inspect 或 cache 行為。EAM 核心不是 raid assistant，也不需要 group spec/range engine。

### LibDeflate / Serialize 類

只有在將來建立大型 import/export 分享格式時才可能需要。EAM 明確不做 WeakAura-like 複雜分享系統，因此暫不採用。

## 來源

- [Ace3 - CurseForge](https://www.curseforge.com/wow/addons/ace3)
- [CallbackHandler-1.0 - CurseForge](https://www.curseforge.com/wow/addons/callbackhandler/source)
- [LibInit - CurseForge](https://www.curseforge.com/wow/addons/libinit)
- [LibSharedMedia-3.0 - CurseForge](https://www.curseforge.com/wow/addons/libsharedmedia-3-0)
- [LibCustomGlow - CurseForge](https://www.curseforge.com/wow/addons/libcustomglow/files/2625790)
- [LibDataBroker-1.1 - CurseForge](https://www.curseforge.com/wow/addons/libdatabroker-1-1)
- [LibDBIcon-1.0 - CurseForge](https://www.curseforge.com/wow/addons/libdbicon-1-0)
- [LibQTip-1.0 - CurseForge](https://www.curseforge.com/wow/addons/libqtip-1-0)
- [LibRangeCheck-3.0 - CurseForge](https://www.curseforge.com/wow/addons/librangecheck-3-0)
- [LibDeflate - CurseForge](https://www.curseforge.com/wow/addons/libdeflate)
- [LibDualSpec-1.0 - CurseForge](https://www.curseforge.com/wow/addons/libdualspec-1-0/files/all)
- [LibGroupInSpecT - CurseForge](https://www.curseforge.com/wow/addons/libgroupinspect)
- [LibWindow-1.1 - CurseForge](https://www.curseforge.com/wow/addons/libwindow-1-1/files)

## 後續建議

短期：

- 不新增任何 Lib 依賴。
- Renderer glow 先自製最小效果。
- Options 字型/音效清單先用內建 media。

中期：

- 若使用者強烈需要跨 AddOn media 選單，再評估 `LibSharedMedia-3.0` soft dependency。
- 若自製 glow 成本過高，再評估 `LibCustomGlow` soft dependency。

長期：

- 所有第三方 library 必須放入 `ReferenceLibs` 先審查。
- 經過 Retail 實機驗證後，才可加入正式 TOC。
