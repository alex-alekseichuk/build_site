ALTER TABLE legacy_account_private_person DROP CONSTRAINT fk_app_apc;

ALTER TABLE legacy_account_private_person ADD COLUMN owner VARCHAR(255) DEFAULT NULL;

ALTER TABLE legacy_account_private_person ADD CONSTRAINT fk_app_al FOREIGN KEY (owner) REFERENCES legacy_account_location (account_location_id) ON UPDATE CASCADE INITIALLY DEFERRED;