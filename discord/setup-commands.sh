#!/usr/bin/env bash
set -eo pipefail

# Discord slash command registration for muster
# Run this once to register /deploy, /status, and /rollback commands on your server.
#
# Usage: bash setup-commands.sh
#
# Requires MUSTER_DISCORD_BOT_TOKEN, MUSTER_DISCORD_APP_ID, and MUSTER_DISCORD_GUILD_ID
# to be set (via config.env or environment).
#
# NOTE: Registering commands is the easy part. To actually RECEIVE and handle
# slash command interactions, you need a web endpoint (Cloudflare Worker,
# AWS Lambda, etc.) that:
#   1. Verifies the Ed25519 signature from Discord
#   2. Responds with a deferred message (type 5) within 3 seconds
#   3. Triggers your muster deploy/rollback
#   4. PATCHes the deferred response with the result
#
# This script only registers the commands so they appear in Discord's UI.
# The notification skill (run.sh) works independently — it posts results
# to your channel after muster deploys/rollbacks, no slash commands needed.

if [[ -z "${MUSTER_DISCORD_BOT_TOKEN:-}" ]]; then
  echo "ERROR: MUSTER_DISCORD_BOT_TOKEN is not set."
  echo "  Configure it: muster skill configure discord"
  exit 1
fi

if [[ -z "${MUSTER_DISCORD_APP_ID:-}" ]]; then
  echo "ERROR: MUSTER_DISCORD_APP_ID is not set."
  echo "  Configure it: muster skill configure discord"
  exit 1
fi

if [[ -z "${MUSTER_DISCORD_GUILD_ID:-}" ]]; then
  echo "ERROR: MUSTER_DISCORD_GUILD_ID is not set."
  echo "  Configure it: muster skill configure discord"
  exit 1
fi

ENDPOINT="https://discord.com/api/v10/applications/${MUSTER_DISCORD_APP_ID}/guilds/${MUSTER_DISCORD_GUILD_ID}/commands"

echo "Registering slash commands for guild ${MUSTER_DISCORD_GUILD_ID}..."

# Bulk overwrite — idempotent, replaces all guild commands with this set.
# Uses a single /muster parent with subcommands (option type 1) so commands
# appear as /muster deploy, /muster status, /muster rollback in Discord's UI.
COMMANDS='[
  {
    "name": "muster",
    "type": 1,
    "description": "Muster deploy framework commands",
    "options": [
      {
        "name": "deploy",
        "description": "Trigger a deployment",
        "type": 1,
        "options": [
          {
            "name": "service",
            "description": "The service to deploy",
            "type": 3,
            "required": true
          }
        ]
      },
      {
        "name": "status",
        "description": "Check deployment status",
        "type": 1
      },
      {
        "name": "rollback",
        "description": "Rollback a service",
        "type": 1,
        "options": [
          {
            "name": "service",
            "description": "The service to rollback",
            "type": 3,
            "required": true
          }
        ]
      }
    ]
  }
]'

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  "$ENDPOINT" \
  -H "Authorization: Bot ${MUSTER_DISCORD_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$COMMANDS")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "OK — Slash commands registered:"
  echo "  /muster deploy <service>  — Trigger a deployment"
  echo "  /muster status            — Check deployment status"
  echo "  /muster rollback <service> — Rollback a service"
  echo ""
  echo "Commands are available in your Discord server now."
  echo ""
  echo "NOTE: These commands appear in Discord but won't do anything"
  echo "until you set up an Interactions Endpoint URL in the Discord"
  echo "developer portal pointing to a web server that handles them."
  echo "See: https://discord.com/developers/docs/interactions/overview"
else
  echo "ERROR: Failed to register commands (HTTP ${HTTP_CODE})"
  echo "$BODY"
  exit 1
fi
