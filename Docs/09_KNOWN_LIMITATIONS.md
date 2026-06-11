# Known Limitations

## Live Validation Gap

This audit was static. No WoW Retail 12.x client was available, so API names,
return shapes, secret/protected behavior, and XML runtime behavior still require
in-game validation.

## Secret / Protected Values

Retail may return secret, protected, display-only, or unavailable data for aura
and cooldown state. The rewrite must degrade safely:

- icon-only display;
- known-safe name/icon/stacks only;
- timer mode `protected`, `displayOnly`, or `unknown`;
- no fabricated duration/expiration/cooldown facts;
- debug boundary warning only when debug/export is requested.

## Combat Restrictions

Some UI or data updates may be unsafe or unavailable in combat. Heavy work,
cache building, layout rebuilding, and migration-like operations must be delayed
or throttled.

## Unsupported Branches

The rewrite does not support:

- Classic
- Mists Classic
- Cata Classic
- Wrath Classic
- TBC Classic
- Era
- region-specific Classic compatibility branches

Legacy directories may remain in the repository as reference only.

## Current Source Risks

First-pass audit found these risks:

- mixed Retail and legacy compatibility branches in Mainline;
- legacy TOCs still present at root;
- `Lib_ZYF` required by current TOC and many runtime modules;
- large spell/item data tables;
- item range scans in `EventAlert_ItemSpellCache.lua`;
- recursive timer scheduling and per-resource OnUpdate scripts;
- broad global variable usage and accidental globals;
- tooltip and aura API assumptions that may conflict with protected data;
- duplicated/archived files with garbled names under `Main/` and
  `DevDocument/ChatGPT/`;
- `EventAlert_ImportExport.lua` has prototype globals and is commented out of
  load order.

## UI Limitations

Current XML creates large static option panels and many global frame names. The
rewrite should prefer a smaller options surface and pooled runtime icons, but
existing UI behavior must be mapped before removal.

## Areas Requiring Retail Validation

- exact `C_UnitAuras` safe access behavior;
- exact `C_Spell.GetSpellCooldown` structured return behavior;
- exact `C_Item.GetItemCooldown` direct itemID behavior;
- `C_Secrets` availability and return behavior;
- cooldown charge behavior;
- target aura update payloads;
- combat restrictions for all planned UI operations;
- tooltip APIs if tooltip display is preserved;
- localization rendering in zhTW/enUS/koKR/zhCN;
- SavedVariables migration with real legacy user data.
