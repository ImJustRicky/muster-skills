# muster-skills — Official Skill Marketplace

Community and first-party skill addons for the [muster](https://github.com/Muster-dev/muster) deploy framework.

## Available Skills

| Skill | Description | Hooks | Config |
|-------|-------------|-------|--------|
| **discord** | Send deploy and fleet notifications to Discord | deploy, rollback, fleet | Bot Token + Channel ID |
| **slack** | Send deploy and fleet notifications to Slack | deploy, rollback, fleet | Webhook URL |
| **webhook** | Send deploy and fleet events to any HTTP endpoint | deploy, rollback, fleet | Endpoint URL |
| **datadog** | Send deploy and fleet events to Datadog | deploy, rollback, fleet | API Key + Site |
| **splunk** | Ship deploy and fleet events to Splunk via HEC | deploy, rollback, fleet | HEC URL + Token |

All skills support both local deploy hooks (`post-deploy`, `post-rollback`) and fleet hooks (`fleet-deploy-*`, `fleet-machine-deploy-*`, `fleet-rollback-*`).

## Install from Marketplace

```sh
muster skill marketplace
```

Browse, search, and install from the TUI. Or install directly:

```sh
muster skill marketplace slack
```

## Configure and Enable

After installing, configure and enable a skill:

```sh
muster skill configure slack    # enter your Slack webhook URL
muster skill enable slack       # auto-runs on deploy/rollback
```

Once enabled, the skill fires automatically during `muster deploy`, `muster rollback`, and `muster fleet deploy` — no manual intervention needed.

### Per-Fleet Config

Skills can have different config per fleet. For example, send production deploys to `#production-deploys` and staging to `#staging-deploys`:

```sh
muster fleet skill enable production discord
muster fleet skill configure production discord    # set production channel ID

muster fleet skill enable staging discord
muster fleet skill configure staging discord       # set staging channel ID
```

Fleet config overrides the skill's base config. Skills always execute on your machine — secrets never leave the orchestrator.

## Environment Variables

Skills receive these env vars at runtime:

| Variable | Description |
|----------|-------------|
| `MUSTER_SERVICE` | Service key (e.g. `api`) |
| `MUSTER_SERVICE_NAME` | Display name (e.g. `API Server`) |
| `MUSTER_HOOK` | Hook name (`post-deploy`, `fleet-deploy-end`, etc.) |
| `MUSTER_DEPLOY_STATUS` | Local: `success`, `failed`, `skipped`. Fleet: `ok`, `failed` |
| `MUSTER_PROJECT_DIR` | Path to the project root |
| `MUSTER_CONFIG_FILE` | Path to deploy.json |

### Fleet Environment Variables

Fleet hooks also get:

| Variable | Description |
|----------|-------------|
| `MUSTER_FLEET_NAME` | Fleet name (e.g. `production`) |
| `MUSTER_FLEET_MACHINE` | Machine identifier (per-machine hooks) |
| `MUSTER_FLEET_HOST` | `user@host` of the machine |
| `MUSTER_FLEET_STRATEGY` | `sequential`, `parallel`, or `rolling` |
| `MUSTER_FLEET_MODE` | `muster` or `push` |

Plus any config values from the skill's `config.env`.

## Fleet Hooks

| Hook | When it fires |
|------|---------------|
| `fleet-deploy-start` | Before fleet deploy begins (once) |
| `fleet-deploy-end` | After fleet deploy finishes (once) |
| `fleet-machine-deploy-start` | Before deploying to each machine |
| `fleet-machine-deploy-end` | After deploying to each machine |
| `fleet-rollback-start` | Before fleet rollback begins |
| `fleet-rollback-end` | After fleet rollback finishes |

## Create Your Own Skill

See the [skill authoring guide](https://github.com/Muster-dev/muster/blob/main/docs/skills/skills.md) for full documentation.

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

Apache 2.0 · Built by [Muster](https://github.com/Muster-dev)
