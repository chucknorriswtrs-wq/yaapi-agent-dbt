with source as (

    select * from {{ source('sales_database', 'seller') }}

),

renamed as (

    select
        -- primary key
        cast(seller_id as string) as seller_id,

        -- attributes (zip code is an identifier, not a number)
        cast(seller_zip_code as string) as seller_zip_code,
        cast(seller_city as string) as seller_city,
        cast(seller_state as string) as seller_state

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by seller_id
        order by seller_zip_code
    ) = 1

)

select * from deduplicated
