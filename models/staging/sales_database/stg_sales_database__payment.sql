SELECT 
  concat(order_id, '-', cast(payment_sequential as string)) as payment_id,
  order_id,
  payment_sequential as payment_sequential,
  payment_type,
  payment_installments as payment_installments,
  cast(payment_value as numeric) as payment_value
FROM {{source('sales_database', 'payment')}}