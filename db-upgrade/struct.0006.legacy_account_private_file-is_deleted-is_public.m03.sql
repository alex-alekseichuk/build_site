-- change the type of 2 status fields of file object to boolean
BEGIN;

ALTER TABLE legacy_account_private_file
      ALTER COLUMN is_deleted DROP DEFAULT,
      ALTER COLUMN is_public  DROP DEFAULT
;

ALTER TABLE legacy_account_private_file
      ALTER COLUMN is_deleted TYPE boolean
            USING
                CASE WHEN is_deleted = 'true'  THEN true
                     WHEN is_deleted = 'false' THEN false
                     ELSE false
                END,
      ALTER COLUMN is_public TYPE boolean
            USING
                CASE WHEN is_public = 'true'  THEN true
                     WHEN is_public = 'false' THEN false
                     ELSE false
                END,
      ALTER COLUMN is_deleted SET DEFAULT false,
      ALTER COLUMN is_public  SET DEFAULT false
;

COMMIT;