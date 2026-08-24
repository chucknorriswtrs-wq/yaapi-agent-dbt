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
    -- All milestone columns are renamed to the *_at convention and converted from UTC TIMESTAMP
    -- to Paris local DATETIME with datetime(<ts>, 'Europe/Paris'): the business time zone.
    -- The time of day is preserved, it drives the delivery delay measures downstream.
    select
        order_id,
        cast(user_name as string) as customer_id,
        order_status,
        datetime(order_date, 'Europe/Paris') as ordered_at,
        datetime(order_approved_date, 'Europe/Paris') as approved_at,
        datetime(pickup_date, 'Europe/Paris') as picked_up_at,
        datetime(delivered_date, 'Europe/Paris') as delivered_at,
        datetime(estimated_time_delivery, 'Europe/Paris') as estimated_delivery_at
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
