#!/bin/bash
# notify.sh — macOS/iTerm2 통합 알림 훅
# Claude Code 이벤트 발생 시 네이티브 알림 전송
#
# 사용법 (다른 훅에서 호출):
#   source "$(dirname "$0")/notify.sh"
#   forge_notify "작업 완료" "빌드 성공: my-project" "success"
#
# 직접 실행 (Claude Code 훅으로):
#   stdin으로 훅 JSON을 받아 알림 전송
#
# 알림 타입: success, error, info, warning

NOTIFY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──────────────────────────────────────────────
# 알림 전송 함수
# ──────────────────────────────────────────────
forge_notify() {
    local title="${1:-Claude Code}"
    local message="${2:-작업이 완료되었습니다}"
    local type="${3:-info}"  # success, error, info, warning
    local sound="${4:-}"     # 빈 값이면 기본 소리

    # 1. macOS 네이티브 알림 (terminal-notifier 우선)
    if command -v terminal-notifier &>/dev/null; then
        local tn_sound=""
        case "$type" in
            success) tn_sound="Glass" ;;
            error)   tn_sound="Basso" ;;
            warning) tn_sound="Purr" ;;
            *)       tn_sound="Pop" ;;
        esac
        [ -n "$sound" ] && tn_sound="$sound"

        terminal-notifier \
            -title "$title" \
            -message "$message" \
            -sound "$tn_sound" \
            -group "claude-forge" \
            -sender "com.googlecode.iterm2" \
            2>/dev/null &
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Fallback: osascript (기본 macOS)
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null &
    elif command -v notify-send &>/dev/null; then
        # Linux fallback
        local urgency="normal"
        [ "$type" = "error" ] && urgency="critical"
        notify-send -u "$urgency" "$title" "$message" 2>/dev/null &
    fi

    # 2. iTerm2 배지 업데이트 (Shell Integration)
    if [ -n "$ITERM_SESSION_ID" ]; then
        # 배지 텍스트 설정
        printf "\033]1337;SetBadgeFormat=%s\a" \
            "$(echo -n "$message" | head -c 30 | base64)" 2>/dev/null

        # 벨 (알림 트리거 발동용)
        printf "\a" 2>/dev/null
    fi

    # 3. tmux 알림 (tmux 세션 내인 경우)
    if [ -n "$TMUX" ]; then
        tmux display-message "🔔 $title: $message" 2>/dev/null
    fi
}

# ──────────────────────────────────────────────
# 배지 초기화 함수
# ──────────────────────────────────────────────
forge_badge_clear() {
    if [ -n "$ITERM_SESSION_ID" ]; then
        printf "\033]1337;SetBadgeFormat=\a" 2>/dev/null
    fi
}

# ──────────────────────────────────────────────
# Claude Code 훅으로 직접 실행 시
# ──────────────────────────────────────────────
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    INPUT=$(cat)

    # 훅 이벤트에서 정보 추출
    HOOK_EVENT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # TaskCompleted 이벤트
    ti = data.get('tool_input', {})
    task_id = ti.get('task_id', ti.get('taskId', ''))
    subject = ti.get('task_subject', ti.get('subject', ''))
    teammate = ti.get('teammate_name', data.get('teammate_name', ''))
    tool = data.get('tool_name', '')
    event = data.get('hook_event', data.get('event', ''))

    if subject:
        print(f'task|{subject}|{teammate}')
    elif event == 'Stop':
        print('stop||')
    else:
        print(f'tool|{tool}|')
except:
    print('unknown||')
" 2>/dev/null)

    IFS='|' read -r EVENT_TYPE EVENT_DETAIL EVENT_ACTOR <<< "$HOOK_EVENT"

    case "$EVENT_TYPE" in
        task)
            forge_notify \
                "Claude: 작업 완료" \
                "✅ ${EVENT_DETAIL}${EVENT_ACTOR:+ (by $EVENT_ACTOR)}" \
                "success"
            ;;
        stop)
            forge_notify \
                "Claude Code" \
                "세션이 종료되었습니다" \
                "info" \
                "Purr"
            ;;
        *)
            # 기본: 조용히 무시
            ;;
    esac

    exit 0
fi
