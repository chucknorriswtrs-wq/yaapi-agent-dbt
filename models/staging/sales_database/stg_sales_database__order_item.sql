with source as (

    select * from {{ source('sales_database', 'order_item') }}

),

renamed as (

    select
        -- surrogate primary key: the source table has no unique column
        concat(
            cast(order_id as string), '-',
            cast(product_id as string), '-',
            cast(seller_id as string)
        ) as order_item_id,

        -- foreign keys
        cast(order_id as string) as order_id,
        cast(product_id as string) as product_id,
        cast(seller_id as string) as seller_id,

        -- measures
        cast(price as numeric) as item_price,
        cast(shipping_cost as numeric) as shipping_cost,
        cast(quantity as int64) as quantity,

        -- timestamps
        cast(pickup_limit_date as timestamp) as pickup_limit_at

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by order_item_id
        order by pickup_limit_at desc
    ) = 1

)

select * from deduplicated
