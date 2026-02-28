#!/usr/bin/env bash
set -eo pipefail

# Splunk HEC notification skill for muster
# Ships structured deploy events to Splunk HTTP Event Collector.

if [[ -z "$MUSTER_SPLUNK_HEC_URL" ]]; then
  echo "[splunk-skill] WARNING: MUSTER_SPLUNK_HEC_URL is not set, skipping notification."
  exit 0
fi

if [[ -z "$MUSTER_SPLUNK_HEC_TOKEN" ]]; then
  echo "[splunk-skill] WARNING: MUSTER_SPLUNK_HEC_TOKEN is not set, skipping notification."
  exit 0
fi

SERVICE="${MUSTER_SERVICE:-unknown}"
HOOK="${MUSTER_HOOK:-unknown}"
TIMESTAMP=$(date +%s)
HOSTNAME=$(hostname)

PAYLOAD=$(cat <<EOF
{
  "event": {
    "service": "${SERVICE}",
    "hook": "${HOOK}",
    "timestamp": ${TIMESTAMP},
    "hostname": "${HOSTNAME}"
  },
  "sourcetype": "muster:deploy",
  "time": ${TIMESTAMP}
}
EOF
)

if ! curl -sf -X POST \
  -H "Authorization: Splunk ${MUSTER_SPLUNK_HEC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "${MUSTER_SPLUNK_HEC_URL}" > /dev/null 2>&1; then
  echo "[splunk-skill] WARNING: Failed to send Splunk event (curl error). Continuing."
fi

exit 0
