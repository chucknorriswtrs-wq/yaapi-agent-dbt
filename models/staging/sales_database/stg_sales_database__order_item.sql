-- Staging model for the order_item source table.
-- Grain: one row per order / product / seller line.
-- The source has no primary key, so a surrogate key is built below.

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        order_id,
        product_id,
        seller_id,
        pickup_limit_date,
        price,
        shipping_cost,
        quantity
    from {{ source('sales_database', 'order_item') }}

),

renamed as (

    -- Surrogate primary key: no single column is unique, the three foreign keys together are.
    -- price is renamed item_price to make clear it is the unit line price, not an order total.
    -- Monetary FLOAT64 values are cast to NUMERIC to avoid floating point rounding on sums.
    -- pickup_limit_date is converted from UTC TIMESTAMP to Paris local DATETIME:
    -- the carrier deadline is an hour of the day, read in the business time zone.
    select
        concat(order_id, '-', product_id, '-', seller_id) as order_item_id,
        order_id,
        product_id,
        seller_id,
        datetime(pickup_limit_date, 'Europe/Paris') as pickup_limit_at,
        cast(price as numeric) as item_price,
        cast(shipping_cost as numeric) as shipping_cost,
        cast(quantity as int64) as quantity
    from source

),

deduplicated as (

    -- Defensive de-duplication: one row per surrogate key.
    select
        order_item_id,
        order_id,
        product_id,
        seller_id,
        pickup_limit_at,
        item_price,
        shipping_cost,
        quantity
    from renamed
    qualify row_number() over (
        partition by order_item_id
        order by
            pickup_limit_at desc,
            item_price desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    order_item_id,
    order_id,
    product_id,
    seller_id,
    pickup_limit_at,
    item_price,
    shipping_cost,
    quantity
from deduplicated
