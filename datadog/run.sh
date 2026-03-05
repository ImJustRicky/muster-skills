#!/usr/bin/env bash
set -eo pipefail

# Datadog event skill for muster
# Sends deploy events to the Datadog Events API v1.
# https://docs.datadoghq.com/api/latest/events/
#
# Required config:
#   MUSTER_DATADOG_API_KEY — Datadog API key
#   MUSTER_DATADOG_SITE    — Datadog site (default: datadoghq.com)
#
# Supports deploy/rollback hooks and fleet hooks.
# Fleet events include fleet name, machine, and strategy as tags.

if [[ -z "${MUSTER_DATADOG_API_KEY:-}" ]]; then
  echo "[datadog] No API key configured, skipping."
  exit 0
fi

# --- Context ---

HOOK="${MUSTER_HOOK:-unknown}"
STATUS="${MUSTER_DEPLOY_STATUS:-unknown}"
SERVICE="${MUSTER_SERVICE:-unknown}"
SERVICE_NAME="${MUSTER_SERVICE_NAME:-$SERVICE}"
FLEET="${MUSTER_FLEET_NAME:-}"
MACHINE="${MUSTER_FLEET_MACHINE:-}"
HOST="${MUSTER_FLEET_HOST:-}"
STRATEGY="${MUSTER_FLEET_STRATEGY:-}"
TIMESTAMP=$(date +%s)
DD_SITE="${MUSTER_DATADOG_SITE:-datadoghq.com}"

# --- Build event ---

ALERT_TYPE="info"
TITLE=""
TEXT=""

case "$HOOK" in
  # Fleet hooks
  fleet-deploy-end)
    if [[ "$STATUS" == "ok" ]]; then
      TITLE="Fleet deploy complete: ${FLEET}"
      TEXT="Fleet ${FLEET} deployed successfully (${STRATEGY})."
      ALERT_TYPE="success"
    else
      TITLE="Fleet deploy FAILED: ${FLEET}"
      TEXT="Fleet ${FLEET} deploy failed (${STRATEGY})."
      ALERT_TYPE="error"
    fi
    ;;
  fleet-machine-deploy-end)
    if [[ "$STATUS" == "ok" ]]; then
      TITLE="Deployed to ${MACHINE}"
      TEXT="Machine ${MACHINE} (${HOST}) deployed successfully."
      ALERT_TYPE="success"
    else
      TITLE="Deploy FAILED: ${MACHINE}"
      TEXT="Machine ${MACHINE} (${HOST}) deploy failed."
      ALERT_TYPE="error"
    fi
    ;;
  fleet-rollback-end)
    if [[ "$STATUS" == "ok" ]]; then
      TITLE="Fleet rollback complete: ${FLEET}"
      TEXT="Fleet ${FLEET} rolled back successfully."
      ALERT_TYPE="warning"
    else
      TITLE="Fleet rollback FAILED: ${FLEET}"
      TEXT="Fleet ${FLEET} rollback failed."
      ALERT_TYPE="error"
    fi
    ;;
  # Standard hooks
  post-deploy)
    case "$STATUS" in
      success)
        TITLE="Deployed ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} was successfully deployed."
        ALERT_TYPE="success"
        ;;
      failed)
        TITLE="Deploy failed: ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} deploy failed."
        ALERT_TYPE="error"
        ;;
      skipped)
        TITLE="Deploy skipped: ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} deploy was skipped."
        ALERT_TYPE="warning"
        ;;
      *)
        TITLE="Deploy ${STATUS}: ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} deploy status: ${STATUS}."
        ALERT_TYPE="info"
        ;;
    esac
    ;;
  post-rollback)
    case "$STATUS" in
      success)
        TITLE="Rolled back ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} was rolled back."
        ALERT_TYPE="warning"
        ;;
      failed)
        TITLE="Rollback failed: ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} rollback failed."
        ALERT_TYPE="error"
        ;;
      *)
        TITLE="Rollback ${STATUS}: ${SERVICE_NAME}"
        TEXT="Service ${SERVICE_NAME} rollback status: ${STATUS}."
        ALERT_TYPE="info"
        ;;
    esac
    ;;
  *)
    TITLE="Muster: ${HOOK}"
    TEXT="Hook ${HOOK} fired (status: ${STATUS})."
    ALERT_TYPE="info"
    ;;
esac

# --- Build tags ---

TAGS="\"service:${SERVICE}\",\"hook:${HOOK}\",\"status:${STATUS}\""
[[ -n "$FLEET" ]]    && TAGS="${TAGS},\"fleet:${FLEET}\""
[[ -n "$MACHINE" ]]  && TAGS="${TAGS},\"machine:${MACHINE}\""
[[ -n "$STRATEGY" ]] && TAGS="${TAGS},\"strategy:${STRATEGY}\""

# --- Escape for JSON ---

_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

PAYLOAD="{\"title\":\"$(_esc "$TITLE")\",\"text\":\"$(_esc "$TEXT")\",\"date_happened\":${TIMESTAMP},\"tags\":[${TAGS}],\"alert_type\":\"${ALERT_TYPE}\",\"source_type_name\":\"muster\"}"

# --- Send to Datadog Events API v1 ---

if ! curl -sf -X POST \
  -H "DD-API-KEY: ${MUSTER_DATADOG_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "https://api.${DD_SITE}/api/v1/events" > /dev/null 2>&1; then
  echo "[datadog] Failed to send event (curl error). Continuing."
fi

exit 0
