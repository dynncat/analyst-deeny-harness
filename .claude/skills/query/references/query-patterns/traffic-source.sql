-- 트래픽 소스 식별 (유저별 최초 유입 소스)
-- 사용 테이블: original_mart
-- ROW_NUMBER로 가장 오래된 행의 소스 값을 가져옴

WITH user_first_touch AS (
  SELECT
    user_id,
    event_date,
    -- 트래픽 소스 관련 컬럼들 (실제 컬럼명은 확인 필요)
    -- ep_source, ep_medium, ep_campaign 등
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY event_timestamp ASC
    ) AS rn
  FROM `project_name.dataset.original_mart`
  WHERE user_id IS NOT NULL
    AND event_date BETWEEN '{{start_date}}' AND '{{end_date}}'
)
SELECT
  user_id,
  event_date AS first_touch_date
  -- , ep_source, ep_medium, ep_campaign
FROM user_first_touch
WHERE rn = 1
