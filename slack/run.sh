#!/usr/bin/env bash
set -eo pipefail

# Slack notification skill for muster
# Sends deploy/rollback notifications to a Slack incoming webhook.

if [[ -z "${MUSTER_SLACK_WEBHOOK:-}" ]]; then
  echo "[slack-skill] WARNING: MUSTER_SLACK_WEBHOOK is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
SERVICE_NAME="${MUSTER_SERVICE_NAME:-$SERVICE}"
HOOK="${MUSTER_HOOK:-unknown}"
STATUS="${MUSTER_DEPLOY_STATUS:-unknown}"

case "${HOOK}:${STATUS}" in
  post-deploy:success)
    COLOR="#2eb886"
    TEXT=":white_check_mark: Deployed *${SERVICE_NAME}* successfully"
    ;;
  post-deploy:failed)
    COLOR="#e01e5a"
    TEXT=":x: Deploy failed for *${SERVICE_NAME}*"
    ;;
  post-deploy:skipped)
    COLOR="#e8a230"
    TEXT=":fast_forward: Deploy skipped for *${SERVICE_NAME}*"
    ;;
  post-rollback:success)
    COLOR="#e8a230"
    TEXT=":rewind: Rolled back *${SERVICE_NAME}* successfully"
    ;;
  post-rollback:failed)
    COLOR="#e01e5a"
    TEXT=":x: Rollback failed for *${SERVICE_NAME}*"
    ;;
  *)
    COLOR="#cccccc"
    TEXT="Hook \`${HOOK}\` fired for *${SERVICE_NAME}* (status: ${STATUS})"
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
