# muster-skills — Official Skill Marketplace

Community and first-party skill addons for the [muster](https://github.com/ImJustRicky/muster) deploy framework.

## Available Skills

| Skill | Description | Hooks | Config |
|-------|-------------|-------|--------|
| **slack** | Send deploy notifications to Slack via webhook | post-deploy, post-rollback | Webhook URL |
| **splunk** | Ship deploy events to Splunk via HEC | post-deploy, post-rollback | HEC URL + Token |
| **datadog** | Send deploy events to Datadog | post-deploy, post-rollback | API Key + Site |
| **discord** | Send deploy notifications to Discord + slash commands | post-deploy, post-rollback | Bot Token + Channel ID |

All skills are status-aware — they report success, failure, and skipped deploys with color-coded messages.

## Install from Marketplace

```sh
muster skill marketplace
```

Browse, search, install, and uninstall skills from the TUI. Or install directly:

```sh
muster skill marketplace slack
```

## Configure and Enable

After installing, configure and enable a skill:

```sh
muster skill configure slack    # enter your Slack webhook URL
muster skill enable slack       # auto-runs on deploy/rollback
```

Once enabled, the skill fires automatically during `muster deploy` and `muster rollback` — no manual intervention needed. Disable with `muster skill disable slack`.

## Environment Variables

Skills receive these env vars at runtime:

| Variable | Description |
|----------|-------------|
| `MUSTER_SERVICE` | Service key (e.g. `api`) |
| `MUSTER_SERVICE_NAME` | Display name (e.g. `API Server`) |
| `MUSTER_HOOK` | Hook name (`post-deploy`, `post-rollback`, etc.) |
| `MUSTER_DEPLOY_STATUS` | Outcome: `success`, `failed`, or `skipped` |
| `MUSTER_PROJECT_DIR` | Path to the project root |
| `MUSTER_CONFIG_FILE` | Path to deploy.json |

Plus any config values from the skill's `config.env`.

## Create Your Own Skill

See the [skill authoring guide](https://github.com/ImJustRicky/muster/blob/main/docs/skills.md) for full documentation.

Quick start:

```sh
muster skill create my-skill
# Edit ~/.muster/skills/my-skill/skill.json and run.sh
muster skill run my-skill
```

### Submit to the Marketplace

1. Fork this repo
2. Add your skill folder (`my-skill/skill.json` + `my-skill/run.sh`)
3. Add an entry to `registry.json`
4. Open a PR

Once merged, your skill appears in `muster skill marketplace` for everyone.

---

Apache 2.0 · Built by [ImJustRicky](https://github.com/ImJustRicky)
