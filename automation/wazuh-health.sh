#!/usr/bin/env bash
# Simple Wazuh Docker health check for single-node stack

LOGFILE="/var/log/wazuh-health.log"
DATE="$(date -Iseconds)"

CONTAINERS=(
  "single-node-wazuh.manager-1"
  "single-node-wazuh.indexer-1"
  "single-node-wazuh.dashboard-1"
)

STATUS="OK"
DETAILS=()

for c in "${CONTAINERS[@]}"; do
  state=$(sudo docker ps --filter "name=${c}" --format '{{.Status}}')
  if [[ -z "$state" ]]; then
    STATUS="FAIL"
    DETAILS+=("${c}: not running")
  elif [[ "$state" != Up* ]]; then
    STATUS="FAIL"
    DETAILS+=("${c}: $state")
  fi
done

if ! curl -sk https://nas-homelab >/dev/null 2>&1; then
  [[ "$STATUS" == "OK" ]] && STATUS="WARN"
  DETAILS+=("Dashboard HTTPS check failed")
fi

printf '%s WAZUH_HEALTH %s %s\n' "$DATE" "$STATUS" "${DETAILS[*]}" \
  | sudo tee -a "$LOGFILE" >/dev/null

