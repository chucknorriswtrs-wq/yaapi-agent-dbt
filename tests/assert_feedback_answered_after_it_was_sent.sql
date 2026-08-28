-- A customer cannot answer a feedback form before it was sent to them.
-- Returns the feedback rows where the answer predates the send, which would
-- mean the two timestamps were swapped upstream or converted inconsistently.

select
    feedback_key,
    feedback_sent_at,
    feedback_answered_at
from {{ ref('stg_sales_database__feedback') }}
where feedback_answered_at < feedback_sent_at
