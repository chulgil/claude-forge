#!/bin/bash
# work-tracker-sync.sh - Work Tracker 동기화 스크립트
# buffer.jsonl의 이벤트를 archive/로 이동 (+ Supabase 연동 옵션)
# LaunchAgent에서 1분 주기로 호출되거나, work-tracker-stop.sh에서 호출
#
# 모드:
#   - 로컬 전용 (기본): buffer → archive/{YYYY-MM-DD}.jsonl
#   - Supabase 연동: buffer → Supabase API → archive/ (SUPABASE_URL + SUPABASE_ANON_KEY 필요)

set -euo pipefail

WORK_LOG="$HOME/.claude/work-log"
BUFFER="$WORK_LOG/buffer.jsonl"
ARCHIVE_DIR="$WORK_LOG/archive"
LOCK_FILE="$WORK_LOG/.sync.lock"

# ─── 락 관리 ───
cleanup() { rm -f "$LOCK_FILE"; }
trap cleanup EXIT

if [ -f "$LOCK_FILE" ]; then
    # 5분 이상 된 락은 무시 (좀비 방지)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE") ))
    else
        lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE") ))
    fi
    if [ "$lock_age" -lt 300 ]; then
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"

# ─── 버퍼 확인 ───
if [ ! -f "$BUFFER" ] || [ ! -s "$BUFFER" ]; then
    exit 0
fi

mkdir -p "$ARCHIVE_DIR"

# ─── 버퍼 스냅샷 (원자적 읽기) ───
TEMP_BUFFER=$(mktemp)
mv "$BUFFER" "$TEMP_BUFFER"
touch "$BUFFER"

LINE_COUNT=$(wc -l < "$TEMP_BUFFER" | tr -d ' ')
if [ "$LINE_COUNT" -eq 0 ]; then
    rm -f "$TEMP_BUFFER"
    exit 0
fi

# ─── Supabase 동기화 (설정된 경우) ───
supabase_sync() {
    local url="${SUPABASE_URL:-}"
    local key="${SUPABASE_ANON_KEY:-}"

    if [ -z "$url" ] || [ -z "$key" ]; then
        return 1  # Supabase 미설정
    fi

    local endpoint="${url}/rest/v1/work_events"
    local payload
    payload=$(python3 -c "
import sys, json
events = []
for line in open('$TEMP_BUFFER'):
    line = line.strip()
    if line:
        events.append(json.loads(line))
print(json.dumps(events))
" 2>/dev/null)

    if [ -z "$payload" ] || [ "$payload" = "[]" ]; then
        return 1
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$endpoint" \
        -H "apikey: $key" \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$payload" \
        --connect-timeout 10 \
        --max-time 30)

    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Supabase 연동 시도 (실패해도 로컬 아카이브는 진행)
SUPABASE_OK=false
if supabase_sync 2>/dev/null; then
    SUPABASE_OK=true
fi

# ─── 로컬 아카이브 (항상 실행) ───
python3 -c "
import json, os
from collections import defaultdict

archive_dir = '$ARCHIVE_DIR'
buffer_path = '$TEMP_BUFFER'

# 날짜별 그룹핑
by_date = defaultdict(list)
for line in open(buffer_path):
    line = line.strip()
    if not line:
        continue
    try:
        rec = json.loads(line)
        ts = rec.get('ts', '')
        date_key = ts[:10] if len(ts) >= 10 else 'unknown'
        by_date[date_key].append(line)
    except:
        by_date['unknown'].append(line)

# 날짜별 파일에 append
for date_key, lines in by_date.items():
    archive_file = os.path.join(archive_dir, f'{date_key}.jsonl')
    with open(archive_file, 'a') as f:
        for l in lines:
            f.write(l + '\n')
" 2>/dev/null

# ─── 정리 ───
rm -f "$TEMP_BUFFER"

exit 0
