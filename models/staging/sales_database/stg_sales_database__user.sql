SELECT 
  cast(user_name as string) as customer_id,
  cast(customer_zip_code as string) as customer_zip_code,
  customer_city,
  customer_state, 
FROM {{source('sales_database','user')}}