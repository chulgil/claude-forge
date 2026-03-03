#!/bin/bash
# Task Completed Guard - TaskCompleted Hook
# 태스크 완료 시 로깅 + macOS/iTerm2 알림
#
# Hook trigger: TaskCompleted
# Exit codes: 0 = 승인 (완료 허용), 2 = 차단 (완료 거부, stderr로 피드백)

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# Read hook input JSON from stdin
INPUT=$(cat)

# 1. stderr 로깅 (기존)
echo "$INPUT" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
except:
    sys.exit(0)

ti = data.get('tool_input', {})
task_id = ti.get('task_id', 'unknown')
subject = ti.get('task_subject', ti.get('subject', 'unknown'))
teammate = ti.get('teammate_name', data.get('teammate_name', 'unknown'))
team = ti.get('team_name', data.get('team_name', 'unknown'))

print(f'[task-completed] Task #{task_id} \"{subject}\" completed by {teammate} (team: {team})', file=sys.stderr)
" 2>/dev/null

# 2. macOS/iTerm2 알림 전송
if [ -f "$HOOK_DIR/notify.sh" ]; then
    echo "$INPUT" | bash "$HOOK_DIR/notify.sh" 2>/dev/null &
fi

exit 0
