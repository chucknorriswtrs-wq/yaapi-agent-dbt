SELECT 
  seller_id,
  cast(seller_zip_code as string) as seller_zip_code,
  seller_city,
  seller_state
FROM {{source('sales_database', 'seller')}}