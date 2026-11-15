-- add current package functionality for each user
BEGIN;

ALTER TABLE legacy_buildsite_user ADD current_package_id character varying(250) NULL;

ALTER TABLE legacy_buildsite_user ADD CONSTRAINT fk_current_package_id FOREIGN KEY (current_package_id)
      REFERENCES legacy_account_private_file(private_file_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;
COMMIT;
