#!/usr/bin/env bash
# ===========================================================================
# scripts/audit_log.sh — Append a structured audit entry for destructive ops
#
# Usage (called from Makefile recipes):
#   source scripts/audit_log.sh
#   audit_log "target" "action" ["extra details"]
#
# Or standalone:
#   ./scripts/audit_log.sh log "target" "action"
#   ./scripts/audit_log.sh tail          Show last 20 entries
#   ./scripts/audit_log.sh summary       Show daily summary
#
# Log location: ~/.dotfiles-audit.log (append-only, human + machine readable)
# Format: JSON lines (one entry per operation)
# ===========================================================================

AUDIT_LOG_FILE="${DOTFILES_AUDIT_LOG:-$HOME/.dotfiles-audit.log}"

audit_log() {
  local target="${1:-unknown}"
  local action="${2:-run}"
  local details="${3:-}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local user
  user="${USER:-$(id -un)}"
  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"
  printf '{"ts":"%s","user":"%s","host":"%s","target":"%s","action":"%s","details":"%s"}\n' \
    "$ts" "$user" "$hostname" "$target" "$action" "$details" \
    >> "$AUDIT_LOG_FILE" 2>/dev/null || true
}

# Standalone invocations
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    log)
      shift
      audit_log "$@"
      ;;
    tail)
      if [ -f "$AUDIT_LOG_FILE" ]; then
        tail -20 "$AUDIT_LOG_FILE" | while IFS= read -r line; do
          ts=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ts'])" 2>/dev/null || echo "?")
          target=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['target'])" 2>/dev/null || echo "?")
          action=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['action'])" 2>/dev/null || echo "?")
          printf "  %s  %-25s  %s\n" "$ts" "$target" "$action"
        done
      else
        echo "  No audit log found at $AUDIT_LOG_FILE"
      fi
      ;;
    summary)
      if [ -f "$AUDIT_LOG_FILE" ]; then
        echo ""
        echo "  Audit Trail Summary (last 7 days)"
        echo "  ==================================="
        echo ""
        python3 -c "
import sys, json
from collections import defaultdict
counts = defaultdict(int)
with open('$AUDIT_LOG_FILE') as f:
    for line in f:
        try:
            d = json.loads(line)
            day = d['ts'][:10]
            counts[day + '|' + d['target']] += 1
        except: pass
for k in sorted(counts.keys())[-50:]:
    day, target = k.split('|', 1)
    print(f'  {day}  {target:<25}  x{counts[k]}')
print()
" 2>/dev/null || echo "  (python3 required for summary)"
      else
        echo "  No audit log found at $AUDIT_LOG_FILE"
      fi
      ;;
    *)
      echo "Usage: $0 log|tail|summary"
      exit 1
      ;;
  esac
fi
