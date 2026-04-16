---
name: query
description: >
  BigQuery 쿼리를 생성합니다. 회사 테이블 구조, 식별자 규칙(user_id vs owner/code),
  ep_ prefix 컨벤션, 시간 기준(KST/UTC)을 자동 적용합니다.
  "쿼리 짜줘", "데이터 추출", "BigQuery", "SQL 작성" 등의 요청 시 사용.
  DAU, 퍼널, 코호트, 트래픽 소스 등 자주 쓰는 패턴도 지원합니다.
---

# /query — BigQuery 쿼리 생성

회사의 BigQuery 컨벤션을 자동 적용한 쿼리를 생성합니다.

## 실행 전 필수

**반드시 `references/bigquery-conventions.md`를 읽고** 컨벤션을 확인한 후 작업을 시작하세요.
자주 쓰는 패턴은 `references/query-patterns/` 를 참조하세요.

## 실행 흐름

### 1단계: 정보 수집
AskUserQuestion을 사용하여 확인:

1. **어떤 데이터가 필요한가요?** (분석 목적 또는 분석 설계서 참조)
2. **어떤 테이블을 사용하나요?**
   - original_mart (custom events)
   - auto_collected_events 마트
   - events_YYYYmmdd (Firebase 원본)
   - 상용 DB 복제 테이블 (→ **구체적으로 어떤 테이블인지**)
3. **분석 기간은?** (YYYY-MM-DD ~ YYYY-MM-DD)
4. **필요한 컬럼이나 조건이 있나요?**
5. **결과 형태는?** (raw 데이터, 집계 테이블, 피벗 등)
6. **테이블 조인이 필요한가요?** (→ 조인 키 확인 필수)

### 2단계: 쿼리 생성
`query-builder` 에이전트를 호출. 이 때 `references/bigquery-conventions.md` 내용을 함께 전달:

```
Agent(subagent_type="query-builder", prompt="[수집한 정보 + BQ 컨벤션 내용 + 조건]")
```

### 3단계: 쿼리 검증 및 확인
생성된 쿼리를 사용자에게 보여주며 다음을 명시:
- **사용된 식별자**와 선택 이유
- **적용된 정합성 조건**
- **시간 기준** (KST vs UTC)
- **주의사항** (있으면)

### 4단계: 실행 코드 제공
확인된 쿼리를 `execute_query()` 호출 형태로 제공:

```python
query = """
[확인된 SQL]
"""
df = execute_query(query)
print(f"데이터 shape: {df.shape}")
df.head()
```

## 주의사항
- **상용 DB 복제 테이블은 식별자가 다름** (owner, code). 반드시 사용자와 확인.
- **event_date는 KST, event_timestamp는 UTC**. 혼용 금지.
- 테이블 조인 시 **조인 키를 반드시 확인**.
- 쿼리가 복잡한 경우 CTE로 단계별 분리하여 가독성 확보.

## 이벤트 로그 쿼리 작성 시 추가 체크리스트

### 중복 적재 이슈 확인
- 일부 이벤트는 동일 플로우에서 **2회 이상 적재**될 수 있음
  - 예: `received_page_view`, `earn_page_view` 류
- `COUNT(*)` 집계 전에 **중복 가능성을 사용자에게 확인**
- 중복 가능성이 있으면 `(user_pseudo_id, event_date, ep_order)` 등 적절한 키로 **DISTINCT 처리 후 COUNT**

### Proxy 이벤트 사용 시 검증 쿼리 포함
- 이벤트 로그를 외부 집계(SSP impression 등)의 proxy로 쓸 경우:
  1. **어떤 이벤트가 가장 적절한 proxy인지 사용자와 확인** (광고 노출 직후 이벤트 vs 지급 완료 이벤트 등)
  2. **외부 집계 총합과의 gap 검증 쿼리를 반드시 함께 작성**
  3. Gap이 클 경우 원인 진단:
     - 앱 버전 필터 적용 여부 차이 (이벤트 쿼리는 버전 필터 O, SSP는 버전 무관)
     - 중복 적재로 인한 과대 집계
     - 광고 시청 후 이탈로 인한 과소 집계 (구조적 한계)

### 이벤트 쿼리 vs 외부 집계 테이블 역할 분리
- 앱 버전 필터가 적용된 이벤트 쿼리와, 버전 무관한 외부 테이블(SSP 등) 사이에는 **구조적 gap이 항상 존재**
- 이 경우 두 소스의 역할을 분리:
  - **외부 집계(SSP 등)**: 절대값 ground truth (총 impression, revenue)
  - **이벤트 proxy**: 상대적 분포(회차별 비율 등)만 활용
- 쿼리 주석에 이 역할 분리 원칙을 명시
