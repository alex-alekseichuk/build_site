-- adding yet another row into table

ALTER TABLE legacy_account_private_file
      ADD COLUMN is_hidden boolean DEFAULT false;