#!/usr/bin/env bash
set -eo pipefail

# Discord notification skill for muster
# Sends deploy/rollback notifications as rich embeds to a Discord channel.

if [[ -z "${MUSTER_DISCORD_BOT_TOKEN:-}" ]]; then
  echo "[discord-skill] WARNING: MUSTER_DISCORD_BOT_TOKEN is not set, skipping notification."
  exit 0
fi

if [[ -z "${MUSTER_DISCORD_CHANNEL_ID:-}" ]]; then
  echo "[discord-skill] WARNING: MUSTER_DISCORD_CHANNEL_ID is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
SERVICE_NAME="${MUSTER_SERVICE_NAME:-$SERVICE}"
HOOK="${MUSTER_HOOK:-unknown}"
STATUS="${MUSTER_DEPLOY_STATUS:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

case "${HOOK}:${STATUS}" in
  post-deploy:success)
    TITLE="Deployed ${SERVICE_NAME}"
    DESC="Service **${SERVICE_NAME}** was successfully deployed."
    COLOR=3066993  # green
    ;;
  post-deploy:failed)
    TITLE="Deploy FAILED: ${SERVICE_NAME}"
    DESC="Service **${SERVICE_NAME}** deploy failed."
    COLOR=15158332  # red
    ;;
  post-deploy:skipped)
    TITLE="Deploy skipped: ${SERVICE_NAME}"
    DESC="Service **${SERVICE_NAME}** was skipped."
    COLOR=15105570  # orange
    ;;
  post-rollback:success)
    TITLE="Rolled back ${SERVICE_NAME}"
    DESC="Service **${SERVICE_NAME}** was rolled back."
    COLOR=15105570  # orange
    ;;
  post-rollback:failed)
    TITLE="Rollback FAILED: ${SERVICE_NAME}"
    DESC="Service **${SERVICE_NAME}** rollback failed."
    COLOR=15158332  # red
    ;;
  *)
    TITLE="Muster: ${HOOK}"
    DESC="Hook \`${HOOK}\` fired for **${SERVICE_NAME}** (status: ${STATUS})."
    COLOR=9807270  # gray
    ;;
esac

PAYLOAD=$(cat <<EOF
{
  "embeds": [
    {
      "title": "${TITLE}",
      "description": "${DESC}",
      "color": ${COLOR},
      "fields": [
        {"name": "Service", "value": "${SERVICE_NAME}", "inline": true},
        {"name": "Status", "value": "${STATUS}", "inline": true},
        {"name": "Hook", "value": "${HOOK}", "inline": true}
      ],
      "footer": {"text": "muster deploy bot"},
      "timestamp": "${TIMESTAMP}"
    }
  ]
}
EOF
)

if ! curl -sf -X POST \
  "https://discord.com/api/v10/channels/${MUSTER_DISCORD_CHANNEL_ID}/messages" \
  -H "Authorization: Bot ${MUSTER_DISCORD_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" > /dev/null 2>&1; then
  echo "[discord-skill] WARNING: Failed to send Discord notification (curl error). Continuing."
fi

exit 0
