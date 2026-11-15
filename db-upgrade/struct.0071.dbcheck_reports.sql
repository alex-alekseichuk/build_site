-- create table dbcheck_reports

CREATE TABLE dbcheck_reports (

  --id | rule_id | bsa_class_name | object_id | info_fields | bad_fields

  dbcheck_reports_id BIGSERIAL PRIMARY KEY, -- autoincrement
  rule_id VARCHAR(255) NOT NULL,
  bsa_class_name VARCHAR(255) NOT NULL,
  object_id VARCHAR(255) NOT NULL,
  info_fields TEXT,
  bad_fields TEXT,

  expired boolean DEFAULT false -- needs to be deleted after next successfull report generation

);
ALTER TABLE dbcheck_reports OWNER TO bsadmin;

