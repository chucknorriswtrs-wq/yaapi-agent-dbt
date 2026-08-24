-- Staging model for the raw `seller` table of the sales_database source.
-- Grain: one row per seller.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'seller') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- primary key: natural key, already unique in the source
        cast(seller_id as string) as seller_id,

        -- attributes: the zip code is an identifier, not a quantity, so it is
        -- cast from INT64 to STRING; leaving it numeric would drop leading
        -- zeros and invite meaningless arithmetic
        cast(seller_zip_code as string) as seller_zip_code,
        cast(seller_city as string) as seller_city,
        cast(seller_state as string) as seller_state

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per key.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by seller_id
        order by seller_zip_code
    ) = 1

)

-- Final output: cleaned, typed, one row per seller
select * from deduplicated
