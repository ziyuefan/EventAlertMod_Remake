--[[ EAM_FILE_COMMENTARY
EventAlertMod Retail Rewrite
Module: Core/SavedVariables
檔案: Core\SavedVariables.lua

理念:
- 用版本化 schema 接管舊 EAM SavedVariables，讓重寫可穩定 migration。
- SavedVariables 只保存設定，不保存 runtime facts。

責任:
- 初始化 EAM_DB、保存 defaults、執行舊 EA_* migration、提供 alert add/remove mutation API。

資料所有權:
- 擁有 EAM_DB schema 與 persistent config 的唯一寫入入口。

可變狀態:
- 只在載入、migration、使用者設定變更時寫入。
- 不得 freeze EAM_DB 或舊 EA_* tables。

邊界:
- 不讀 aura/cooldown API。
- 不寫入每 frame 或事件 hot path 狀態。

效能注意:
- migration 應一次性執行；大量修正需分批且避免戰鬥中處理。
- add/remove 是使用者觸發路徑，不進事件 hot path。

Retail API 注意:
- 保留舊 EA_* SavedVariables 名稱在 TOC，供 Retail-only migration 使用。

]]
local _, EAM = ...

local mathFloor = math.floor

local SavedVariables = {
    migrationReport = {
        imported = 0,
        skipped = 0,
    },
}
EAM.Modules.SavedVariables = SavedVariables

local defaults = {
    schemaVersion = EAM.Constants.SCHEMA_VERSION,
    revision = 0,
    debug = false,
    alerts = {
        playerAuras = {},
        targetAuras = {},
        spellCooldowns = {},
        itemCooldowns = {},
        groundEffects = {}, -- 新增地面效果配置
    },
    layout = {
        iconSize = 40,
        spacing = 6,
        frames = {
            selfAura = { growDirection = 1, x = 0, y = 120, point = "CENTER" },      -- 1 = RIGHT (向右)
            targetAura = { growDirection = 1, x = 0, y = 200, point = "CENTER" },
            spellCooldown = { growDirection = 1, x = -120, y = 0, point = "CENTER" },
            itemCooldown = { growDirection = 1, x = 120, y = 0, point = "CENTER" },
            classPower = { growDirection = 1, x = 0, y = -80, point = "CENTER" },
            groundEffect = { growDirection = 1, x = 0, y = -160, point = "CENTER" },
            totem = { growDirection = 1, x = 0, y = -240, point = "CENTER" },
        }
    },
    config = {
        showFrame = true,
        showSpellName = true,
        showTimeVal = true,
        showChangeInOut = true,
        showFlash = true,
        showSound = true,
        soundName = "ShayBell",
        allowEscCancel = false,
        showExtraAlert = false,
        cooldownRemoveAura = false,
        showSCDOutsideCombat = true,
        glowSCDWhenUsable = true,
        showDKRune = true,
        enableItemCooldown = true,
        enableCDM = false,
        
        -- 滑桿數值
        iconSize = 40,
        iconSpacing = 6,
        verticalSpacing = 0,
        selfDebuffRed = 0.5,
        targetDebuffGreen = 0.5,
        bossExecuteThreshold = 0.2,
        enableBossExecute = false,
        fontSizeSpellName = 12,
        fontSizeTimeVal = 14,
        fontSizeStack = 12,
        cooldownShadow = true,
        
        -- 職業特殊能量 (20種)
        powerHoly = true,
        powerShard = true,
        powerCombo = true,
        powerChi = true,
        powerRage = true,
        powerInsanity = true,
        powerMaelstrom = true,
        powerRunic = true,
        powerAstral = true,
        powerLifebloom = true,
        powerEnergy = true,
        powerFocus = true,
        powerArcane = true,
        powerRunes = true,
        powerFury = true,
        powerFrenzy = true,
        powerMana = true,
        powerPetFocus = true,
        powerPetEnergy = true,
        powerVigor = true,
    }
}

SavedVariables.defaults = defaults

local function ensureTable(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

local function normalizePositiveInteger(value)
    local numberValue = tonumber(value)
    if not numberValue or numberValue <= 0 then
        return nil
    end
    return mathFloor(numberValue)
end

local function buildAlertID(kind, unit, spellID, itemID)
    if kind == EAM.Constants.ALERT_KIND_ITEM_COOLDOWN then
        if not itemID then
            return nil
        end
        return kind .. ":item:" .. itemID
    end

    if not spellID then
        return nil
    end

    return kind .. ":" .. (unit or "player") .. ":" .. spellID
end

local function getAlertList(db, kind, unit)
    if not db then
        return nil
    end

    local alerts = ensureTable(db, "alerts")
    if kind == EAM.Constants.ALERT_KIND_AURA then
        if unit == "target" then
            return ensureTable(alerts, "targetAuras")
        end
        return ensureTable(alerts, "playerAuras")
    elseif kind == EAM.Constants.ALERT_KIND_SPELL_COOLDOWN then
        return ensureTable(alerts, "spellCooldowns")
    elseif kind == EAM.Constants.ALERT_KIND_ITEM_COOLDOWN then
        return ensureTable(alerts, "itemCooldowns")
    elseif kind == "groundEffect" then
        return ensureTable(alerts, "groundEffects")
    end

    return nil
end

local function touchRevision(db)
    if not db then
        return
    end
    db.revision = (db.revision or 0) + 1
end

local function copyMissingDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            local child = ensureTable(target, key)
            copyMissingDefaults(child, value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function addAlert(list, kind, spellID, itemID, unit, sourceTable, sourceKey, options)
    if type(list) ~= "table" then
        return false
    end

    local id = buildAlertID(kind, unit, spellID, itemID)
    if not id then
        return false
    end

    if list[id] then
        return false
    end

    list[id] = {
        id = id,
        kind = kind,
        spellID = spellID,
        itemID = itemID,
        unit = unit,
        enabled = options and options.enable ~= false,
        fromPlayer = options and options.self == true,
        legacy = {
            tableName = sourceTable,
            key = sourceKey,
        },
    }
    return true
end

local function importSpellTable(target, source, kind, unit, tableName)
    if type(source) ~= "table" then
        return 0, 0
    end

    local imported = 0
    local skipped = 0
    for spellID, options in pairs(source) do
        local numericID = tonumber(spellID)
        if numericID then
            if addAlert(target, kind, numericID, nil, unit, tableName, spellID, options) then
                imported = imported + 1
            end
        else
            skipped = skipped + 1
        end
    end

    return imported, skipped
end

local function importLegacyTables(db)
    local report = SavedVariables.migrationReport
    local _, playerClass = UnitClass and UnitClass("player")
    playerClass = playerClass or "OTHER"

    local alerts = ensureTable(db, "alerts")
    local playerAuras = ensureTable(alerts, "playerAuras")
    local targetAuras = ensureTable(alerts, "targetAuras")
    local spellCooldowns = ensureTable(alerts, "spellCooldowns")

    local imported, skipped
    if type(EA_Items) == "table" then
        imported, skipped = importSpellTable(playerAuras, EA_Items[playerClass], "aura", "player", "EA_Items")
        report.imported = report.imported + imported
        report.skipped = report.skipped + skipped
        imported, skipped = importSpellTable(playerAuras, EA_Items.OTHER, "aura", "player", "EA_Items")
        report.imported = report.imported + imported
        report.skipped = report.skipped + skipped
    end

    if type(EA_AltItems) == "table" then
        imported, skipped = importSpellTable(playerAuras, EA_AltItems[playerClass], "aura", "player", "EA_AltItems")
        report.imported = report.imported + imported
        report.skipped = report.skipped + skipped
    end

    if type(EA_TarItems) == "table" then
        imported, skipped = importSpellTable(targetAuras, EA_TarItems[playerClass], "aura", "target", "EA_TarItems")
        report.imported = report.imported + imported
        report.skipped = report.skipped + skipped
    end

    if type(EA_ScdItems) == "table" then
        imported, skipped = importSpellTable(spellCooldowns, EA_ScdItems[playerClass], "spellCooldown", "player", "EA_ScdItems")
        report.imported = report.imported + imported
        report.skipped = report.skipped + skipped
    end
end

function SavedVariables.initialize()
    EAM_DB = EAM_DB or {}
    if EAM_DB.schemaVersion ~= EAM.Constants.SCHEMA_VERSION then
        EAM_DB.schemaVersion = EAM.Constants.SCHEMA_VERSION
    end

    copyMissingDefaults(EAM_DB, defaults)

    -- 多框架升級相容與舊坐標遷移
    if EAM_DB.layout and type(EAM_DB.layout.frames) ~= "table" then
        EAM_DB.layout.frames = {}
        for fName, fDef in pairs(defaults.layout.frames) do
            EAM_DB.layout.frames[fName] = {
                growDirection = fDef.growDirection,
                x = fDef.x,
                y = fDef.y,
                point = fDef.point,
            }
        end
        -- 舊的全域坐標映射給自身光環 (selfAura)
        if EAM_DB.layout.x and EAM_DB.layout.y then
            EAM_DB.layout.frames.selfAura.x = EAM_DB.layout.x
            EAM_DB.layout.frames.selfAura.y = EAM_DB.layout.y
            EAM_DB.layout.frames.selfAura.point = EAM_DB.layout.point or "CENTER"
            EAM_DB.layout.x = nil
            EAM_DB.layout.y = nil
            EAM_DB.layout.point = nil
        end
    end

    importLegacyTables(EAM_DB)

    EAM.db = EAM_DB

    -- 🛡️ 載入預設監控法術 (全新安裝或無 WTF 檔案時之防空機制)
    if EAM_DB.alerts then
        local count = 0
        for _ in pairs(EAM_DB.alerts.playerAuras) do count = count + 1 break end
        for _ in pairs(EAM_DB.alerts.targetAuras) do count = count + 1 break end
        for _ in pairs(EAM_DB.alerts.spellCooldowns) do count = count + 1 break end
        for _ in pairs(EAM_DB.alerts.itemCooldowns) do count = count + 1 break end
        
        if count == 0 then
            local _, classToken = UnitClass("player")
            local spellArray = EAM.Data and EAM.Data.SpellArray
            local classData = classToken and spellArray and spellArray[classToken]
            if classData then
                -- 導入 general 預設法術
                if classData.general then
                    for _, sp in ipairs(classData.general) do
                        if sp.type == "aura" or sp.type == "spellCooldown" or sp.type == "itemCooldown" or sp.type == "groundEffect" then
                            SavedVariables.addAlert(sp.type, sp.unit, sp.id, nil)
                        end
                    end
                end
                -- 導入各專精預設法術
                for specIdx = 1, 4 do
                    local specList = classData[specIdx]
                    if specList then
                        for _, sp in ipairs(specList) do
                            if sp.type == "aura" or sp.type == "spellCooldown" or sp.type == "itemCooldown" or sp.type == "groundEffect" then
                                SavedVariables.addAlert(sp.type, sp.unit, sp.id, nil)
                            end
                        end
                    end
                end
            end
        end
    end

    return EAM_DB
end

function SavedVariables.buildAlertID(kind, unit, spellID, itemID)
    return buildAlertID(kind, unit, spellID, itemID)
end

function SavedVariables.getAlertList(kind, unit)
    return getAlertList(EAM.db, kind, unit)
end

function SavedVariables.addAlert(kind, unit, spellID, itemID, options)
    local db = EAM.db
    if type(db) ~= "table" then
        return false, "dbUnavailable"
    end

    spellID = spellID and normalizePositiveInteger(spellID) or nil
    itemID = itemID and normalizePositiveInteger(itemID) or nil
    local list = getAlertList(db, kind, unit)
    if not list then
        return false, "invalidKind"
    end

    local id = buildAlertID(kind, unit, spellID, itemID)
    if not id then
        return false, "invalidID"
    end

    if list[id] then
        list[id].enabled = true
        touchRevision(db)
        return true, id, "enabled"
    end

    list[id] = {
        id = id,
        kind = kind,
        spellID = spellID,
        itemID = itemID,
        unit = unit,
        enabled = true,
        fromPlayer = options and options.fromPlayer == true or nil,
    }
    touchRevision(db)
    return true, id, "added"
end

function SavedVariables.removeAlert(kind, unit, spellID, itemID)
    local db = EAM.db
    if type(db) ~= "table" then
        return false, "dbUnavailable"
    end

    spellID = spellID and normalizePositiveInteger(spellID) or nil
    itemID = itemID and normalizePositiveInteger(itemID) or nil
    local list = getAlertList(db, kind, unit)
    if not list then
        return false, "invalidKind"
    end

    local id = buildAlertID(kind, unit, spellID, itemID)
    if not id then
        return false, "invalidID"
    end

    if not list[id] then
        return false, "notFound"
    end

    list[id] = nil
    touchRevision(db)
    return true, id, "removed"
end

function SavedVariables.addAuraAlert(unit, spellID, options)
    return SavedVariables.addAlert(EAM.Constants.ALERT_KIND_AURA, unit or "player", spellID, nil, options)
end

function SavedVariables.removeAuraAlert(unit, spellID)
    return SavedVariables.removeAlert(EAM.Constants.ALERT_KIND_AURA, unit or "player", spellID, nil)
end

function SavedVariables.addSpellCooldownAlert(spellID, options)
    return SavedVariables.addAlert(EAM.Constants.ALERT_KIND_SPELL_COOLDOWN, "player", spellID, nil, options)
end

function SavedVariables.removeSpellCooldownAlert(spellID)
    return SavedVariables.removeAlert(EAM.Constants.ALERT_KIND_SPELL_COOLDOWN, "player", spellID, nil)
end

function SavedVariables.addItemCooldownAlert(itemID, options)
    return SavedVariables.addAlert(EAM.Constants.ALERT_KIND_ITEM_COOLDOWN, nil, nil, itemID, options)
end

function SavedVariables.removeItemCooldownAlert(itemID)
    return SavedVariables.removeAlert(EAM.Constants.ALERT_KIND_ITEM_COOLDOWN, nil, nil, itemID)
end
