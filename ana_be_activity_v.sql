create or replace force editionable view ana_be_activity_v as
-- first try
select  org.enterprise_id
,       act.activity_group_code
,       act.classification_code
,       act.activity_type_code
,       act.activity_code
,       coalesce(act.start_date, act.gdb_start_date) start_date
,       act.updated_on as date_time
from    ods_organization   org
join    ods_activity       act
  on    act.org_gdb_org_yuid = org.gdb_org_yuid
where   org.type_code = 'ROOT_ORG'
and     org.country_code = 'BE';
comment on column ANA_BE_ACTIVITY_V.ENTERPRISE_ID is 'Unique identification within the Graydon Database that identifies an organization';
comment on column ANA_BE_ACTIVITY_V.ACTIVITY_GROUP_CODE is 'Activity group code is the supplier code of the source that supplied the data';
comment on column ANA_BE_ACTIVITY_V.CLASSIFICATION_CODE is 'The classification code the activity belongs to';
comment on column ANA_BE_ACTIVITY_V.ACTIVITY_TYPE_CODE is 'The type code of the activity: is it a primary or secondary activity';
comment on column ANA_BE_ACTIVITY_V.ACTIVITY_CODE is 'The activity code of the company';
comment on column ANA_BE_ACTIVITY_V.START_DATE is 'Registered start date of the activity in the database';
comment on column ANA_BE_ACTIVITY_V.DATE_TIME is 'Last changed date time of the record in the table';
