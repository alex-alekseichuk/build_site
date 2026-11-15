-- change the type of the document is_generic field to boolean
BEGIN;

ALTER TABLE document
      ALTER COLUMN is_generic  DROP DEFAULT
;

ALTER TABLE document
      ALTER COLUMN is_generic TYPE boolean
            USING
                CASE WHEN is_generic = 'true'  THEN true
                     WHEN is_generic = 'false' THEN false
                     ELSE false
                END,
      ALTER COLUMN is_generic SET DEFAULT false
;

COMMIT;
