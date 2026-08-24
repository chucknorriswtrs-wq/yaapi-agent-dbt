-- Staging model for the seller source table.
-- Grain: one row per seller_id (natural primary key).

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        seller_id,
        seller_zip_code,
        seller_city,
        seller_state
    from {{ source('sales_database', 'seller') }}

),

renamed as (

    -- A zip code is an identifier, not a measure: stored as INT64 upstream it loses its
    -- leading zeros and invites meaningless arithmetic, so it is cast back to STRING.
    select
        seller_id,
        cast(seller_zip_code as string) as seller_zip_code,
        seller_city,
        seller_state
    from source

),

deduplicated as (

    -- Defensive de-duplication: one row per seller_id.
    select
        seller_id,
        seller_zip_code,
        seller_city,
        seller_state
    from renamed
    qualify row_number() over (
        partition by seller_id
        order by
            seller_zip_code desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    seller_id,
    seller_zip_code,
    seller_city,
    seller_state
from deduplicated
