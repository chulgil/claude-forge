---
description: 스프린트 회고 자동 생성 — 커밋 분석 기반 (GStack Retro 패턴 차용)
argument-hint: [기간] [--format brief|full] [--output 파일경로]
---

# Retro Command

Git 커밋 히스토리를 분석하여 스프린트 회고 리포트를 자동 생성한다.

> GStack의 `/retro` 패턴을 Claude Forge에 맞게 재구성. 12개 병렬 쿼리 → 구조화된 회고 리포트.

## 언제 사용하는가

- 주간 개발 보고서 작성
- 스프린트 회고 미팅 준비
- 프로젝트 진척도 파악
- 어떤 도메인에 집중했는지 분석

---

## Task

### 0단계: 인자 파싱

`$ARGUMENTS`에서 옵션 추출:

| 인자 | 설명 | 기본값 |
|------|------|--------|
| `[기간]` | 분석 기간 (`1d`, `3d`, `7d`, `14d`, `30d`) | `7d` |
| `--format brief` | 요약만 출력 | |
| `--format full` | 전체 분석 (기본값) | `full` |
| `--output [경로]` | 결과를 파일로 저장 | 터미널 출력만 |

기간을 숫자+단위로 파싱:
- `1d` → 1일, `7d` → 7일, `2w` → 14일, `1m` → 30일
- 숫자만 입력 시 일(day) 단위로 해석: `7` → `7d`

---

### 1단계: 데이터 수집 (병렬 실행)

다음 12개 쿼리를 **병렬**로 실행한다:

```bash
# 1. 커밋 통계
git log --since="[기간] ago" --oneline | wc -l
git log --since="[기간] ago" --format="%H" | wc -l

# 2. 일별 커밋 분포
git log --since="[기간] ago" --format="%ad" --date=short | sort | uniq -c | sort -rn

# 3. 변경 파일 통계
git log --since="[기간] ago" --stat --format="" | tail -1

# 4. 도메인별 변경 횟수 (features/ 기준)
git log --since="[기간] ago" --name-only --format="" | grep -oP '(features|src|lib)/\K[^/]+' | sort | uniq -c | sort -rn | head -10

# 5. 가장 많이 변경된 파일 Top 10
git log --since="[기간] ago" --name-only --format="" | sort | uniq -c | sort -rn | head -10

# 6. 커밋 타입 분포 (Conventional Commits)
git log --since="[기간] ago" --format="%s" | grep -oP '^\w+' | sort | uniq -c | sort -rn

# 7. 시간대별 활동 패턴
git log --since="[기간] ago" --format="%aH" | sort | uniq -c | sort -k2 -n

# 8. 브랜치별 활동
git log --since="[기간] ago" --all --format="%D" | grep -v "^$" | sort | uniq -c | sort -rn | head -5

# 9. 추가/삭제 라인 수
git log --since="[기간] ago" --numstat --format="" | awk '{add+=$1; del+=$2} END {print "+"add, "-"del}'

# 10. 최근 PR 목록 (gh CLI)
gh pr list --state merged --search "merged:>=[시작일]" --limit 10 --json number,title,mergedAt 2>/dev/null

# 11. 이슈 활동 (gh CLI)
gh issue list --state all --search "updated:>=[시작일]" --limit 10 --json number,title,state 2>/dev/null

# 12. 테스트 커버리지 변화 (있으면)
git log --since="[기간] ago" --all -p -- "*.test.*" "*.spec.*" "*_test.*" --stat --format="" | tail -1
```

---

### 2단계: 분석 & 리포트 생성

수집된 데이터를 종합하여 다음 형식의 리포트를 생성한다:

```markdown
# 스프린트 회고 리포트

> 기간: [시작일] ~ [종료일] ([N]일)
> 생성일: [오늘 날짜]

---

## 요약

| 지표 | 값 |
|------|-----|
| 총 커밋 | [N]개 |
| 변경 파일 | [N]개 |
| 추가 라인 | +[N] |
| 삭제 라인 | -[N] |
| 머지된 PR | [N]개 |
| 해결된 이슈 | [N]개 |

---

## 도메인별 활동

| 도메인 | 커밋 수 | 비율 | 주요 변경 |
|--------|---------|------|----------|
| [domain1] | [N] | [%] | [한줄 요약] |
| [domain2] | [N] | [%] | [한줄 요약] |
| ... | | | |

---

## 커밋 타입 분포

| 타입 | 횟수 | 비율 |
|------|------|------|
| feat | [N] | [%] |
| fix | [N] | [%] |
| refactor | [N] | [%] |
| ... | | |

---

## 활동 패턴

### 일별 분포
[일별 커밋 수 막대 차트 (ASCII)]

### 시간대 분포
[시간대별 활동 히트맵 (ASCII)]

---

## 핫스팟 — 가장 많이 변경된 파일

1. `[파일경로]` — [N]회 변경
2. `[파일경로]` — [N]회 변경
3. ...

> 핫스팟이 많은 파일은 리팩토링 대상일 수 있음

---

## 머지된 PR

| # | 제목 | 머지일 |
|---|------|--------|
| [N] | [제목] | [날짜] |

---

## 잘한 점 (AI 분석)

커밋 메시지와 변경 패턴을 분석하여:
- [긍정적 패턴 1]
- [긍정적 패턴 2]

## 개선할 점 (AI 분석)

- [개선 제안 1 — 근거와 함께]
- [개선 제안 2 — 근거와 함께]

## 다음 스프린트 제안

변경 패턴과 미해결 이슈를 기반으로:
1. [우선순위 높은 작업]
2. [기술 부채 해결]
3. [새로운 기능]
```

---

### 3단계: 출력

**`--format brief` 시:**
- "요약" 섹션만 출력
- 도메인별 활동 테이블 포함
- 나머지 생략

**`--output [경로]` 시:**
- 전체 리포트를 지정 경로에 마크다운 파일로 저장
- 터미널에는 요약만 출력

**기본 (터미널 출력):**
- 전체 리포트를 터미널에 출력

---

## 사용 예시

```bash
# 최근 7일 회고 (기본)
/retro

# 최근 1일 (어제 뭐했지?)
/retro 1d

# 2주간 회고를 파일로 저장
/retro 14d --output docs/retro-2026-03-25.md

# 30일 요약만
/retro 30d --format brief
```

## 관련 커맨드

| 상황 | 커맨드 |
|------|--------|
| 세션 종료 정리 | `/session-wrap` |
| 교훈 기록 | `/learn` |
| 다음 작업 추천 | `/next-task` |
