# Zettelkasten Audit — LLM 기반 노트 재분류 제안

특정 폴더의 노트들을 LLM이 읽고 더 적합한 저장 위치를 제안하는 스킬.
카르파시의 "분류 재정렬"을 MyBrain 구조에 맞춰 구현.
**파일을 이동하지 않는다.** JSON 제안서만 생성 → 사용자 검토 후 수동/후속 이동.

## 트리거

- `/zt-audit` — 기본 대상 `35 Insights/general` (1,182건)
- `/zt-audit --folder "<경로>"` — 특정 폴더 감사
- `/zt-audit --folder "<경로>" --limit N` — N개만 샘플 감사

## 볼트 위치

MyBrain: `/Users/r00360/Dev/mybrain`

## 동작

### Step 1: 대상 폴더 스캔

- 지정 폴더의 `.md` 파일 목록 수집
- `_MOC*`, 템플릿 파일 제외
- 각 노트의 프런트매터(title, type, domain, tags, summary) + 본문 1,200자 미리보기 추출

### Step 2: LLM 분류 호출 (Claude Haiku 4.5)

`scripts/vault_audit` 서브패키지 실행:

```bash
cd /Users/r00360/Dev/mybrain/scripts
uv run python -m vault_audit --folder "35 Insights/general" --sleep 0.12
```

각 노트에 대해 JSON 제안 생성:
```json
{
  "path": "35 Insights/general/어떤노트.md",
  "current_type": "insight",
  "current_domain": "general",
  "type": "insight",
  "domain": "mindset",
  "target_folder": "35 Insights/mindset",
  "confidence": "high",
  "reason": "저자의 실행 경험 기반 통찰 + 구체적 3가지 신념체계"
}
```

### Step 3: 제안서 저장

기본 경로: `logs/vault_audit_proposals.json`

각 건 성공 후 즉시 JSON append 저장 → 중단 시 재개 가능.

### Step 4: 사용자 검토 루프

스킬은 분류 완료 후 아래 3가지 버킷 요약을 출력:
- **keep (현재 위치 유지)**: 추가 조치 없음
- **high-confidence 이동 제안**: 대부분 승인 가능
- **low/medium confidence**: 수동 검토 필수

예시 보고:
```
[Audit 완료]
  대상: 35 Insights/general (1,182개)
  제안 분포:
    keep:          X개
    → 35 Insights/mindset (high):   Y개
    → 35 Insights/dev (high):       Z개
    → 40 Keywords/* (high):         W개
    → 50 Archives (archive):        V개
    low/medium confidence:          M개

  다음 단계:
    1. logs/vault_audit_proposals.json 검토
    2. high-confidence 이동 일괄 적용 (별도 스크립트)
    3. low/medium 항목 수동 판단
```

### Step 5: 이동 실행 (별도 단계, 자동 아님)

**/zt-audit 자체는 이동하지 않는다.** 이동은 사용자 승인 후 아래 중 하나로:

A. 수동: Finder/Obsidian으로 옮기기
B. 스크립트: `scripts/vault_audit/mover.py` (향후 개발, Wikilink 갱신 포함)
C. `/zt-ingest` 변형으로 재인제스트

## 분류 스키마

| type | 정의 | 저장 위치 |
|------|------|----------|
| keyword | 1개념 1파일 (원자 정의) | `40 Keywords/{domain}/` |
| knowledge | 여러 개념 학습 가이드 | `30 Knowledge/{domain}/` |
| insight | 본인 언어 통찰 | `35 Insights/{domain}/` |
| project | 마감 있는 작업 | `10 Projects/{project}/` |
| meeting | 회의록 | `61 Meetings/` |
| journal | 일일 저널 | `60 Journal/{year}/` |
| flashcard | Anki 카드 | `70 Flashcards/{domain}/` |
| people | 인물 | `20 Areas/people/` |
| archive | 비활성·미완성 | `50 Archives/` |
| keep | 현재 위치 적절 | (유지) |

domain: `ai, business, dev, finance, mindset, english, health, career, general`

## CLAUDE.md 연계

- `35 Insights/general/`은 폐지 방침 → `general` 유지는 원칙적으로 없음
- insight 하위는 `{domain}` 서브폴더 중 하나로 라우팅 필수
- archive 판정 시 `status: archived` 프런트매터 추가 권장

## 제한사항

- **파일 이동은 수행하지 않음** — 제안 JSON만 생성
- **Wikilink 갱신 안 함** — 이동 시 별도 도구 필요
- 본문 1,200자 초과 내용은 LLM이 보지 못함 (긴 노트는 샘플링 기반 판단)
- confidence 낮음 → 사용자 수동 검토 필수
