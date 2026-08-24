-- Staging model for the raw `order` table of the sales_database source.
-- Grain: one row per order.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'order') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- primary key: natural key, already unique in the source
        cast(order_id as string) as order_id,

        -- foreign key: the source calls it user_name but it holds the customer
        -- identifier, so it is renamed to match stg_sales_database__user
        cast(user_name as string) as customer_id,

        -- attribute: lifecycle status of the order (delivered, shipped, ...)
        cast(order_status as string) as order_status,

        -- timestamps: every milestone carries a time of day in the source, so
        -- they stay TIMESTAMP; a DATE cast would make delays between two
        -- milestones impossible to measure in hours
        cast(order_date as timestamp) as ordered_at,
        cast(order_approved_date as timestamp) as approved_at,
        cast(pickup_date as timestamp) as picked_up_at,
        cast(delivered_date as timestamp) as delivered_at,
        cast(estimated_time_delivery as timestamp) as estimated_delivery_at

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per key, most recent first.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by order_id
        order by ordered_at desc
    ) = 1

)

-- Final output: cleaned, typed, one row per order
select * from deduplicated
