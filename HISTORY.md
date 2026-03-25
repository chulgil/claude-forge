# Claude Forge — Fork History

> 포크 원본: [sangrokjung/claude-forge](https://github.com/sangrokjung/claude-forge)
>
> 포크 저장소: [chulgil/claude-forge](https://github.com/chulgil/claude-forge)

이 문서는 upstream 동기화 및 자체 커스터마이징 이력을 기록합니다.

---

## 2026-03-25

### GStack 패턴 체리픽 (자체 추가)

GStack(게리 탄)의 핵심 패턴 3가지를 Claude Forge에 통합.

| 변경 | 파일 | 사용법 |
|------|------|--------|
| **CEO 리뷰 모드** | `commands/plan.md` | `/plan --ceo 기능 설명` |
| **스프린트 회고** | `commands/retro.md` (신규) | `/retro 7d` |
| **분할 커밋** | `commands/commit-push-pr.md` | `/commit-push-pr --split` |

**CEO 리뷰 모드 (`--ceo`)**
- 제품 비전 관점에서 기획 (기존 `--eng`는 기술 중심)
- 텐스타 제품 방향 3~5개 발굴
- 4가지 범위 모드: 10x Vision / 기본 / Cherry / 무자비한 MVP
- UX 감정 분석 + ASCII 아키텍처 다이어그램 필수

**스프린트 회고 (`/retro`)**
- Git 커밋 히스토리 기반 12개 병렬 쿼리
- 도메인별 활동 분석, 커밋 타입 분포, 핫스팟 탐지
- 1일~30일 범위 설정 가능
- `--output` 옵션으로 마크다운 파일 저장

**분할 커밋 (`--split`)**
- 변경 파일을 논리 단위(스키마→로직→UI→테스트→문서)로 자동 분류
- 그룹별 Conventional Commit 메시지 자동 생성
- PR 리뷰어가 이해하기 쉬운 커밋 히스토리 생성

### GStack Browse 설치 (자체 추가)

GStack의 0-token 헤드리스 브라우저를 `install.sh`에 통합.

- `~/.claude/skills/gstack/`에 자동 클론 + 빌드
- Bun 미설치 시 자동 설치
- Playwright Chromium 자동 설치
- 기존 설치 시 `git pull`로 업데이트

```bash
# install.sh 실행 시 선택 옵션으로 제공
Install GStack Browse? (Bun required, ~60MB) (y/n)
```

**GStack Browse vs Playwright MCP:**

| 항목 | GStack Browse | Playwright MCP |
|------|-------------|----------------|
| 컨텍스트 오버헤드 | **0 토큰** | 1,500 토큰/호출 |
| 이후 호출 속도 | **~100ms** | 1~3초 |
| 세션 유지 | 데몬 모델 (쿠키 유지) | 매번 새 시작 |
| 요소 식별 | 접근성 트리 (@e1, @e2) | CSS 셀렉터 |

### Upstream 동기화

upstream [sangrokjung/claude-forge](https://github.com/sangrokjung/claude-forge)에서 11개 커밋 머지.

| 버전 | 주요 내용 |
|------|----------|
| **v2.2** | Karpathy 원칙 기반 Surgical Changes + State Assumptions 규칙 추가 |
| **v2.1** | 에이전트 self-evolution, verification 규칙, 전체 영문 번역 |
| **보안** | ExitPlanMode 자동승인 버그 대응, deny 리스트 12개 패턴 추가 |
| **플러그인** | Claude Code 공식 마켓플레이스 지원 (`.claude-plugin/`) |
| **에이전트 라우팅** | 34개 도메인 자동 라우팅 (`/agent-router`) |
| **문서** | `/plan` vs 내장 PlanMode 비교 가이드 |

**신규 파일:**
- `rules/verification.md` — 검증 규칙 (자동 로딩)
- `commands/agent-router.md` — 에이전트 자동 라우팅
- `skills/using-superpowers/` — Codex/Gemini 도구 연동
- `.mcp.json` — 마켓플레이스 호환 MCP 설정
- `docs/plan-vs-planmode.md` — Plan 스킬 비교

---

## 이전 이력

포크 초기 설정 및 개인화 — upstream과 동일한 기본 구조에서 시작.
