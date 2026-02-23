# Agent MCP 설정 참조

> 이 파일은 agents-v2.md에서 분리된 MCP 분배 및 설정 내용입니다.
> 핵심 에이전트 목록과 즉시 사용 규칙은 [agents-v2.md](agents-v2.md) 참조.
> 팀 운영 상세는 [agents-teams-ref.md](agents-teams-ref.md) 참조.

## MCP 분배 패턴 (팀 워크플로우)

| 패턴 | Frontend/Writer | Backend/Designer | Tester/Distributor |
|------|----------------|------------------|--------------------|
| 풀스택 | Browser Automation, Data Transform | Memory, System Commands | Browser Automation, Analytics |

## MCP-Aware Subagent 선택 가이드

| 필요 MCP | 권장 type | 이유 |
|----------|-----------|------|
| CI/CD, Browser Automation, HTTP, Memory | general-purpose | Write/Bash 접근 필요 |
| Web Search, Documentation, Content Search | Explore | 읽기 전용 리서치 |
