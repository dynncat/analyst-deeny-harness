# BigQuery 컨벤션 가이드

쿼리 작성 전에 반드시 참조하세요.

---

## 테이블 네이밍

```
project_name.dataset.table_name
```

---

## 주요 테이블 유형

### 1. original_mart (커스텀 이벤트 마트)

Firebase의 custom events를 평탄화(flatten)한 테이블.

**주요 컬럼:**
| 컬럼명 | 설명 | 비고 |
|--------|------|------|
| `event_date` | 이벤트 날짜 | **KST** |
| `event_timestamp` | 이벤트 타임스탬프 | **UTC** |
| `event_name` | 이벤트 이름 | 거의 사용하지 않음 |
| `ep_event_label` | 이벤트 라벨 | **주요 식별자 — event_name 대신 사용** |
| `user_pseudo_id` | Firebase 익명 식별자 | |
| `user_id` | 로그인 사용자 식별자 | |
| `device.operating_system` | OS | |
| `device.operating_version` | OS 버전 | |
| `app_info.version` | 앱 버전 | |
| `ep_tab` | 탭 정보 | ep_ prefix |
| `ep_service` | 서비스 구분 | ep_ prefix |
| `ep_link` | 링크 정보 | ep_ prefix |
| `ep_amount` | 금액/수량 | ep_ prefix |
| `ep_type` | 타입 구분 | ep_ prefix |

**식별자:** `user_id` 또는 `user_pseudo_id`

### 2. auto_collected_events 마트

Firebase 자동 수집 이벤트 마트 (first_open, user_engagement 등).

**식별자:** `user_id` 또는 `user_pseudo_id`

### 3. events_YYYYmmdd (Firebase 원본)

STRUCT/ARRAY 구조. 날짜별 테이블 (예: `events_20240301`).
직접 쿼리 시 UNNEST 필요.

**식별자:** `user_pseudo_id`, `user_id`

### 4. 상용 DB 복제 테이블

프로덕션 DB를 BigQuery로 복제. **⚠️ 식별자가 Firebase와 다름!**

**식별자:** `owner`, `code` (= user_id와 동일한 값)

---

## 핵심 규칙

### 1. ep_ prefix 규칙
```sql
-- event_params의 key-value가 ep_ prefix 컬럼으로 변환됨
-- 예: event_params.key = 'event_label' → ep_event_label
-- 예: event_params.key = 'tab' → ep_tab
```

### 2. ep_event_label 우선 사용
```sql
-- ❌ WHERE event_name = 'some_event'
-- ✅ WHERE ep_event_label = 'some_label'
```

### 3. 시간 기준 주의
```sql
-- event_date: KST
WHERE event_date BETWEEN '2024-03-01' AND '2024-03-31'

-- event_timestamp: UTC (마이크로초) → KST 변환 시 +9시간
WHERE TIMESTAMP_MICROS(event_timestamp) >= TIMESTAMP('2024-03-01', 'Asia/Seoul')
```

### 4. 테이블 조인 키
```sql
-- Firebase ↔ 상용 DB 복제: user_id = code
SELECT a.*, b.*
FROM `project_name.dataset.original_mart` a
JOIN `project_name.dataset.production_table` b
  ON a.user_id = b.code
```

### 5. 트래픽 소스 식별 패턴
```sql
WITH user_first_touch AS (
  SELECT
    user_id,
    -- 트래픽 소스 관련 컬럼,
    ROW_NUMBER() OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp ASC
    ) AS rn
  FROM `project_name.dataset.original_mart`
  WHERE user_id IS NOT NULL
)
SELECT * FROM user_first_touch WHERE rn = 1
```

---

## 쿼리 작성 체크리스트

- [ ] 사용할 테이블의 **식별자**가 올바른가?
- [ ] `ep_event_label`을 사용하고 있는가? (event_name 대신)
- [ ] 시간 필터가 올바른 기준(KST vs UTC)을 사용하는가?
- [ ] 테이블 조인 시 조인 키가 올바른가?
- [ ] `user_id`가 NULL인 행을 고려했는가?
- [ ] 파티션 컬럼(`event_date`)으로 필터했는가? (비용 절감)
