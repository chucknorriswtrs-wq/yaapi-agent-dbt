SELECT  
  concat(order_id, '-', product_id, '-', seller_id) as order_item_id,
  order_id,
  product_id,
  seller_id,
  datetime(pickup_limit_date, 'Europe/Paris') as pickup_limit_at,
  cast(price as numeric) as item_price, -- better for financial
  cast(shipping_cost as numeric) as shipping_cost,
  cast(quantity as int64) as quantity
FROM {{source('sales_database', 'order_item')}}