-- DAU (Daily Active Users) 계산
-- 사용 테이블: original_mart
-- 식별자: user_id (로그인 유저) 또는 user_pseudo_id (전체)

SELECT
  event_date,
  COUNT(DISTINCT user_id) AS dau_logged_in,
  COUNT(DISTINCT user_pseudo_id) AS dau_all
FROM `project_name.dataset.original_mart`
WHERE event_date BETWEEN '{{start_date}}' AND '{{end_date}}'
GROUP BY event_date
ORDER BY event_date
