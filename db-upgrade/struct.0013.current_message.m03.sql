-- add current message functionality for each user
BEGIN;

ALTER TABLE legacy_buildsite_user ADD current_message_id character varying(250) NULL;

ALTER TABLE legacy_buildsite_user ADD CONSTRAINT fk_current_message_id FOREIGN KEY (current_message_id)
      REFERENCES legacy_sent_message (message_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

COMMIT;