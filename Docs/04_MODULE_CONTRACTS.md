<!-- EAM_DOCUMENTATION_SOURCE: zh-TW -->
# 模組合約

## 所有權規則

- `SavedVariables` 擁有持久配置表和遷移。
- 服務擁有運行時事實。
- `Renderer` 擁有渲染的 UI 狀態。
- `IconPool` 擁有框架物件。
- `Scheduler` 擁有應有的工作。
- `DebugState` 擁有 debug/session 快照。
- 靜態常數可能會被凍結。運行時狀態和 SavedVariables 絕不能
  被凍結。
- 每個主動載入的來源檔案必須以模組註解區塊開頭
  記錄目的、設計理念、所有權、突變邊界，以及
  保養注意事項。當模組合約發生變化時，請保持此評論最新。
  請參閱“Docs/12_CODE_COMMENTARY_GUIDE.md”。

## Core/Env

輸入：

- 外掛名稱和命名空間
- 正式服建置/flavor API

輸出：

- 外掛程式命名空間
- 本地 API 別名表
- 僅限正式服的防護結果

突變：
- 可以初始化外掛名稱空間一次
- 不得改變 SavedVariables

## Core/Util

輸入：

- 原始 Lua/WoW 表 API

輸出：

- `CreateTable`、`FreezeTable`、`IsFrozen`、泳池助手、安全擦除/release、
  穩定的枚舉助手，調試斷言
- Secret/protected 值安全讀取助手：
  - `readSafeField`
  - `readSafeScalar`
  - `markBoundary`
  - `appendBoundaryWarning`
  - `clearTimer`

突變：

- 僅擁有輔助本地池

## Core/Constants

輸入：

- 模組載入後無

輸出：

- 凍結枚舉表、模組名稱、事件名稱、狀態常數、模式
  版本、哨兵常數，例如 `UNKNOWN` 和 `EMPTY`

突變：

- 凍結後沒有

## Core/EventRouter

輸入：

- 模組事件註冊
- 暴雪事件

輸出：
- 透過參數化 `pcall` 錯誤隔離來分派對已註冊模組處理程序的調用，確保一個模組處理程序中的故障不會阻止其他註冊者

突變：

- 擁有事件框架與事件註冊表
- 每個活動報名沒有關閉分配

## Core/Scheduler

輸入：

- 模組請求的到期作業

輸出：

- 在保護性 `pcall` 隔離下進行回調度調度，確保捕獲作業運行時故障並且不會破壞全域程式碼框架
- 無論回調成功與否，安全佇列清理和任務記錄回收

突變：

- 擁有一個 OnUpdate 框架、到期佇列、可重複使用作業記錄和任務池
- 沒有每個圖示的調度表

## Core/SavedVariables

輸入：

- 舊版全域變數：`EA_Config`、`EA_Position`、`EA_Items`、`EA_AltItems`、
  `EA_TarItems`、`EA_ScdItems`、`EA_GrpItems`、`EA_Pos`
輸出：

- 版本化的活動設定文件
- 遷移報告
- 驗證警告
- 使用者觸發的警報添加/remove光環、法術冷卻和物品冷卻的API

突變：

- 在載入/migration/config變更期間可能會改變SavedVariables
- 不得寫入高頻運轉時狀態
- 不得結凍 SavedVariables
- 在使用者觸發的配置突變後增加 `EAM_DB.revision`

## Core/Performance

輸入：

- `GetFramerate`，戰鬥鎖定狀態，選用`debugprofilestop`

輸出：

- 節流決策、分析樣本、共享表池

突變：

- 僅擁有分析/session 計數器

## Services/AuraService

輸入：

- 設定玩家/target光環警報
- `UNIT_AURA`、`PLAYER_TARGET_CHANGED`、登入/world 事件

輸出：

- `EAM_AURA_STATE_CHANGED` 事件透過參數化狀態和 frameName 觸發到 EventRouter
- 從 `AuraStatePool` 分配的標準化 `AuraState` 和 `AlertState`
- 邊界警告
- 由單位和 `auraInstanceID` 鍵入的增量感知光環緩存
- 配置修訂感知警報索引，按單元鍵入並配置 spellID
- 完整更新回退掃描每個追蹤單元/filter一次，重建單元光環緩存，並將不匹配的配置警報標記為非活動狀態

突變：

- 僅擁有 aura 運行時快取和 `AuraStatePool`
- 不得創建 UI 框架
- 不得寫入 SavedVariables
- 當 SavedVariables 版本變更時可能會重建警報索引

## Managers/AlertManager

輸入：

- 來自 EventRouter 的 `EAM_AURA_STATE_CHANGED`、`EAM_COOLDOWN_STATE_CHANGED`、`EAM_ITEM_COOLDOWN_STATE_CHANGED`、`EAM_GROUND_EFFECT_STATE_CHANGED` 和 `EAM_TOTEM_STATE_CHANGED` 事件
- 配置警報列表

輸出：
-batch/throttled 呼叫包裝在佈局批次控制中的 `Renderer.render` (`Renderer.BeginBatch` / `Renderer.EndBatch`)
- 在 UI 隱藏渲染完成後，透過 `state.releaseFunc(state)` 回收多類型狀態表以回收非活動狀態（Aura、Cooldown、Item、GroundEffect、Totem）

突變：

- 擁有掛起的更新佇列和節流調度程序狀態
- 不擁有 AlertState、SavedVariables 或 UI 圖標

## Services/CooldownService

輸入：

- 配置法術冷卻時間警報
- 與冷卻相關的事件和調度程序後備刻度

輸出：

- 標準化 `CooldownState` 和 `AlertState`
- 髒警報 ID

突變：

- 僅擁有法術冷卻緩存

## Services/ShadowHostService

輸入：

- 暴風雪的原生 `EssentialCooldownViewer` 和 `Utility` 幀池狀態
- 動態框架 `Acquire` 和 `Release` 掛鉤
- 世界進入與再生狀態事件

輸出：

- 每個 spellID 映射活動主機圖示幀
- 非戰鬥中本機幀的零污染不可見設定（Alpha = 0）

突變：

- 僅擁有內部 spellID 到框架映射註冊表
- 不得在戰鬥中修改安全屬性

## Services/ItemCooldownService

輸入：

- 設定 itemID 警報
- 物品冷卻事件
- 可選的顯式快取建置命令

輸出：

- 標準化 `ItemCooldownState` 和 `AlertState`
- 快取狀態

突變：

- 擁有物品冷卻運轉時緩存
- 任何物品-法術映射快取都必須是增量且可中斷的

## Services/SpellInfoService

輸入：

- spellID/itemID 尋找請求

輸出：

- 安全名稱/icon/link 可用事實
- 有界查找緩存，僅儲存安全欄位和邊界警告

突變：

- 擁有查找緩存
- 必須避免激烈的戰鬥查詢循環
## Services/ClassPowerService

輸入：

- 配置類別資源選項
- 玩家電源事件（UNIT_POWER_UPDATE、UNIT_MAXPOWER、PLAYER_TALENT_UPDATE）

輸出：

- 當前等級功率類型的動態中央堆疊編號和 AlertState，在功率更新期間受到 `pcall` 隔離和 `issecretvalue` 檢查的保護，以繞過戰鬥中的限制值 /table 運行時異常
- 直接佈局渲染到 classPower 框架

突變：

- 除了調度事件狀態更新和防禦邊界記錄之外，沒有其他操作

## Services/GroundEffectService

輸入：

- 配置的地面效應項目（動態/manual模式）
- 未過濾的戰鬥日誌事件（SPELL_CAST_SUCCESS）
- 施法成功期間低頻 C_TooltipInfo.GetSpellByID 查找

輸出：

- `EAM_GROUND_EFFECT_STATE_CHANGED` 事件觸發到 EventRouter 並帶有狀態和 frameName
- 從 `GroundEffectStatePool` 分配的標準化 `GroundEffectState` 和 `AlertState`
- 透過 Scheduler.after 安排發布計時器

突變：

- 僅擁有地面效應活動計時器表、activeStates 快取和 `GroundEffectStatePool`

## Services/TotemService

輸入：

- 薩滿圖騰事件 (PLAYER_TOTEM_UPDATE)
- 本機 C_Totems.GetTotemInfo API 更新

輸出：

- `EAM_TOTEM_STATE_CHANGED` 事件觸發到 EventRouter 並帶有狀態和 frameName
- 從 `TotemStatePool` 分配的標準化 `TotemState` 和 `AlertState`

突變：

- 僅擁有 activeStates 快取和 `TotemStatePool`

## UI/IconPool

輸入：

- 所需的圖示數量/class

輸出：

- 取得/released圖示框記錄
- 預熱非活動圖示以避免創建戰鬥中框架

突變：

- 擁有框架、紋理、冷卻區域、FontStrings
- 框架創建應該在初始化期間或僅在受控增長期間發生
- 當池為空時，不得在戰鬥中創建新的圖標框架

## UI/Renderer

輸入：

- `IconRenderState`

輸出：

- 可見的UI狀態
- 佈局批次控制端點 (`Renderer.BeginBatch` / `Renderer.EndBatch`) 以延遲昂貴的 X/Y 佈局計算

突變：

- 僅改變 UI 框架
- 從不取得aura/cooldown數據
- 控制所有昂貴的 UI 寫入
- 推遲戰鬥中的結構佈局變化和首次圖標獲取

## UI/Options

輸入：

- 活躍的個人資料
- 類別標記到類別 ID 映射表 (`CLASS_TOKEN_TO_ID`)

輸出：

- 透過 `SavedVariables` 配置突變
- 使用本機「GetSpecializationInfoForClassID(classID, specIndex)」和強大的靜態後備表進行動態、本地化專業化下拉過濾，確保 100% 本地化類別 /spec UI 文本，無需硬編碼
- 用於明確 add/remove 操作的最小遊戲內面板：
  - 玩家光環spellID
  - 目標光環spellID
  - 法術冷卻時間spellID
  - 物品冷卻時間itemID
- 用戶觸發突變成功後立即刷新服務

突變：

- 僅 UI 小部件和明確配置值
- 如果正式服阻止或面臨受保護的 UI 突變的風險，則必須在戰鬥中延遲首次框架創建

## UI/Slash

輸入：

- `/eam` 指令文本

輸出：

- 設定操作、狀態文字、偵錯匯出請求
- 針對玩家光環、目標光環、法術冷卻時間和物品冷卻時間的簡單“/eam添加”和“/eam刪除”命令

突變：
- 可呼叫模組API；不得直接編輯服務內部
- 僅透過「Core/SavedVariables」寫入持久警報配置

## Debug/DebugState

輸入：

- 模組狀態快照

輸出：

- 緊湊的`DebugSnapshot`
- 來自服務狀態的聚合邊界警告

突變：

- 僅擁有瞬時調試記錄

## Debug/PromptExport

輸入：

- `DebugSnapshot`
- 匯出模式：`debug-min`、`analysis-full`、`github-issue`

輸出：

- 類似 JSON 的緊湊文本

突變：

- 除了瞬態字串產生器緩衝區之外沒有任何其他