# 데이터 분석 하네스 (Data Analysis Harness)

> 이 프로젝트는 데이터 분석가의 업무를 단계별로 지원하는 Claude Code 하네스입니다.
> 전체 자동화가 아닌, 각 단계에서 필요한 도움을 제공하고 사용자가 확인·수정할 수 있도록 설계되었습니다.

---

## 기본 행동 규칙

1. **항상 한국어로 응답**하세요.
2. **작업 전에 반드시 AskUserQuestion으로 충분한 정보를 수집**하세요. 추측하지 마세요.
3. **한 번에 하나의 단계만** 수행하고, 결과를 보여준 뒤 사용자 확인을 기다리세요.
4. **대용량 문서**(기획서, 이벤트 명세 등)는 반드시 `doc-reader` 에이전트를 통해 구조화한 뒤 사용하세요. 원본 전체를 컨텍스트에 넣지 마세요.
5. 분석 코드 생성 시 **사용자의 기존 유틸 함수와 코드 스타일을 우선** 따르세요.
6. 결과물은 항상 **사용자가 직접 검토·수정할 수 있는 형태**(마크다운, .py 파일 등)로 제공하세요.

---

## 사용 가능한 명령어 (슬래시 커맨드)

| 명령어 | 설명 | 사용 시점 |
|--------|------|-----------|
| `/read-spec` | 기획서·이벤트 명세 읽기 및 구조화 | 분석 시작 전, 문서 파악할 때 |
| `/design` | 분석 설계서 초안 작성 | 가설·지표·세그먼트 설계할 때 |
| `/query` | BigQuery 쿼리 생성 | 데이터 추출 쿼리 필요할 때 |
| `/analyze` | 분석 Python 코드 생성 | 분석 코드 작성할 때 |
| `/viz` | 시각화 코드 생성 | 그래프·차트 만들 때 |
| `/interpret` | 분석 결과 해석 도우미 | 결과 해석이 필요할 때 |
| `/report` | 보고서 마크다운 초안 생성 | 노션 보고서 작성할 때 |

---

## BigQuery 컨벤션 요약

자세한 내용은 `.claude/skills/query/references/bigquery-conventions.md`를 참조하세요.

### 테이블 구조
- 네이밍: `project_name.dataset.table_name`
- **original_mart**: custom_events를 평탄화한 테이블 (ep_ prefix)
- **auto_collected_events 마트**: first_open, user_engagement 등
- **events_YYYYmmdd**: Firebase 원본 (STRUCT/ARRAY 구조)
- **상용 DB 복제 테이블**: 다양한 서비스 테이블

### 핵심 규칙
- `event_name` 대신 **`ep_event_label`** 을 주로 사용
- event_params 평탄화 컬럼은 **`ep_` prefix** (ep_tab, ep_service, ep_link 등)
- **식별자 규칙이 테이블마다 다름**:
  - original_mart → `user_id` 또는 `user_pseudo_id`
  - 상용 DB 복제 → `owner`, `code` (= user_id)
- 트래픽 소스 식별: `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_timestamp ASC)` → rn = 1

---

## 시각화 규칙 요약

자세한 내용은 `.claude/skills/viz/references/visualization-guide.md`를 참조하세요.

- **한글 폰트** 필수
- 제목: 분석 조건을 구체적으로 드러내는 서술형
- 주요 날짜(이벤트일 등)는 **수직선(axvline)** 으로 표시
- 참고용 **평균선** 등 기준선 표시
- 주 사용 라이브러리: matplotlib, seaborn, plotly

---

## 보고서 구조

자세한 내용은 `.claude/skills/report/references/report-template.md`를 참조하세요.

```
[핵심 요약] (경영진용, 4-5줄)
1. 분석 배경 및 개요
2. 목적 및 가설
3. 가설 단위 검증 결과 (그래프 + 해석)
4. 결론 및 제언
```

---

## 분석 코드 구조

분석에 따라 두 가지 구조 중 선택:

**가설 단위 구조:**
```
가설 1 → 데이터 추출 → 가공 → 분석 → 시각화 → 요약(md셀)
가설 2 → ...
```

**프로세스 단위 구조:**
```
Data Extraction → Preprocessing → Definition → Execute → Visualization → Summary
```

각 분석 결과 뒤에는 마크다운 셀로 다음을 정리:
- 검증한 가설
- 사용 지표 및 정의
- 계산 방법
- 간단한 수치 해석

---

## 프로젝트 폴더 구조

```
notebooks/프로젝트이름/담당자이름/분석주제/
├── *.ipynb          # 분석 노트북
├── *.py             # 분석 코드 (Claude Code 작업용)
├── *.md             # 분석 설계서
└── reference/       # 기획서, 이벤트 명세 등 입력 문서
```
