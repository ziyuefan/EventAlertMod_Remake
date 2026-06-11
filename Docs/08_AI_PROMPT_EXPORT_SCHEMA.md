# AI Prompt Export Schema

## Purpose

Debug export is on demand only. It exists to help a user or AI agent inspect
EAM state without dumping huge logs.

Modes:

- `debug-min`: compact state for quick support.
- `analysis-full`: detailed but bounded state for architecture/debug analysis.
- `github-issue`: user-readable issue payload.

## Required Separation

Export must separate:

- facts: direct, safe API data;
- derived: calculated UI/render state;
- human notes: user-readable comments;
- boundaryWarnings: secret/protected/unsafe data limitations;
- environment: build, locale, combat state, FPS, addon version.

Do not mix guessed values into facts.

## Compact Schema

```js
{
  schema: 1,
  mode: "debug-min|analysis-full|github-issue",
  environment: {
    addon: "EventAlertMod",
    addonVersion: "string?",
    interface: "number?",
    build: "string?",
    locale: "string?",
    inCombat: "boolean",
    fps: "number?",
    retailOnly: true
  },
  facts: {
    alertCount: "number",
    alerts: [
      {
        id: "string",
        kind: "aura|spellCooldown|itemCooldown",
        spellID: "number?",
        itemID: "number?",
        unit: "string?",
        name: "string?",
        icon: "number|string?",
        stacks: "number?",
        timerMode: "none|numeric|displayOnly|protected|unknown",
        active: "boolean",
        sourceAPI: "string?"
      }
    ]
  },
  derived: {
    visibleIcons: "number",
    dirtyQueues: { aura: "number", cooldown: "number", item: "number" },
    schedulerJobs: "number"
  },
  boundaryWarnings: [
    { id: "string?", code: "string", note: "string" }
  ],
  humanNotes: ["string"]
}
```

## Example

```js
{
  schema: 1,
  mode: "debug-min",
  environment: {
    addon: "EventAlertMod",
    interface: 120000,
    locale: "zhTW",
    inCombat: false,
    fps: 118,
    retailOnly: true
  },
  facts: {
    alertCount: 2,
    alerts: [
      {
        id: "aura:player:12345",
        kind: "aura",
        spellID: 12345,
        unit: "player",
        name: "Example Buff",
        timerMode: "numeric",
        active: true,
        sourceAPI: "C_UnitAuras"
      },
      {
        id: "spellCooldown:67890",
        kind: "spellCooldown",
        spellID: 67890,
        timerMode: "protected",
        active: true,
        sourceAPI: "C_Spell"
      }
    ]
  },
  derived: {
    visibleIcons: 2,
    dirtyQueues: { aura: 0, cooldown: 0, item: 0 },
    schedulerJobs: 1
  },
  boundaryWarnings: [
    {
      id: "spellCooldown:67890",
      code: "SPELL_COOLDOWN_SECRET",
      note: "Timer details unavailable; icon-only render used."
    }
  ],
  humanNotes: []
}
```

## Export Limits

- No automatic export.
- No unbounded aura lists.
- No full SavedVariables dumps by default.
- No combat-log spam.
- No large item cache dumps.
- String building happens only during explicit export command.
