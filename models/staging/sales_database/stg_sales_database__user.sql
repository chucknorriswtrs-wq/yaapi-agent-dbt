-- Staging model for the user source table.
-- Grain: one row per customer (natural primary key, named user_name upstream).

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        user_name,
        customer_zip_code,
        customer_city,
        customer_state,
        row_num
    from {{ source('sales_database', 'user') }}

),

renamed as (

    -- user_name holds the customer key, not a person's name: renamed customer_id so it
    -- matches the column it joins to in the order table.
    -- The zip code is cast to STRING (identifier, keeps leading zeros).
    -- row_num is a technical extraction counter: prefixed source_ to flag it as such.
    select
        cast(user_name as string) as customer_id,
        cast(customer_zip_code as string) as customer_zip_code,
        customer_city,
        customer_state,
        cast(row_num as int64) as source_row_num
    from source

),

deduplicated as (

    -- Defensive de-duplication: keep the first extracted row per customer_id.
    select
        customer_id,
        customer_zip_code,
        customer_city,
        customer_state,
        source_row_num
    from renamed
    qualify row_number() over (
        partition by customer_id
        order by
            source_row_num asc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    customer_id,
    customer_zip_code,
    customer_city,
    customer_state,
    source_row_num
from deduplicated
