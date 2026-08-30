-- This model generates a small table of random users

{{ config(materialized='table') }}

with user_ids as (
    select 1 as user_id, 'Alice'   as user_name, 'analyst'     as role, 27 as age
    union all
    select 2, 'Bob',     'engineer',   34
    union all
    select 3, 'Charlie', 'manager',    41
    union all
    select 4, 'Diana',   'designer',   29
    union all
    select 5, 'Eve',     'analyst',    32
)

select
    user_id,
    user_name,
    role,
    age,
    current_timestamp() as loaded_at
from user_ids