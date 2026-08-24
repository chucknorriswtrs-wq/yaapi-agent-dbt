-- Staging model for the order source table.
-- Grain: one row per order_id (natural primary key).

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        order_id,
        user_name,
        order_status,
        order_date,
        order_approved_date,
        pickup_date,
        delivered_date,
        estimated_time_delivery
    from {{ source('sales_database', 'order') }}

),

renamed as (

    -- user_name is not a name but the customer key that joins to the user table:
    -- it is renamed customer_id so the relationship is explicit.
    -- All milestone columns are renamed to the *_at convention and kept as TIMESTAMP,
    -- because the time of day drives the delivery delay measures downstream.
    select
        order_id,
        cast(user_name as string) as customer_id,
        order_status,
        cast(order_date as timestamp) as ordered_at,
        cast(order_approved_date as timestamp) as approved_at,
        cast(pickup_date as timestamp) as picked_up_at,
        cast(delivered_date as timestamp) as delivered_at,
        cast(estimated_time_delivery as timestamp) as estimated_delivery_at
    from source

),

deduplicated as (

    -- Defensive de-duplication: keep the most advanced record per order_id.
    select
        order_id,
        customer_id,
        order_status,
        ordered_at,
        approved_at,
        picked_up_at,
        delivered_at,
        estimated_delivery_at
    from renamed
    qualify row_number() over (
        partition by order_id
        order by
            delivered_at desc,
            ordered_at desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    order_id,
    customer_id,
    order_status,
    ordered_at,
    approved_at,
    picked_up_at,
    delivered_at,
    estimated_delivery_at
from deduplicated
