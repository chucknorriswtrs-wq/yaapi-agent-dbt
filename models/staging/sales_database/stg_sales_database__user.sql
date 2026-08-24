-- Staging model for the raw `user` table of the sales_database source.
-- Grain: one row per customer.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'user') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- primary key: the source calls it user_name but it holds the customer
        -- identifier, so it is renamed to customer_id and used as the key
        cast(user_name as string) as customer_id,

        -- attributes: the zip code is an identifier, not a quantity, so it is
        -- cast from INT64 to STRING; leaving it numeric would drop leading
        -- zeros and invite meaningless arithmetic
        cast(customer_zip_code as string) as customer_zip_code,
        cast(customer_city as string) as customer_city,
        cast(customer_state as string) as customer_state,

        -- technical column produced by the loader, kept but prefixed so that
        -- it is never mistaken for a business attribute
        cast(row_num as int64) as source_row_num

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per key.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by customer_id
        order by source_row_num
    ) = 1

)

-- Final output: cleaned, typed, one row per customer
select * from deduplicated
