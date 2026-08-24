SELECT
  order_id,
  user_name as customer_id,
  order_status,
  datetime(order_date, 'Europe/Paris') as ordered_at,
  datetime(order_approved_date, 'Europe/Paris') as approved_at,
  datetime(pickup_date, 'Europe/Paris') as picked_up_at,
  datetime(delivered_date, 'Europe/Paris') as delivered_at,
  datetime(estimated_time_delivery, 'Europe/Paris') as estimated_delivery_at
FROM {{source('sales_database', 'order')}}