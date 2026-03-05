#!/usr/bin/env bash
set -eo pipefail

# Splunk HEC skill for muster
# Ships structured deploy and fleet events to Splunk HTTP Event Collector.
# https://docs.splunk.com/Documentation/Splunk/latest/Data/UsetheHTTPEventCollector
#
# Required config:
#   MUSTER_SPLUNK_HEC_URL   — HEC endpoint URL
#   MUSTER_SPLUNK_HEC_TOKEN — HEC authentication token
#
# Supports deploy/rollback hooks and fleet hooks.
# Fleet events include fleet name, machine, host, and strategy fields.

if [[ -z "${MUSTER_SPLUNK_HEC_URL:-}" ]]; then
  echo "[splunk] No HEC URL configured, skipping."
  exit 0
fi

if [[ -z "${MUSTER_SPLUNK_HEC_TOKEN:-}" ]]; then
  echo "[splunk] No HEC token configured, skipping."
  exit 0
fi

# --- Context ---

SERVICE="${MUSTER_SERVICE:-unknown}"
SERVICE_NAME="${MUSTER_SERVICE_NAME:-$SERVICE}"
HOOK="${MUSTER_HOOK:-unknown}"
STATUS="${MUSTER_DEPLOY_STATUS:-unknown}"
FLEET="${MUSTER_FLEET_NAME:-}"
MACHINE="${MUSTER_FLEET_MACHINE:-}"
HOST="${MUSTER_FLEET_HOST:-}"
STRATEGY="${MUSTER_FLEET_STRATEGY:-}"
TIMESTAMP=$(date +%s)
HOSTNAME_VAL=$(hostname)

# --- Build event JSON ---

_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

EVENT="{\"service\":\"$(_esc "$SERVICE")\",\"service_name\":\"$(_esc "$SERVICE_NAME")\",\"hook\":\"$(_esc "$HOOK")\",\"status\":\"$(_esc "$STATUS")\",\"hostname\":\"$(_esc "$HOSTNAME_VAL")\""

# Add fleet context if present
if [[ -n "$FLEET" ]]; then
  EVENT="${EVENT},\"fleet\":\"$(_esc "$FLEET")\""
  [[ -n "$MACHINE" ]]  && EVENT="${EVENT},\"machine\":\"$(_esc "$MACHINE")\""
  [[ -n "$HOST" ]]     && EVENT="${EVENT},\"host\":\"$(_esc "$HOST")\""
  [[ -n "$STRATEGY" ]] && EVENT="${EVENT},\"strategy\":\"$(_esc "$STRATEGY")\""
fi

EVENT="${EVENT}}"

PAYLOAD="{\"event\":${EVENT},\"sourcetype\":\"muster:deploy\",\"time\":${TIMESTAMP}}"

# --- Send to Splunk HEC ---

if ! curl -sf -X POST \
  -H "Authorization: Splunk ${MUSTER_SPLUNK_HEC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "${MUSTER_SPLUNK_HEC_URL}" > /dev/null 2>&1; then
  echo "[splunk] Failed to send event (curl error). Continuing."
fi

exit 0
