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
HOOK="${MUSTER_HOOK:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

case "$HOOK" in
  post-deploy)
    TITLE="Deployed ${SERVICE}"
    DESC="Service **${SERVICE}** was successfully deployed."
    # Green
    COLOR=3066993
    ;;
  post-rollback)
    TITLE="Rolled back ${SERVICE}"
    DESC="Service **${SERVICE}** was rolled back."
    # Orange
    COLOR=15105570
    ;;
  *)
    TITLE="Muster: ${HOOK}"
    DESC="Hook \`${HOOK}\` fired for **${SERVICE}**."
    # Gray
    COLOR=9807270
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
        {"name": "Service", "value": "${SERVICE}", "inline": true},
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
