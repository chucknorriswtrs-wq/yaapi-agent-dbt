SELECT  
  concat(feedback_id, '-', order_id) as feedback_key,
  order_id,
  cast(feedback_score as int64) as feedback_score,
  datetime(feedback_form_sent_date, 'Europe/Paris') as feedback_sent_at,
  datetime(feedback_answer_date, 'Europe/Paris') as feedback_answered_at
FROM {{source('sales_database', 'feedback')}}