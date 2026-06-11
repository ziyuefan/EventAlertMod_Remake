# Migration Notes

## Old Behavior Mapping

Preserve where feasible:

- self buff/debuff alert icons;
- target buff/debuff alert icons;
- spell cooldown alert icons;
- item cooldown alert icons by itemID;
- easy spellID add/remove workflow;
- `/eam opt` settings entry point;
- `/eam show`, `/eam showt`, `/eam showc`, `/eam showa` detection workflows;
- cooldown behavior toggles:
  - remove when cooldown completes;
  - keep cooldown icons out of combat;
  - glow when usable;
- icon display toggles:
  - show frame;
  - show name;
  - show timer;
  - show flash/glow;
  - tooltip append spell/item ID;
- font size controls for name, timer, and stacks;
- minimap option button semantics;
- localization strings, especially zhTW, enUS, koKR, zhCN where present;
- useful default spell/item tables after Retail validation.

## Old SavedVariables Migration

Legacy inputs:

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

Target migration:

```js
EventAlertModDB = {
  schemaVersion: 1,
  profile: {
    display: {},
    behavior: {},
    alerts: {
      playerAuras: [],
      targetAuras: [],
      spellCooldowns: [],
      itemCooldowns: [],
      groupAlerts: []
    },
    layout: {}
  },
  migration: {
    fromLegacy: true,
    sourceKeys: [],
    warnings: []
  }
}
```

The exact target variable name is a rewrite decision. If the old variable names
remain for compatibility, they still need schema markers and migration status.

Migration rules:

- never freeze migrated SavedVariables;
- never store runtime state in SavedVariables;
- preserve unknown legacy fields under a migration-safe extension table or
  warning list;
- validate spellID/itemID numeric fields;
- record removed Classic-only fields as migration warnings;
- do not delete old fields until a backup or migration confidence strategy is
  defined.

## Removed Old Behaviors

Remove from active Retail architecture:

- Classic, TBC, Wrath, Cata, Mists TOCs and load roots;
- `G.WOW_VERSION` branches for Classic behavior;
- old unpacked return compatibility layers for Classic APIs;
- old hunter pet happiness/focus branches that only exist for Classic-era
  behavior;
- huge normal-runtime item ID scans;
- timer-per-icon and timer-per-spell refresh chains;
- tooltip scanning as normal fact source;
- external dependency requirement for core operation.

## Compatibility Breaks

Expected breaks:

- old Classic TOCs no longer load;
- users relying on legacy Classic-specific resources lose those alerts;
- group-event scripting/configuration may need simplification;
- import/export prototype must be redesigned or removed unless a simple safe
  path is needed;
- `Lib_ZYF` helpers should be replaced or isolated; do not assume it exists in
  the new core.

## Localization Migration

Existing locale files:

- `locale/localization.comm.lua`
- `locale/localization.en.lua`
- `locale/localization.tw.lua`
- `locale/localization.cn.lua`
- `locale/localization.kr.lua`
- `locale/localization.ru.lua`

Keep localization isolated. Do not mix strings into logic modules. Do not add
Simplified Chinese strings to zhTW.

## Legacy Source Handling

Current old source roots remain for audit/reference:

- `Classic/`
- `TBC/`
- `Wrath/`

They should not be loaded by the Retail rewrite. If retained in the repository,
mark them archived/unsupported.
