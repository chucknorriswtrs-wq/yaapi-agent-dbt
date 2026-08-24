-- Staging model for the feedback source table.
-- Grain: one row per feedback_id (natural primary key).

with source as (

    -- Read every column explicitly from the raw source table, no transformation here.
    select
        feedback_id,
        order_id,
        feedback_score,
        feedback_form_sent_date,
        feedback_answer_date
    from {{ source('sales_database', 'feedback') }}

),

renamed as (

    -- Apply naming conventions (event timestamps end with _at) and pin the data types.
    -- The raw columns are UTC TIMESTAMP instants: datetime(<ts>, 'Europe/Paris') converts them
    -- to Paris local wall-clock DATETIME, the business time zone used by every downstream layer.
    -- The time of day is kept, only the reference time zone changes.
    select
        feedback_id,
        order_id,
        cast(feedback_score as int64) as feedback_score,
        datetime(feedback_form_sent_date, 'Europe/Paris') as feedback_sent_at,
        datetime(feedback_answer_date, 'Europe/Paris') as feedback_answered_at
    from source

),

deduplicated as (

    -- Defensive de-duplication: keep the most recent record per feedback_id.
    select
        feedback_id,
        order_id,
        feedback_score,
        feedback_sent_at,
        feedback_answered_at
    from renamed
    qualify row_number() over (
        partition by feedback_id
        order by
            feedback_answered_at desc,
            feedback_sent_at desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    feedback_id,
    order_id,
    feedback_score,
    feedback_sent_at,
    feedback_answered_at
from deduplicated
