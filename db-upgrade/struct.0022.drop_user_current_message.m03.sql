-- we don't need current_message field
-- there is current_message_id field

BEGIN;

ALTER TABLE legacy_buildsite_user
      DROP COLUMN current_message;

COMMIT;
