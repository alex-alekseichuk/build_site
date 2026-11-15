-- change the type of the user access field to boolean
BEGIN;

ALTER TABLE legacy_buildsite_user
      ALTER COLUMN block_access DROP DEFAULT;

ALTER TABLE legacy_buildsite_user
      ALTER COLUMN block_access TYPE boolean
            USING
                CASE WHEN block_access = 'true' THEN true
                     WHEN block_access = 'false' THEN false
                     ELSE false
                END,
      ALTER COLUMN block_access SET DEFAULT false
;

COMMIT;
