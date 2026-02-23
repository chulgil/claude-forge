<p align="center">
  <img src="docs/banner.png" alt="Claude Forge" width="100%">
</p>

<h1 align="center">Claude Forge</h1>

<p align="center">
  <strong>Claude Code를 위한 프로덕션 수준 설정 프레임워크</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/Claude%20Code-%E2%89%A51.0-blueviolet" alt="Claude Code"></a>
  <img src="https://img.shields.io/badge/에이전트-23-green" alt="23 Agents">
  <img src="https://img.shields.io/badge/커맨드-79-orange" alt="79 Commands">
  <img src="https://img.shields.io/badge/훅-23-red" alt="23 Hooks">
</p>

---

## Claude Forge란?

Claude Forge는 Claude Code를 기본 CLI에서 완전한 개발 환경으로 변환하는 올인원 설정 프레임워크입니다. 23개 전문 에이전트, 79개 슬래시 커맨드, 21개 스킬 워크플로우, 23개 보안/자동화 훅, 10개 규칙 파일을 포함하며, 설치 한 번으로 모든 것이 연결됩니다.

> [English README](README.md)

---

## 빠른 시작

```bash
# 1. 클론
git clone --recurse-submodules https://github.com/sangrokjung/claude-forge.git
cd claude-forge

# 2. 설치 (~/.claude에 심볼릭 링크 생성)
./install.sh

# 3. Claude Code 실행
claude
```

---

## 주요 구성

| 카테고리 | 수량 | 주요 항목 |
|----------|------|-----------|
| **에이전트** | 23 | planner, architect, code-reviewer, security-reviewer, tdd-guide, database-reviewer, web-designer, codex-reviewer, gemini-reviewer 등 |
| **커맨드** | 79 | `/commit-push-pr`, `/handoff-verify`, `/explore`, `/tdd`, `/plan`, `/orchestrate`, `/generate-image` 등 |
| **스킬** | 21 | build-system, security-pipeline, eval-harness, team-orchestrator, session-wrap 등 |
| **훅** | 23 | 7단계 보안 방어, 크로스 모델 자동 리뷰, MCP 속도 제한, 시크릿 필터링 |
| **규칙** | 10 | coding-style, security, git-workflow, golden-principles, agent orchestration 등 |
| **MCP 서버** | 9 | context7, memory, exa, gmail, github, fetch, jina-reader, desktop-commander, coingecko |

---

## 아키텍처

```
~/.claude/                      (install.sh가 심볼릭 링크 생성)
  ├── agents/                   23개 전문 에이전트 정의
  ├── commands/                 79개 슬래시 커맨드
  ├── skills/                   21개 다단계 워크플로우
  ├── hooks/                    23개 이벤트 기반 스크립트
  ├── rules/                    10개 자동 로드 규칙 파일
  ├── scripts/                  유틸리티 (md-to-docx, pdf-enhance)
  ├── cc-chips/                 CC CHIPS 상태바 (서브모듈)
  ├── cc-chips-custom/          커스텀 상태바 오버레이
  ├── knowledge/                지식 베이스
  ├── reference/                참조 문서
  ├── setup/                    설치 가이드
  └── settings.json             권한, 훅, 환경 설정
```

설치 스크립트가 리포에서 `~/.claude/`로 **심볼릭 링크**를 생성하므로, `git pull` 한 번으로 즉시 업데이트됩니다.

---

## 핵심 기능

### 크로스 모델 리뷰 파이프라인

다양한 관점의 코드 리뷰를 위해 여러 AI 모델을 자동으로 활용합니다:

- **Codex Reviewer**: OpenAI Codex 기반 세컨드 오피니언
- **Gemini Reviewer**: Google Gemini 3 Pro 프론트엔드 특화 리뷰
- **Code Reviewer**: Claude 네이티브 종합 리뷰

파일 수정 시 PostToolUse 훅을 통해 세 가지 모두 자동 실행됩니다.

### 보안 훅 (7단계 방어)

| 단계 | 훅 | 트리거 |
|------|-----|--------|
| 1 | `output-secret-filter.sh` | 모든 도구 출력 |
| 2 | `remote-command-guard.sh` | Bash 명령 |
| 3 | `db-guard.sh` | SQL 실행 |
| 4 | `email-guard.sh` | 이메일 발송 |
| 5 | `ads-guard.sh` | 광고 플랫폼 조작 |
| 6 | `calendar-guard.sh` | 캘린더 수정 |
| 7 | `security-auto-trigger.sh` | 코드 변경 |

### CC CHIPS 상태바

모델, 세션 ID, 토큰 사용량, MCP 통계를 실시간으로 표시합니다. [CC CHIPS](https://github.com/roger-me/CC-CHIPS) 기반 + 커스텀 오버레이.

### Agent Teams 지원

멀티 에이전트 협업:
- Hub-and-spoke 통신 (리더가 조율)
- 파일 소유권 분리 (충돌 없음)
- 페이즈 기반 팀 교체
- 결정 사항은 `decisions.md`로 외부화

---

## 커스터마이징

추적되는 파일을 수정하지 않고 설정을 오버라이드할 수 있습니다:

```bash
# 로컬 오버라이드 파일 생성 (git-ignored)
cp setup/settings.local.template.json ~/.claude/settings.local.json

# 시크릿/환경설정 편집
vim ~/.claude/settings.local.json
```

`settings.local.json`은 Claude Code가 `settings.json` 위에 병합합니다.

---

## 기여

에이전트, 커맨드, 스킬, 훅 추가 방법은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

---

## 라이선스

[MIT](LICENSE) -- 자유롭게 사용, 포크, 확장하세요.
