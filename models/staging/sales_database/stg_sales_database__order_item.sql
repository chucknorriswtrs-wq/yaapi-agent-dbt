-- Staging model for the raw `order_item` table of the sales_database source.
-- Grain: one row per product sold by a seller within an order.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'order_item') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- surrogate primary key: the source table has no unique column, so the
        -- three columns that together identify a line are concatenated
        concat(
            cast(order_id as string), '-',
            cast(product_id as string), '-',
            cast(seller_id as string)
        ) as order_item_id,

        -- foreign keys to the order, product and seller staging models
        cast(order_id as string) as order_id,
        cast(product_id as string) as product_id,
        cast(seller_id as string) as seller_id,

        -- measures: money cast from FLOAT64 to NUMERIC so that sums are exact
        -- and never drift by rounding; quantity is a whole number
        cast(price as numeric) as item_price,
        cast(shipping_cost as numeric) as shipping_cost,
        cast(quantity as int64) as quantity,

        -- timestamp: a shipping deadline expressed to the hour in the source,
        -- so it stays TIMESTAMP rather than being truncated to a DATE
        cast(pickup_limit_date as timestamp) as pickup_limit_at

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per surrogate key.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by order_item_id
        order by pickup_limit_at desc
    ) = 1

)

-- Final output: cleaned, typed, one row per order line
select * from deduplicated
