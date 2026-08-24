-- Staging model for the payment source table.
-- Grain: one row per payment instalment attached to an order.
-- The source has no primary key, so a surrogate key is built below.

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    from {{ source('sales_database', 'payment') }}

),

renamed as (

    -- Surrogate primary key: an order can be paid in several sequential parts,
    -- so order_id alone is not unique but order_id + payment_sequential is.
    -- payment_value is cast to NUMERIC to keep monetary sums exact.
    select
        concat(order_id, '-', cast(payment_sequential as string)) as payment_id,
        order_id,
        cast(payment_sequential as int64) as payment_sequential,
        payment_type,
        cast(payment_installments as int64) as payment_installments,
        cast(payment_value as numeric) as payment_value
    from source

),

deduplicated as (

    -- Defensive de-duplication: one row per surrogate key.
    select
        payment_id,
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    from renamed
    qualify row_number() over (
        partition by payment_id
        order by
            payment_value desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    payment_id,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from deduplicated
