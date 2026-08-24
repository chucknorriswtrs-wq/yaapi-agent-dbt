-- Staging model for the feedback source table.
-- Grain: one row per (feedback_id, order_id) pair.
-- feedback_id alone is NOT unique: 802 ids are shared by several orders
-- (same score, same dates, only order_id differs), so the primary key is a surrogate one.

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
    -- feedback_key is the surrogate primary key of the model: feedback_id concatenated with order_id,
    -- which is the only combination unique in the source data.
    -- The raw columns are UTC TIMESTAMP instants: datetime(<ts>, 'Europe/Paris') converts them
    -- to Paris local wall-clock DATETIME, the business time zone used by every downstream layer.
    -- The time of day is kept, only the reference time zone changes.
    select
        concat(feedback_id, '-', order_id) as feedback_key,
        feedback_id,
        order_id,
        cast(feedback_score as int64) as feedback_score,
        datetime(feedback_form_sent_date, 'Europe/Paris') as feedback_sent_at,
        datetime(feedback_answer_date, 'Europe/Paris') as feedback_answered_at
    from source

),

deduplicated as (

    -- Defensive de-duplication on the real grain: keep the most recent record
    -- per (feedback_id, order_id). No true duplicate exists today, this guards future loads.
    select
        feedback_key,
        feedback_id,
        order_id,
        feedback_score,
        feedback_sent_at,
        feedback_answered_at
    from renamed
    qualify row_number() over (
        partition by feedback_id, order_id
        order by
            feedback_answered_at desc,
            feedback_sent_at desc
    ) = 1

)

-- Final output exposed to the downstream layers.
select
    feedback_key,
    feedback_id,
    order_id,
    feedback_score,
    feedback_sent_at,
    feedback_answered_at
from deduplicated
