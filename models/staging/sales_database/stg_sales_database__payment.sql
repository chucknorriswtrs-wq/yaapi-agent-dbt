with source as (

    select * from {{ source('sales_database', 'payment') }}

),

renamed as (

    select
        -- surrogate primary key: the source table has no unique column
        concat(
            cast(order_id as string), '-',
            cast(payment_sequential as string)
        ) as payment_id,

        -- foreign key
        cast(order_id as string) as order_id,

        -- attributes
        cast(payment_sequential as int64) as payment_sequential,
        cast(payment_type as string) as payment_type,
        cast(payment_installments as int64) as payment_installments,

        -- measures
        cast(payment_value as numeric) as payment_value

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by payment_id
        order by payment_value desc
    ) = 1

)

select * from deduplicated
