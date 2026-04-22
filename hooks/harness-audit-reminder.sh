#!/bin/bash
# Harness Audit Reminder - SessionStart Hook
# Hints to run /harness-audit weekly to catch dead/duplicate/orphan rules & hooks

LAST_AUDIT_FILE="$HOME/.claude/homunculus/.last-audit"
NOW=$(date +%s)
LAST=0
[ -f "$LAST_AUDIT_FILE" ] && LAST=$(cat "$LAST_AUDIT_FILE" 2>/dev/null || echo 0)
DIFF_DAYS=$(( (NOW - LAST) / 86400 ))

if [ "$DIFF_DAYS" -ge 7 ]; then
  echo "[hint] /harness-audit 실행 권장 (마지막 감사: ${DIFF_DAYS}일 전)"
fi

exit 0
