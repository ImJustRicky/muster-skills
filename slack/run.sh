#!/usr/bin/env bash
set -eo pipefail

# Slack notification skill for muster
# Sends deploy/rollback notifications to a Slack incoming webhook.

if [[ -z "$MUSTER_SLACK_WEBHOOK" ]]; then
  echo "[slack-skill] WARNING: MUSTER_SLACK_WEBHOOK is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
HOOK="${MUSTER_HOOK:-unknown}"

case "$HOOK" in
  post-deploy)
    COLOR="#2eb886"
    TEXT="Deployed *${SERVICE}*"
    ;;
  post-rollback)
    COLOR="#e8a230"
    TEXT="Rolled back *${SERVICE}*"
    ;;
  *)
    COLOR="#cccccc"
    TEXT="Hook \`${HOOK}\` fired for *${SERVICE}*"
    ;;
esac

PAYLOAD=$(cat <<EOF
{
  "attachments": [
    {
      "color": "${COLOR}",
      "text": "${TEXT}",
      "fallback": "${TEXT}",
      "ts": $(date +%s)
    }
  ]
}
EOF
)

if ! curl -sf -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$MUSTER_SLACK_WEBHOOK" > /dev/null 2>&1; then
  echo "[slack-skill] WARNING: Failed to send Slack notification (curl error). Continuing."
fi

exit 0
