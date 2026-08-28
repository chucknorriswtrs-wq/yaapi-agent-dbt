-- An order moves through its milestones in one direction only:
-- ordered -> approved -> picked up -> delivered.
-- This test returns the orders where that sequence goes backwards, which no
-- generic test can express. Rows with a NULL milestone are not returned: a
-- pending order has simply not reached that step yet.

select
    order_id,
    ordered_at,
    approved_at,
    picked_up_at,
    delivered_at
from {{ ref('stg_sales_database__order') }}
where approved_at < ordered_at
   or picked_up_at < approved_at
   or delivered_at < picked_up_at
