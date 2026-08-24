with source as (

    select * from {{ source('sales_database', 'feedback') }}

),

renamed as (

    select
        -- primary key
        cast(feedback_id as string) as feedback_id,

        -- foreign key
        cast(order_id as string) as order_id,

        -- attributes
        cast(feedback_score as int64) as feedback_score,

        -- timestamps
        cast(feedback_form_sent_date as timestamp) as feedback_form_sent_at,
        cast(feedback_answer_date as timestamp) as feedback_answered_at

    from source

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by feedback_id
        order by feedback_answered_at desc
    ) = 1

)

select * from deduplicated
