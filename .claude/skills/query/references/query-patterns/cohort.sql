-- 코호트 리텐션 분석
-- 사용 테이블: original_mart
-- 가입(또는 first_open) 기준 코호트 구성

WITH user_cohort AS (
  -- 유저별 최초 활동일 (코호트 기준)
  SELECT
    user_id,
    MIN(event_date) AS cohort_date
  FROM `project_name.dataset.original_mart`
  WHERE event_date BETWEEN '{{cohort_start}}' AND '{{cohort_end}}'
    AND user_id IS NOT NULL
  GROUP BY user_id
),
user_activity AS (
  SELECT DISTINCT
    a.user_id,
    a.event_date
  FROM `project_name.dataset.original_mart` a
  WHERE a.event_date BETWEEN '{{cohort_start}}' AND '{{analysis_end}}'
    AND a.user_id IS NOT NULL
)
SELECT
  c.cohort_date,
  DATE_DIFF(a.event_date, c.cohort_date, DAY) AS day_n,
  COUNT(DISTINCT c.user_id) AS cohort_size,
  COUNT(DISTINCT a.user_id) AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT a.user_id), COUNT(DISTINCT c.user_id)) AS retention_rate
FROM user_cohort c
LEFT JOIN user_activity a
  ON c.user_id = a.user_id
GROUP BY c.cohort_date, day_n
ORDER BY c.cohort_date, day_n
