
-- rename table with files
ALTER TABLE legacy_account_private_file RENAME TO file;


-- rename primary key field
ALTER TABLE file RENAME COLUMN private_file_id TO file_id;