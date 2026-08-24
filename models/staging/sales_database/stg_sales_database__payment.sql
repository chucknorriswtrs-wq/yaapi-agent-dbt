-- Staging model for the raw `payment` table of the sales_database source.
-- Grain: one row per payment attached to an order.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'payment') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- surrogate primary key: the source table has no unique column, so the
        -- order id and the payment rank are concatenated
        concat(
            cast(order_id as string), '-',
            cast(payment_sequential as string)
        ) as payment_id,

        -- foreign key to stg_sales_database__order
        cast(order_id as string) as order_id,

        -- attributes: rank of the payment within the order, method used, and
        -- the number of instalments agreed with the customer
        cast(payment_sequential as int64) as payment_sequential,
        cast(payment_type as string) as payment_type,
        cast(payment_installments as int64) as payment_installments,

        -- measure: money cast from FLOAT64 to NUMERIC so that sums are exact
        cast(payment_value as numeric) as payment_value

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per surrogate key.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by payment_id
        order by payment_value desc
    ) = 1

)

-- Final output: cleaned, typed, one row per payment
select * from deduplicated
