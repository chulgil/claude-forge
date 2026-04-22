---
name: zt-rag
description: |
  로컬 RAG로 볼트 전체를 질의. MLX + ChromaDB + BM25 하이브리드로 retrieval,
  Qwen2.5-Coder-32B로 답변 생성 후 55 Query Results/에 Zettel로 파일링.
  외부 API 호출 없음.
  트리거: /zt-rag, 로컬 RAG, 볼트 쿼리, 볼트 질문, vault query
---

# Zettelkasten RAG — 로컬 MLX + ChromaDB 하이브리드 Q&A

볼트 전체를 대상으로 질문하고, LLM 답변을 Zettel 노트로 파일링하는 로컬 RAG 스킬.
`zt-query`가 Claude Code가 실시간으로 볼트를 탐색한다면, `zt-rag`는
사전 인덱싱된 로컬 벡터+BM25 스토어에서 retrieval → 로컬 LLM이 답변한다.

## 트리거

`/zt-rag <질문>` — 기본 저장 + 스트리밍
`/zt-rag --no-save <질문>` — 저장하지 않고 답변만 출력
`/zt-rag --domain dev <질문>` — 특정 도메인으로 retrieval 제한
`/zt-rag --mode vector <질문>` — vector only (기본: hybrid)

## 볼트 위치

MyBrain: `/Users/r00360/Dev/mybrain` (git 리포지토리 경로)
scripts 경로: `/Users/r00360/Dev/mybrain/scripts`

현재 작업 디렉토리가 MyBrain이 아니면 위 경로로 이동.

## 사전 요구사항

1. **MLX 서버 가동 중** (`http://localhost:8080/v1`)
2. **인덱스 존재** (`/Users/r00360/Dev/mybrain/.rag_index/mybrain/`)
3. **BM25 인덱스 존재** (`/Users/r00360/Dev/mybrain/.rag_index/bm25.pkl`)

## 동작

### Step 1: MLX 서버 생존 확인

```bash
curl -s --max-time 2 http://localhost:8080/v1/models | head -c 200
```

응답이 없으면 안내:

```
⚠ MLX 서버가 꺼져있습니다. 다음 명령으로 기동하세요:

  mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 8080

별도 터미널에서 백그라운드로 실행 후 다시 /zt-rag를 호출하세요.
```

### Step 2: 인덱스 상태 확인

```bash
cd /Users/r00360/Dev/mybrain/scripts && uv run python -m vault_rag status
```

`chunks` 값이 `(index not found — ...)` 이면 안내:

```
⚠ RAG 인덱스가 없습니다. 먼저 인덱싱하세요:

  cd /Users/r00360/Dev/mybrain/scripts && uv run python -m vault_rag index

첫 실행은 2,300+ 노트 처리로 ~15분 소요. 이후 증분 인덱싱은 수 초.
```

### Step 3: 쿼리 실행

**기본 동작** (답변 저장 + 스트리밍):

```bash
cd /Users/r00360/Dev/mybrain/scripts && \
  uv run python -m vault_rag query "사용자질문" --stream --save
```

**옵션 매핑**:

| 사용자 옵션 | CLI 플래그 |
|-----------|-----------|
| `--no-save` | `--save` 제거 |
| `--domain <X>` | `--domain X` |
| `--mode vector` | `--mode vector` |
| `--mode bm25` | `--mode bm25` |
| (기본) | `--mode hybrid --save --stream` |

### Step 4: 결과 요약 출력

CLI 출력에서 아래 정보를 추출해서 사용자에게 깔끔하게 보여준다:

- LLM 답변 본문
- "출처:" 섹션의 노트 경로들 (볼트 내 [[wikilink]] 형식으로 변환)
- `✓ saved: 55 Query Results/...` 라인에서 저장된 파일 경로

**출력 예시**:

```
📝 답변:
CPI(Cost Per Install)는 앱 설치 1건당 지불하는 광고비...

🔗 근거 노트:
- [[CPI (설치당 비용)]]
- [[광고비]]
- [[설치당비용]]

💾 저장: 55 Query Results/2026-04-22-cpi란.md
```

### Step 5: 후속 제안 (선택적)

답변이 생성됐으면 사용자에게 다음 액션을 제안:

- "이 답변을 Insight로 승격시키려면 `35 Insights/<domain>/`로 이동"
- "근거 노트에 백링크를 추가하려면 해당 노트 편집"
- 답변이 "볼트에 관련 정보가 없습니다"면 → 인덱스 갱신 권장 (`vault_rag index`)

## 에러 처리

| 에러 | 원인 | 안내 |
|-----|------|-----|
| Connection refused | MLX 서버 꺼짐 | Step 1의 기동 명령 안내 |
| `(index not found)` | 인덱싱 안됨 | Step 2의 인덱싱 명령 안내 |
| `--mode hybrid` + BM25 없음 | BM25 인덱스 누락 | 재인덱싱 안내 (CLI가 자동으로 `vector` 폴백) |
| 타임아웃 | LLM 응답 느림 | 모델 로딩 중 가능성 — 30초 후 재시도 |

## /zt-query와의 차이

| 항목 | `/zt-query` | `/zt-rag` |
|------|------------|----------|
| 실행 주체 | Claude Code (원격 API) | 로컬 MLX + Qwen |
| retrieval | Grep/Glob 실시간 | 사전 인덱싱된 벡터+BM25 |
| 속도 | 볼트 크기에 의존 | O(Top-K) 상수 |
| 오프라인 동작 | 불가 | 가능 (인터넷 없어도 OK) |
| 비용 | API 토큰 비용 | 무료 (전력만) |
| 답변 품질 | 최신 모델 (Opus 4.7) | Qwen2.5-Coder-32B |
| 볼트 최신 상태 반영 | 즉시 | 재인덱싱 필요 |

**추천 사용**:
- 새로 쓴 노트 포함 질문: `/zt-query`
- 오프라인/프라이버시 중요: `/zt-rag`
- 빠른 반복 질의: `/zt-rag`

## 관련 스킬

- `/zt-query` — 온라인 실시간 볼트 탐색
- `/zt-index` — 벡터 인덱싱 + 클러스터맵 갱신
- `/zt-ingest` — 인박스 → 도메인 분류

## 구현 참조

- CLI: `/Users/r00360/Dev/mybrain/scripts/vault_rag/cli.py`
- 설계 가이드: `/Users/r00360/Dev/mybrain/CLAUDE.md` → "로컬 RAG (vault_rag)" 섹션
- Heart Cache: `/Users/r00360/Dev/mybrain/_wiki-heart.md` — 최신 상태 요약
