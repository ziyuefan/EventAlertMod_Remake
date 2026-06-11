# State Schema

## SavedVariables Audit

Current TOCs declare these SavedVariables:

```lua
EA_Config
EA_Position
EA_Items
EA_AltItems
EA_TarItems
EA_ScdItems
EA_GrpItems
EA_Pos
```

Observed default/runtime companions:

```lua
EA_Config2
EA_ShowScrollSpells
EA_ShowScrollSpell_YPos
```

`EA_Config` currently stores display and behavior toggles such as frame
visibility, name/timer/flash display, sound, font sizes, alternate alerts,
target own-debuff filtering, cooldown behavior, rune display, and aura value
thresholds.

`EA_Position` stores anchor points, offsets, debuff color settings, target
layout flags, SCD offsets, execution icon settings, boss-level logic, and
cooldown display settings.

`EA_Items`, `EA_AltItems`, `EA_TarItems`, `EA_ScdItems`, and `EA_GrpItems`
store configured alert spell/item/group entries. Their current exact field
shape is legacy and should be migrated by a versioned manager, not frozen.

`EA_Pos` stores per-class shared position data through `G.Pos`.

## Current Global State Audit

Namespace:

```lua
_G.EventAlertMod
G -- addon namespace from ...
```

Major namespace runtime tables:

```lua
G.Pos
G.SPELLINFO_SELF
G.SPELLINFO_TARGET
G.SPELLINFO_SCD
G.ClassAltSpellName
G.GC_IndexOfGroupFrame
G.EA_CurrentBuffs
G.EA_TarCurrentBuffs
G.EA_ScdCurrentBuffs
G.EA_ShowScrollSpells
G.SpecFrame_LifeBloom
G.iconTextures
G.runeTextures
G.runeSetTexCoord
G.runeEnergizeTextures
G.runeColors
G.runeTypeText
G.RUNE_MAPPING
G.Auras
```

Global families:

```lua
EA_CLASS*
EA_SPELL_POWER*
EA_X*
EA_TTIP*
EX_XCLSALERT*
SLASH_EVENTALERTMOD1
SLASH_EVENTALERTMOD2
```

Major XML/UI globals:

```lua
EA_Main_Frame
EA_Version_Frame
EA_Options_Frame
EA_Icon_Options_Frame
EA_Class_Events_Frame
EA_Other_Events_Frame
EA_Target_Events_Frame
EA_SCD_Events_Frame
EA_Group_Events_Frame
EA_SpellCondition_Frame
EA_GroupEventSetting_Frame
EA_Anchor_Frame*
EA_MinimapOption
```

Notable accidental-global candidates found by assignment scan:

```lua
auraData, eaf, eaf2, EAEXF, EAItems, EASCDFrame, EA_icon, EA_rank,
EA_timeLeft, currentBuffs, startTime, duration, expirationTime, timeLeft,
usable, spellId, spellName, icon, frame, importButton, exportButton,
importFrame, exportFrame, MyAddonFrame, tempFunc
```

The rewrite should move these into module-owned local state or explicit
namespace fields.

## AlertState

```js
AlertState = {
  id: "string",
  kind: "aura|spellCooldown|itemCooldown",
  spellID: "number?",
  itemID: "number?",
  unit: "player|pet|target?",
  icon: "number|string?",
  name: "string?",
  stacks: "number?",
  timer: TimerState?,
  flags: AlertFlags,
  source: SourceState,
  boundaryWarnings: "array<string>?"
}
```

## TimerState

```js
TimerState = {
  mode: "none|numeric|displayOnly|protected|unknown",
  startTime: "number?",
  duration: "number?",
  expirationTime: "number?",
  timeLeft: "number?",
  displayText: "string?"
}
```

## AuraState

```js
AuraState = {
  alertID: "string",
  unit: "player|pet|target",
  auraInstanceID: "number?",
  spellID: "number?",
  name: "string?",
  icon: "number|string?",
  applications: "number?",
  fromPlayer: "boolean?",
  timer: TimerState,
  factsSafe: "boolean",
  boundaryWarnings: "array<string>?"
}
```

## CooldownState

```js
CooldownState = {
  alertID: "string",
  spellID: "number",
  name: "string?",
  icon: "number|string?",
  usable: "boolean?",
  charges: "number?",
  maxCharges: "number?",
  timer: TimerState,
  factsSafe: "boolean",
  boundaryWarnings: "array<string>?"
}
```

## ItemCooldownState

```js
ItemCooldownState = {
  alertID: "string",
  itemID: "number",
  linkedSpellID: "number?",
  name: "string?",
  icon: "number|string?",
  timer: TimerState,
  cacheStatus: "none|direct|pending|ready|throttled|combatBlocked",
  boundaryWarnings: "array<string>?"
}
```

## IconRenderState

```js
IconRenderState = {
  alertID: "string",
  visible: "boolean",
  texture: "number|string?",
  stackText: "string?",
  timerText: "string?",
  nameText: "string?",
  cooldown: { start: "number?", duration: "number?", enabled: "boolean?" },
  glow: "none|active|usable|warning",
  alpha: "number?",
  layoutKey: "string"
}
```

## DebugSnapshot

```js
DebugSnapshot = {
  schema: 1,
  addon: { name: "EventAlertMod", version: "string?", build: "number?" },
  environment: { retailOnly: true, inCombat: "boolean", fps: "number?" },
  facts: { alerts: "array<AlertState>" },
  derived: { icons: "array<IconRenderState>", dirtyQueues: "object" },
  boundaryWarnings: "array<object>",
  humanNotes: "array<string>"
}
```
