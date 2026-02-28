# muster-skills -- Official Skill Addons

Community and first-party skill addons for the [muster](https://github.com/ImJustRicky/muster) deploy framework.

## Available Skills

| Skill | Description | Install |
|-------|-------------|---------|
| **slack** | Send deploy notifications to Slack via webhook | `muster skill add slack` |
| **splunk** | Ship deploy events to Splunk via HEC | `muster skill add splunk` |
| **datadog** | Send deploy events to Datadog | `muster skill add datadog` |

## Installation

Browse and install skills from the marketplace:

```sh
muster skill marketplace
```

Or add the entire skills repo as a source:

```sh
muster skill add https://github.com/ImJustRicky/muster-skills
```

## Authoring Your Own Skills

See the [skill authoring guide](https://github.com/ImJustRicky/muster/blob/main/docs/skills.md) in the main muster repository for instructions on creating custom skills.

---

Apache 2.0 · Built by Ricky Eipper
