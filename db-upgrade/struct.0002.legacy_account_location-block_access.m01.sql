-- change the type of the location access field to boolean
-- but it's changed for location table. is it a bug?
BEGIN;

ALTER TABLE legacy_account_location
      ALTER COLUMN block_access DROP DEFAULT;

ALTER TABLE legacy_account_location
      ALTER COLUMN block_access TYPE boolean
            USING
                CASE WHEN block_access = 'true' THEN true
                     WHEN block_access = 'false' THEN false
                     ELSE false
                END,
      ALTER COLUMN block_access SET DEFAULT false
;

COMMIT;
