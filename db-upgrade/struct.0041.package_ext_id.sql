-- adding yet another row into table
-- it is necessary for submittal post-to-url feature

ALTER TABLE file ADD COLUMN package_ext_id character varying(250) null;
create index package_ext_id_i on file (package_ext_id);

