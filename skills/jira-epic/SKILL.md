---
name: jira-epic
version: 1.0.0
description: Jira 프로젝트에 에픽을 생성하고 기존 관련 이슈를 하위로 연결하는 스킬
last_updated: 2026-03-17
trigger: /jira-epic
argument-hint: "<프로젝트키> <에픽 제목 또는 주제>"
---

# Jira 에픽 생성 스킬

## 사용법

```
/jira-epic KRPB RP 정책 변경
/jira-epic KEEN 대만 마이그레이션 Phase 2
/jira-epic KRPB CMS 스크립트 자동화
```

## 실행 절차

### 1단계: 프로젝트 확인

1. `jira_get_project_issues`로 프로젝트 존재 여부 및 최근 이슈 확인
2. 이슈 유형 이름 파악 (한글 `에픽` vs 영문 `Epic` — 프로젝트마다 다름)
3. 기존 에픽 중 동일/유사 주제가 있는지 검색:
   ```
   jira_search: project = {프로젝트키} AND issuetype = {에픽 유형명} AND summary ~ "{주제 키워드}"
   ```
4. 중복 에픽이 있으면 사용자에게 알리고 기존 에픽 사용 여부 확인

### 2단계: 에픽 생성

`jira_create_issue`로 에픽 생성. 아래 형식을 따른다:

**제목 형식**: `[{국가코드}] {주제} - {부제}`
- 예: `[KR] RP 정책 변경 - 회원가입 개편 및 EMS 발송`

**본문 구조** (Markdown):
```markdown
## 개요
{1~2문장 요약}

## 주요 작업 범위
### 1. {작업 그룹 1}
- 세부 항목들

### 2. {작업 그룹 2}
- 세부 항목들

## 관련 문서
- [Confluence - 문서명](URL)
- [Figma - 디자인명](URL)
- [JIRA 티켓](URL)

## 기술 스택
- {관련 기술 정보}
```

**레이블**: 주제와 관련된 키워드 (예: `RP`, `Member`, `Migration`)

### 3단계: 관련 기존 이슈 탐색

주제 키워드로 기존 이슈를 검색하여 연결 대상을 찾는다:
```
jira_search: project = {프로젝트키} AND summary ~ "{키워드1}" OR summary ~ "{키워드2}"
```

- 에픽 자체는 제외 (issuetype != 에픽)
- 이미 다른 에픽에 속한 이슈는 제외
- 찾은 이슈 목록을 사용자에게 보여주고 연결 여부 확인

### 4단계: 하위 이슈 연결

기존 이슈를 에픽 하위로 연결한다.

**연결 방법** (우선순위 순):
1. `jira_update_issue`로 parent 필드 설정 (Jira Cloud 차세대 프로젝트):
   ```json
   {"parent": {"key": "{에픽키}"}}
   ```
2. 위 방법 실패 시 `jira_link_to_epic` 시도 (클래식 프로젝트)
3. 둘 다 실패 시 `jira_update_issue`로 Epic Link 커스텀 필드 설정:
   ```json
   {"epicKey": "{에픽키}"}
   ```

### 5단계: 결과 보고

생성 완료 후 아래 형식으로 보고:

```
### 생성된 에픽
**[{에픽키}](URL)** — {에픽 제목}

### 하위 연결된 이슈
| 티켓 | 제목 | 담당자 |
|------|------|--------|
| [KRPB-xxx](URL) | 이슈 제목 | 담당자명 |
```

## 주의사항

### 이슈 유형 이름
- KRPB 프로젝트: `에픽`, `작업` (한글)
- 다른 프로젝트는 `Epic`, `Task` (영문)일 수 있음
- 첫 생성 시 에러 나면 한/영 반대로 재시도

### 에픽 연결 방식
- KRPB(이커머스팀) 프로젝트: `parent` 필드 방식으로 연결 확인됨
- `jira_link_to_epic`은 "is not an Epic" 에러 발생 — 차세대 프로젝트에서는 사용 불가

### 에픽 상태 전환 (보드 노출)
- KRPB 프로젝트: 에픽 생성 후 반드시 **"프로젝트"** 상태(transition ID: 43)로 전환해야 보드에 노출됨
- 기본 "해야 할 일" 상태에서는 프로젝트 리스트 뷰에 표시되지 않음
- 전환 방법: `jira_transition_issue(issue_key, transition_id="43")`
- 다른 프로젝트는 보드 필터 설정에 따라 다를 수 있으므로, 기존 에픽의 상태를 먼저 확인하고 동일하게 맞출 것

### 컨텍스트 수집
- 대화 히스토리에서 관련 문서, Confluence 링크, Figma 링크 등을 수집하여 에픽 본문에 포함
- 기술 스택 정보가 있으면 함께 기재
