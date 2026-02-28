#!/usr/bin/env bash
set -eo pipefail

# Datadog event skill for muster
# Sends deploy events to the Datadog Events API.

if [[ -z "$MUSTER_DATADOG_API_KEY" ]]; then
  echo "[datadog-skill] WARNING: MUSTER_DATADOG_API_KEY is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
HOOK="${MUSTER_HOOK:-unknown}"
TIMESTAMP=$(date +%s)

case "$HOOK" in
  post-deploy)
    TITLE="Deployed ${SERVICE}"
    TEXT="Service ${SERVICE} was successfully deployed."
    ALERT_TYPE="success"
    ;;
  post-rollback)
    TITLE="Rolled back ${SERVICE}"
    TEXT="Service ${SERVICE} was rolled back."
    ALERT_TYPE="warning"
    ;;
  *)
    TITLE="Muster hook ${HOOK} for ${SERVICE}"
    TEXT="Hook ${HOOK} fired for service ${SERVICE}."
    ALERT_TYPE="info"
    ;;
esac

PAYLOAD=$(cat <<EOF
{
  "title": "${TITLE}",
  "text": "${TEXT}",
  "date_happened": ${TIMESTAMP},
  "tags": ["service:${SERVICE}", "hook:${HOOK}"],
  "alert_type": "${ALERT_TYPE}",
  "source_type_name": "muster"
}
EOF
)

if ! curl -sf -X POST \
  -H "DD-API-KEY: ${MUSTER_DATADOG_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "https://api.datadoghq.com/api/v1/events" > /dev/null 2>&1; then
  echo "[datadog-skill] WARNING: Failed to send Datadog event (curl error). Continuing."
fi

exit 0
