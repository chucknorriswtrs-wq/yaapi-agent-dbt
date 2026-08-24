with source as (

    select * from {{ source('sales_database', 'product') }}

),

renamed as (

    select
        -- primary key
        cast(product_id as string) as product_id,

        -- attributes
        cast(product_category as string) as product_category,

        -- counts stored as float in the source, cast to integer
        cast(product_name_lenght as int64) as product_name_length,
        cast(product_description_lenght as int64) as product_description_length,
        cast(product_photos_qty as int64) as product_photos_qty,

        -- dimensions
        cast(product_weight_g as numeric) as product_weight_g,
        cast(product_length_cm as numeric) as product_length_cm,
        cast(product_height_cm as numeric) as product_height_cm,
        cast(product_width_cm as numeric) as product_width_cm

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by product_id
        order by product_category
    ) = 1

)

select * from deduplicated
