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
    -- Character counts and photo counts are stored as FLOAT64 upstream although they are
    -- discrete counts, so they are cast to INT64.
    -- Physical dimensions stay decimal and are cast to NUMERIC for exact arithmetic.
    select
        product_id,
        product_category,
        cast(product_name_lenght as int64) as product_name_length,
        cast(product_description_lenght as int64) as product_description_length,
        cast(product_photos_qty as int64) as product_photos_qty,
        cast(product_weight_g as numeric) as product_weight_g,
        cast(product_length_cm as numeric) as product_length_cm,
        cast(product_height_cm as numeric) as product_height_cm,
        cast(product_width_cm as numeric) as product_width_cm
    from source

),

deduplicated as (

    -- Defensive de-duplication: one row per product_id.
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
