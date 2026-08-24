-- Staging model for the product source table.
-- Grain: one row per product_id (natural primary key).

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        product_id,
        product_category,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from {{ source('sales_database', 'product') }}

),

renamed as (

    -- The source misspells "lenght": the columns are renamed to length.
    -- Every measure is stored as FLOAT64 upstream but carries no meaningful
    -- decimal part (character counts, photo counts, grams and whole centimetres),
    -- so everything is cast to INT64. Note that BigQuery rounds half away from
    -- zero on a FLOAT64 -> INT64 cast, it does not truncate.
    -- coalesce removes the NULLs so that downstream arithmetic (sum, volume,
    -- shipping weight) never propagates a NULL:
    --   - text -> 'unknown' (623 rows have no category)
    --   - counts and measures -> 0 (610 rows for the counts, 2 rows for the dimensions)
    -- 0 is a sentinel meaning "not provided by the source", not a measured zero.
    select
        product_id,
        coalesce(product_category, 'unknown') as product_category,
        coalesce(cast(product_name_lenght as int64), 0) as product_name_length,
        coalesce(cast(product_description_lenght as int64), 0) as product_description_length,
        coalesce(cast(product_photos_qty as int64), 0) as product_photos_qty,
        coalesce(cast(product_weight_g as int64), 0) as product_weight_g,
        coalesce(cast(product_length_cm as int64), 0) as product_length_cm,
        coalesce(cast(product_height_cm as int64), 0) as product_height_cm,
        coalesce(cast(product_width_cm as int64), 0) as product_width_cm
    from source

),

deduplicated as (

    -- Defensive de-duplication: one row per product_id.
    -- The most documented row wins (most photos, then heaviest), which also
    -- keeps a row carrying real values over one filled with the 0 sentinel.
    select
        product_id,
        product_category,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from renamed
    qualify row_number() over (
        partition by product_id
        order by
            product_photos_qty desc,
            product_weight_g desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    product_id,
    product_category,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from deduplicated
