{{ config(materialized='view') }}

with source_data as (

    select 1 as id, 'alpha' as label
    union all
    select 2 as id, 'beta' as label

)

select
    id,
    label
from source_data
