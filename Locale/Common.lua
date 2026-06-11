--[[ EAM_FILE_COMMENTARY
EventAlertMod Retail Rewrite
Module: Locale/Common
檔案: Locale\Common.lua

理念:
- 建立 locale registry 與 fallback 機制，讓字串不再污染全域。
- 語系載入採 enUS fallback 加目前語系覆蓋。

責任:
- 建立 EAM.Locale、EAM.L、register/get helper 與 class/power static helper。

資料所有權:
- 擁有 EAM.L 字串表與 Locale helper tables。

可變狀態:
- EAM.L 可被 fallback/current locale 覆蓋；靜態 helper tables 可 freeze。

邊界:
- 語系模組不處理 UI 行為。
- 不寫 SavedVariables 或 runtime facts。

效能注意:
- 語系載入非 hot path；但 static helper 應保持穩定。

Retail API 注意:
- GetLocale/GetClassInfo/Enum.PowerType 需 Retail 12.x 可用；class/power 變更需更新文件。

]]
local _, EAM = ...

local api = EAM.API or {}
local freeze = EAM.Util and EAM.Util.tableFreeze or function(value)
    return value
end

local Locale = {
    current = GetLocale and GetLocale() or "enUS",
    fallback = "enUS",
}

EAM.Locale = Locale
EAM.L = EAM.L or {}

local classNames = {}
if GetNumClasses and GetClassInfo then
    for index = 1, GetNumClasses() do
        local classLocaleName, classFile = GetClassInfo(index)
        if classFile then
            classNames[classFile] = classLocaleName
        end
    end
end
classNames.OTHER = "OTHER"

Locale.ClassFile = freeze({
    DEATHKNIGHT = "DEATHKNIGHT",
    DEMONHUNTER = "DEMONHUNTER",
    DRUID = "DRUID",
    EVOKER = "EVOKER",
    HUNTER = "HUNTER",
    MAGE = "MAGE",
    MONK = "MONK",
    PALADIN = "PALADIN",
    PRIEST = "PRIEST",
    ROGUE = "ROGUE",
    SHAMAN = "SHAMAN",
    WARLOCK = "WARLOCK",
    WARRIOR = "WARRIOR",
    FUNKY = "FUNKY",
    OTHER = "OTHER",
})

Locale.ClassName = freeze(classNames)

local powerType = Enum and Enum.PowerType or {}
Locale.PowerType = freeze({
    MANA = powerType.Mana,
    RAGE = powerType.Rage,
    FOCUS = powerType.Focus,
    ENERGY = powerType.Energy,
    COMBO_POINTS = powerType.ComboPoints,
    RUNES = powerType.Runes,
    RUNIC_POWER = powerType.RunicPower,
    SOUL_SHARDS = powerType.SoulShards,
    LUNAR_POWER = powerType.LunarPower,
    HOLY_POWER = powerType.HolyPower,
    MAELSTROM = powerType.Maelstrom,
    CHI = powerType.Chi,
    INSANITY = powerType.Insanity,
    ARCANE_CHARGES = powerType.ArcaneCharges,
    FURY = powerType.Fury,
    PAIN = powerType.Pain,
    HAPPINESS = powerType.Happiness,
    ESSENCE = powerType.Essence,
})

Locale.CompareOptions = freeze({
    { text = "<", value = 1 },
    { text = "<=", value = 2 },
    { text = "=", value = 3 },
    { text = ">=", value = 4 },
    { text = ">", value = 5 },
    { text = "<>", value = 6 },
    { text = "*", value = 7 },
})

function Locale.register(locale, loader)
    if not loader then
        return
    end

    if locale == Locale.fallback or locale == Locale.current then
        loader(EAM.L)
    end
end

function Locale.get(key)
    return EAM.L[key] or key
end

