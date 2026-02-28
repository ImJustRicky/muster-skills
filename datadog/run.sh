#!/usr/bin/env bash
set -eo pipefail

# Datadog event skill for muster
# Sends deploy events to the Datadog Events API.

if [[ -z "${MUSTER_DATADOG_API_KEY:-}" ]]; then
  echo "[datadog-skill] WARNING: MUSTER_DATADOG_API_KEY is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
SERVICE_NAME="${MUSTER_SERVICE_NAME:-$SERVICE}"
HOOK="${MUSTER_HOOK:-unknown}"
STATUS="${MUSTER_DEPLOY_STATUS:-unknown}"
TIMESTAMP=$(date +%s)

case "${HOOK}:${STATUS}" in
  post-deploy:success)
    TITLE="Deployed ${SERVICE_NAME}"
    TEXT="Service ${SERVICE_NAME} was successfully deployed."
    ALERT_TYPE="success"
    ;;
  post-deploy:failed)
    TITLE="Deploy failed: ${SERVICE_NAME}"
    TEXT="Service ${SERVICE_NAME} deploy failed."
    ALERT_TYPE="error"
    ;;
  post-deploy:skipped)
    TITLE="Deploy skipped: ${SERVICE_NAME}"
    TEXT="Service ${SERVICE_NAME} deploy was skipped."
    ALERT_TYPE="warning"
    ;;
  post-rollback:success)
    TITLE="Rolled back ${SERVICE_NAME}"
    TEXT="Service ${SERVICE_NAME} was rolled back."
    ALERT_TYPE="warning"
    ;;
  post-rollback:failed)
    TITLE="Rollback failed: ${SERVICE_NAME}"
    TEXT="Service ${SERVICE_NAME} rollback failed."
    ALERT_TYPE="error"
    ;;
  *)
    TITLE="Muster: ${HOOK} ${SERVICE_NAME}"
    TEXT="Hook ${HOOK} fired for service ${SERVICE_NAME} (status: ${STATUS})."
    ALERT_TYPE="info"
    ;;
esac

DD_SITE="${MUSTER_DATADOG_SITE:-datadoghq.com}"

PAYLOAD=$(cat <<EOF
{
  "title": "${TITLE}",
  "text": "${TEXT}",
  "date_happened": ${TIMESTAMP},
  "tags": ["service:${SERVICE}", "hook:${HOOK}", "status:${STATUS}"],
  "alert_type": "${ALERT_TYPE}",
  "source_type_name": "muster"
}
EOF
)

if ! curl -sf -X POST \
  -H "DD-API-KEY: ${MUSTER_DATADOG_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "https://api.${DD_SITE}/api/v1/events" > /dev/null 2>&1; then
  echo "[datadog-skill] WARNING: Failed to send Datadog event (curl error). Continuing."
fi

exit 0
