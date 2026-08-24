-- Staging model for the raw `feedback` table of the sales_database source.
-- Grain: one row per feedback form.

with source as (

    -- Raw data, read through the dbt source so that lineage is tracked
    select * from {{ source('sales_database', 'feedback') }}

),

renamed as (

    -- Explicit column list: cast the types and give business-readable names
    select
        -- primary key: natural key, already unique in the source
        cast(feedback_id as string) as feedback_id,

        -- foreign key to stg_sales_database__order
        cast(order_id as string) as order_id,

        -- attribute: satisfaction score left by the customer
        cast(feedback_score as int64) as feedback_score,

        -- timestamps: the source stores a full date + time, so the values stay
        -- TIMESTAMP; casting to DATE would destroy the time component
        cast(feedback_form_sent_date as timestamp) as feedback_form_sent_at,
        cast(feedback_answer_date as timestamp) as feedback_answered_at

    from source

),

deduplicated as (

    -- Defensive de-duplication: keep one row per key, latest answer first.
    -- No duplicate exists in the source today; this protects future loads.
    select *
    from renamed
    qualify row_number() over (
        partition by feedback_id
        order by feedback_answered_at desc
    ) = 1

)

-- Final output: cleaned, typed, one row per feedback
select * from deduplicated
