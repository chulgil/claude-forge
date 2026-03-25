#!/bin/bash
# Pre-Push Security Gate - PreToolUse Hook (Bash)
# git push 명령 감지 시 변경 파일에 대한 빠른 보안 스캔 수행
# 참조: reference/appsec-patterns-ref.md
#
# Hook trigger: PreToolUse, matcher: Bash
# Exit codes: 0 = 허용, 2 = 차단 (Critical 시크릿 감지 시)

INPUT=$(cat)

# git push 명령인지 확인
COMMAND=$(echo "$INPUT" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("command", ""))
except:
    pass
' 2>/dev/null)

# git push가 아니면 즉시 통과
if ! echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
    exit 0
fi

# 세션당 1회만 실행 (같은 push 재시도 시 스킵)
MARKER="/tmp/pre-push-security-$$"
if [[ -f "$MARKER" ]]; then
    exit 0
fi

# Python으로 보안 스캔 실행
export _PUSH_CMD="$COMMAND"
python3 << 'SCAN_SCRIPT'
import os
import sys
import re
import subprocess
import math
from collections import Counter

def shannon_entropy(data):
    """Shannon 엔트로피 계산"""
    if not data or len(data) < 20:
        return 0
    entropy = 0
    for count in Counter(data).values():
        p = count / len(data)
        entropy -= p * math.log2(p)
    return entropy

def classify_risk(filepath):
    """파일 리스크 분류"""
    path_lower = filepath.lower()
    HIGH_PATTERNS = [
        r'auth', r'login', r'session', r'token', r'jwt', r'oauth',
        r'password', r'payment', r'crypto', r'encrypt', r'hash',
        r'admin', r'credential', r'secret',
    ]
    MEDIUM_PATTERNS = [
        r'api/', r'route', r'middleware', r'config',
        r'upload', r'download', r'redirect', r'\.env',
    ]
    LOW_PATTERNS = [
        r'\.md$', r'\.txt$', r'test', r'spec', r'__test__',
        r'docs/', r'static/', r'README', r'CHANGELOG',
    ]
    for pat in HIGH_PATTERNS:
        if re.search(pat, path_lower):
            return 'HIGH'
    for pat in MEDIUM_PATTERNS:
        if re.search(pat, path_lower):
            return 'MEDIUM'
    for pat in LOW_PATTERNS:
        if re.search(pat, path_lower):
            return 'LOW'
    return 'MEDIUM'

# 변경 파일 목록 가져오기
try:
    result = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', 'HEAD~1'],
        capture_output=True, text=True, timeout=10
    )
    if result.returncode != 0:
        result = subprocess.run(
            ['git', 'diff', '--name-only', 'HEAD~1'],
            capture_output=True, text=True, timeout=10
        )
    changed_files = [f for f in result.stdout.strip().split('\n') if f]
except Exception:
    sys.exit(0)

if not changed_files:
    sys.exit(0)

# 파일 분류
classified = {'HIGH': [], 'MEDIUM': [], 'LOW': []}
for f in changed_files:
    risk = classify_risk(f)
    classified[risk].append(f)

# 시크릿 감지 패턴
SECRET_PATTERNS = [
    (r'(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}', "AWS Access Key"),
    (r'AIza[0-9A-Za-z\-_]{35}', "Google API Key"),
    (r'gh[pousr]_[A-Za-z0-9_]{36,255}', "GitHub Token"),
    (r'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,32}', "Slack Token"),
    (r'(?i)(sk|pk)_(test|live)_[0-9a-zA-Z]{24,}', "Stripe Key"),
    (r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----', "Private Key"),
    (r'(?i)(mysql|postgresql|mongodb|redis)://[^\s]+:[^\s]+@', "DB URL with Credentials"),
]

# CWE-798 오탐 허용 목록: localStorage 키 이름, 환경변수 키 이름 등
CWE798_ALLOWLIST = [
    r'ACCESS_TOKEN',
    r'REFRESH_TOKEN',
    r'KEY_\w+',
    r'STORAGE_KEY',
    r'TOKEN_TYPE',
    r'Bearer',
]
CWE798_ALLOWLIST_PATTERN = re.compile('|'.join(CWE798_ALLOWLIST))

# CWE 위험 패턴 (HIGH/MEDIUM 파일에만 적용)
CWE_PATTERNS = [
    (r'(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*["\'][a-zA-Z0-9!@#$%^&*()_+=\-]{8,}["\']', "CWE-798: Hardcoded Credential"),
    (r'eval\s*\(', "CWE-78: Potential Code Injection"),
    (r'innerHTML\s*=', "CWE-79: Potential XSS"),
    (r'dangerouslySetInnerHTML', "CWE-79: React XSS Risk"),
    (r'\.query\s*\(\s*[\x60f"\'].*\$\{', "CWE-89: Potential SQL Injection"),
    (r'os\.system\s*\(', "CWE-78: OS Command Execution"),
    (r'subprocess.*shell\s*=\s*True', "CWE-78: Shell Injection Risk"),
    (r'pickle\.loads?\s*\(', "CWE-502: Unsafe Deserialization"),
    (r'yaml\.load\s*\((?!.*safe)', "CWE-502: Unsafe YAML Load"),
]

# 엔트로피 기반 시크릿 감지용 변수명 패턴
SECRET_VAR_PATTERN = re.compile(
    r'(?i)(key|secret|token|password|credential|auth|api_key|apikey)\s*[:=]\s*["\']([^"\']{20,})["\']'
)

findings = []
critical_count = 0
high_count = 0
medium_count = 0

# 스캔할 파일 결정 (HIGH + MEDIUM만, LOW는 시크릿만)
scan_files = classified['HIGH'] + classified['MEDIUM']
all_files = scan_files + classified['LOW']

for filepath in all_files:
    try:
        result = subprocess.run(
            ['git', 'show', f'HEAD:{filepath}'],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            continue
        content = result.stdout
    except Exception:
        continue

    # 시크릿 패턴 스캔 (모든 파일)
    for pattern, desc in SECRET_PATTERNS:
        matches = re.findall(pattern, content)
        if matches:
            findings.append(('CRITICAL', filepath, desc))
            critical_count += 1

    # CWE 패턴 스캔 (HIGH/MEDIUM 파일만)
    if filepath in scan_files:
        for pattern, desc in CWE_PATTERNS:
            matches_cwe = re.finditer(pattern, content)
            for m in matches_cwe:
                matched_text = m.group(0)
                # CWE-798 오탐 허용 목록 체크
                if 'CWE-798' in desc and CWE798_ALLOWLIST_PATTERN.search(matched_text):
                    continue
                severity = 'CRITICAL' if 'CWE-798' in desc else 'HIGH'
                findings.append((severity, filepath, desc))
                if severity == 'CRITICAL':
                    critical_count += 1
                else:
                    high_count += 1
                break  # 같은 패턴은 파일당 1번만 보고

    # 엔트로피 기반 시크릿 감지 (HIGH 파일만)
    if filepath in classified['HIGH']:
        for match in SECRET_VAR_PATTERN.finditer(content):
            value = match.group(2)
            entropy = shannon_entropy(value)
            if entropy > 4.5:
                findings.append(('HIGH', filepath, f"High entropy secret (entropy={entropy:.1f})"))
                high_count += 1

# 결과 출력
if findings:
    total = len(changed_files)
    high_risk = len(classified['HIGH'])
    med_risk = len(classified['MEDIUM'])

    print(f"PRE-PUSH SECURITY SCAN", file=sys.stderr)
    print(f"Files: {total} (HIGH:{high_risk} MED:{med_risk})", file=sys.stderr)
    print(f"Critical: {critical_count} | High: {high_count}", file=sys.stderr)
    print("", file=sys.stderr)

    for severity, fpath, desc in findings[:10]:  # 최대 10개만 표시
        print(f"  [{severity}] {fpath}: {desc}", file=sys.stderr)

    if len(findings) > 10:
        print(f"  ... and {len(findings) - 10} more", file=sys.stderr)

    print("", file=sys.stderr)

    if critical_count > 0:
        print("BLOCKED: Critical security issues found. Fix before pushing.", file=sys.stderr)
        print("Run /security-review for detailed analysis.", file=sys.stderr)
        sys.exit(2)
    else:
        print("WARNING: Security issues found. Consider running /security-review.", file=sys.stderr)
        sys.exit(0)

sys.exit(0)
SCAN_SCRIPT
SCAN_EXIT=$?

# 마커 파일 생성 (세션당 1회 실행 보장)
touch "$MARKER" 2>/dev/null

# Python 종료 코드 전달
exit $SCAN_EXIT
