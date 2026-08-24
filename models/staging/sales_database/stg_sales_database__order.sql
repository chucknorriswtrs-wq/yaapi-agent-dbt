with source as (

    select * from {{ source('sales_database', 'order') }}

),

renamed as (

    select
        -- primary key
        cast(order_id as string) as order_id,

        -- foreign key (user_name is the customer identifier in the source)
        cast(user_name as string) as customer_id,

        -- attributes
        cast(order_status as string) as order_status,

        -- timestamps
        cast(order_date as timestamp) as ordered_at,
        cast(order_approved_date as timestamp) as approved_at,
        cast(pickup_date as timestamp) as picked_up_at,
        cast(delivered_date as timestamp) as delivered_at,
        cast(estimated_time_delivery as timestamp) as estimated_delivery_at

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by order_id
        order by ordered_at desc
    ) = 1

)

select * from deduplicated
