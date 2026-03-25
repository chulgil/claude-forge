---
description: YouTube 영상을 요약하여 가이드 문서를 작성합니다
---

# YouTube Guide Generator

YouTube 영상 URL을 받아 요약 + 트랜스크립트를 추출하고, 실사용 가이드 문서를 작성하여 적절한 위치에 저장합니다.

## 입력

- `$ARGUMENTS`: YouTube URL (필수)

URL이 없으면 에러를 출력하고 종료:
```
사용법: /youtube-guide <YouTube URL>
예시: /youtube-guide https://www.youtube.com/watch?v=xxxxx
```

---

## 실행 절차

### 1단계: 영상 내용 추출 (병렬)

두 명령을 **동시에** 실행:

```bash
summarize "$ARGUMENTS" --youtube auto --length xxl
summarize "$ARGUMENTS" --youtube auto --extract-only
```

두 결과를 모두 확보한 후 다음 단계로 진행.

### 2단계: 내용 분석 & 분류

영상 주제를 분석하여 저장 위치를 결정:

| 주제 | 저장 위치 |
|------|----------|
| Claude Code 실전 가이드 (도구 사용법, 워크플로우) | `development/guide/claude-code/` |
| Claude Code 기능 출시/업데이트 소식 | `development/guide/claude-code/updates/` |
| AI 도구/플랫폼/서비스 | `development/guide/ai-agent/` |
| 학습 전략/방법론 | `development/guide/ai-agent/` |

### 3단계: 가이드 문서 작성

다음 템플릿을 따라 작성:

```markdown
# [도구/기능명] — [한줄 설명]

> 출처: [YouTube - 제목](URL)
>
> 작성일: [오늘 날짜]

---

## 핵심 요약

**[1~2줄 핵심 요약]**

비유: [일상적 비유 1~2문장]

---

## [본문 섹션들]
- 기능/사용법은 표 또는 코드블록으로 정리
- 설치 방법이 있으면 Step별로 구분
- 비교가 있으면 비교 표 작성

---

## Lesson App 활용 예시

lesson-app 프로젝트 컨텍스트:
- Flutter + Riverpod + Clean Architecture
- 음악 레슨/연습 관리 앱 (iOS, Android)
- features: lessons, practice, students, parent_home, notifications, onboarding
- backend: FastAPI (개발 예정)
- 로컬 DB: Hive

해당 도구/기능이 lesson-app에 어떻게 적용될 수 있는지 **구체적** 예시 2~4개 작성.

---

## 핵심 포인트

1. ...
2. ...
```

### 4단계: 파일 생성

- 파일명: **kebab-case**, 도구명 또는 기능명 기반
- 예: `playwright-browser-automation.md`, `perplexity-computer.md`

### 5단계: 인덱스 업데이트

1. 저장 위치의 README.md에 문서 링크 추가
2. `development/guide/README.md`에도 필요 시 추가

### 6단계: 결과 요약

작성 완료 후 사용자에게 다음을 보고:
- 파일 경로
- 영상 핵심 요약 (3~5줄)
- 주요 내용 테이블

---

## 주의사항

- `summarize` CLI가 설치되어 있어야 함 (`brew install steipete/tap/summarize`)
- 트랜스크립트 추출 실패 시 요약본만으로 작성
- 날짜는 반드시 시스템 명령(`date`)으로 확인
- 영상이 한국어/영어 혼합일 수 있으므로 문서는 **한국어**로 작성
