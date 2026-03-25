---
description: YouTube 영상을 요약하여 가이드 문서를 작성합니다
argument-hint: <YouTube URL>
---

# YouTube Guide Generator (v2)

YouTube 영상 URL을 받아 요약 + 트랜스크립트를 추출하고, 가이드 문서 작성 + AI 키워드 Anki 업데이트를 수행합니다.

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

### 3단계: 중복 체크

**기존 가이드 문서와의 중복을 반드시 확인한다.**

1. 저장 위치의 README.md를 읽어 기존 문서 목록 확인
2. 동일/유사 주제의 문서가 있으면:
   - 완전 중복 → 기존 문서 업데이트 (새 파일 생성 금지)
   - 부분 중복 → 새 문서 작성하되, 중복 내용은 기존 문서 링크로 대체
3. 중복 여부를 사용자에게 보고

### 4단계: 가이드 문서 작성

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
- Claude Forge에서 대체 가능한 기능이 있으면 매핑 표 추가

---

## Lesson App 활용 예시

lesson-app 프로젝트 컨텍스트:
- Flutter + Riverpod + Clean Architecture
- 음악 레슨/연습 관리 앱 (iOS, Android)
- features: lessons, practice, students, parent_home, notifications, onboarding
- backend: FastAPI (개발 예정)
- 로컬 DB: Hive

해당 도구/기능이 lesson-app에 어떻게 적용될 수 있는지 **구체적** 예시 2~4개 작성.
각 예시는 다음 형식:
1. 기능/도메인 명시 (예: "레슨 예약 플로우")
2. 적용 방법 (코드 예시 또는 설정 예시)
3. 기대 효과 (정량적이면 더 좋음)

---

## 핵심 포인트

1. ...
2. ...
```

### 5단계: AI 키워드 Anki 업데이트

**영상에서 새로운 AI 관련 용어가 등장했는지 확인하고, 학습 가치가 있으면 추가한다.**

5-1. 기존 키워드 로딩:
```bash
# 기존 키워드 목록 확인
grep -oP '<b>[^<]+</b>' study/ai/data/ai-keywords.tsv | sort
```

5-2. 영상에서 추출된 용어와 기존 목록 비교:
- **중복** → 스킵
- **간단한 용어** (토큰, GPU, LLM 등 이미 있거나 자명한 것) → 스킵
- **새로운 기술 용어** → TSV에 추가

5-3. 새 키워드가 있으면 `study/ai/data/ai-keywords.tsv`에 추가:
```
<b>[용어]</b>\t<b>[한글명]</b><br><br>[설명 2~3문장]<br><br><i>[비유 또는 예시]</i>\t[태그]
```

태그 규칙:
- `ai::model` — 모델/아키텍처
- `ai::technique` — 기법/방법론
- `ai::infra` — 인프라/도구
- `ai::application` — 응용/서비스
- `ai::pattern` — 설계/워크플로 패턴

5-4. Anki 덱 리빌드:
```bash
uv run python study/anki/scripts/build_all.py --ai
```

5-5. 추가/스킵된 키워드를 사용자에게 보고:
```
[AI Keywords 업데이트]
  추가: Agent Orchestration, Semantic Kernel (2건)
  스킵 (기존): LLM, RAG, MCP (3건)
  스킵 (간단): API, SDK (2건)
  총 카드: 60장 → 62장
```

### 6단계: 파일 생성

- 파일명: **kebab-case**, 도구명 또는 기능명 기반
- 예: `playwright-browser-automation.md`, `perplexity-computer.md`

### 7단계: 인덱스 업데이트

1. 저장 위치의 README.md에 문서 링크 추가
2. `development/guide/README.md`에도 필요 시 추가

### 8단계: 결과 요약

작성 완료 후 사용자에게 다음을 보고:

```
[YouTube Guide 완료]
  파일: development/guide/[category]/[filename].md
  요약: [3~5줄]

[AI Keywords]
  추가: [N]건 | 스킵: [N]건 | 총 카드: [N]장

[Lesson App 예시]
  1. [예시 제목]
  2. [예시 제목]
```

---

## 주의사항

- `summarize` CLI가 설치되어 있어야 함 (`brew install steipete/tap/summarize`)
- 트랜스크립트 추출 실패 시 요약본만으로 작성
- 날짜는 반드시 시스템 명령(`date`)으로 확인
- 영상이 한국어/영어 혼합일 수 있으므로 문서는 **한국어**로 작성
- AI 키워드 추가 시 기존 카드와 **반드시 중복 체크** (grep으로 확인)
- Lesson App 예시는 실제 프로젝트 구조(features/[domain]/)에 맞게 구체적으로 작성
