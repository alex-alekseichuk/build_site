-- modify PK of package item

BEGIN;

ALTER TABLE package_item ALTER COLUMN package_item_id TYPE varchar(255);

COMMIT;
