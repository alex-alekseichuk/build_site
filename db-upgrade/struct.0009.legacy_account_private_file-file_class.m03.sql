-- create special enum type for folder obejct types
-- and use it in folder objects table

-- this script does not work within a single transaction, but works if it is split into several transactions.
-- see http://trac.ahinea.com/bs-app/ticket/39

BEGIN;

DROP TYPE IF EXISTS file_class_type;
CREATE TYPE file_class_type AS ENUM ('folder', 'archive', 'file', 'shortcut');

ALTER TABLE legacy_account_private_file RENAME COLUMN file_class TO file_class2;
ALTER TABLE legacy_account_private_file ADD COLUMN file_class file_class_type NOT NULL DEFAULT 'file';

UPDATE legacy_account_private_file SET file_class='folder' WHERE file_class2='folder';
UPDATE legacy_account_private_file SET file_class='archive' WHERE file_class2='archive';
UPDATE legacy_account_private_file SET file_class='file' WHERE file_class2='file';
UPDATE legacy_account_private_file SET file_class='shortcut' WHERE file_class2='shortcut';

COMMIT;

ALTER TABLE legacy_account_private_file DROP COLUMN file_class2;
