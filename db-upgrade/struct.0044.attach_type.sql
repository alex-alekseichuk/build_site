-- change type for attach_type column

ALTER TABLE message ALTER COLUMN attach_type TYPE character varying(250);
ALTER TABLE message ALTER COLUMN attach_type SET DEFAULT '';
UPDATE message SET attach_type='file' WHERE package_id is not null;
UPDATE message SET attach_type='' WHERE package_id is null;
ALTER TABLE message ALTER COLUMN attach_type SET NOT NULL;

