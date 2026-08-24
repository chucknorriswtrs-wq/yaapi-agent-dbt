-- Staging model for the raw `product` table of the sales_database source.
-- Grain: one row per product.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'product') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- primary key: natural key, already unique in the source
        cast(product_id as string) as product_id,

        -- attribute: product taxonomy
        cast(product_category as string) as product_category,

        -- counts stored as FLOAT64 in the source although they can only be
        -- whole numbers, so they are cast to INT64. The source misspells
        -- "lenght", fixed here to "length".
        cast(product_name_lenght as int64) as product_name_length,
        cast(product_description_lenght as int64) as product_description_length,
        cast(product_photos_qty as int64) as product_photos_qty,

        -- physical dimensions: kept decimal but cast to NUMERIC so that
        -- shipping computations stay exact
        cast(product_weight_g as numeric) as product_weight_g,
        cast(product_length_cm as numeric) as product_length_cm,
        cast(product_height_cm as numeric) as product_height_cm,
        cast(product_width_cm as numeric) as product_width_cm

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per key.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by product_id
        order by product_category
    ) = 1

)

-- Final output: cleaned, typed, one row per product
select * from deduplicated
