with source as (

    select * from {{ source('sales_database', 'user') }}

),

renamed as (

    select
        -- primary key (user_name is the customer identifier in the source)
        cast(user_name as string) as customer_id,

        -- attributes (zip code is an identifier, not a number)
        cast(customer_zip_code as string) as customer_zip_code,
        cast(customer_city as string) as customer_city,
        cast(customer_state as string) as customer_state,

        -- technical column from the source loader (always 1)
        cast(row_num as int64) as source_row_num

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by customer_id
        order by source_row_num
    ) = 1

)

select * from deduplicated
