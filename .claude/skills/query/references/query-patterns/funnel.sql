-- 퍼널 전환율 계산
-- 사용 테이블: original_mart
-- ep_event_label 기준으로 퍼널 단계 정의

WITH funnel AS (
  SELECT
    user_id,
    MAX(CASE WHEN ep_event_label = '{{step1_label}}' THEN 1 ELSE 0 END) AS step1,
    MAX(CASE WHEN ep_event_label = '{{step2_label}}' THEN 1 ELSE 0 END) AS step2,
    MAX(CASE WHEN ep_event_label = '{{step3_label}}' THEN 1 ELSE 0 END) AS step3
  FROM `project_name.dataset.original_mart`
  WHERE event_date BETWEEN '{{start_date}}' AND '{{end_date}}'
    AND user_id IS NOT NULL
  GROUP BY user_id
)
SELECT
  COUNT(CASE WHEN step1 = 1 THEN 1 END) AS step1_users,
  COUNT(CASE WHEN step1 = 1 AND step2 = 1 THEN 1 END) AS step2_users,
  COUNT(CASE WHEN step1 = 1 AND step2 = 1 AND step3 = 1 THEN 1 END) AS step3_users,
  SAFE_DIVIDE(
    COUNT(CASE WHEN step1 = 1 AND step2 = 1 THEN 1 END),
    COUNT(CASE WHEN step1 = 1 THEN 1 END)
  ) AS step1_to_step2_rate,
  SAFE_DIVIDE(
    COUNT(CASE WHEN step1 = 1 AND step2 = 1 AND step3 = 1 THEN 1 END),
    COUNT(CASE WHEN step1 = 1 AND step2 = 1 THEN 1 END)
  ) AS step2_to_step3_rate
FROM funnel
