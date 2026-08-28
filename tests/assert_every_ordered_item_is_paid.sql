-- An order that carries items must carry at least one payment instalment.
-- The relationships tests check that each payment points at a real order; this
-- checks the other direction, which they cannot: an order billed to nobody.

with orders_with_items as (

    select distinct order_id
    from {{ ref('stg_sales_database__order_item') }}

),

orders_with_payment as (

    select distinct order_id
    from {{ ref('stg_sales_database__payment') }}

)

select items.order_id
from orders_with_items as items
left join orders_with_payment as payments
    on payments.order_id = items.order_id
where payments.order_id is null
