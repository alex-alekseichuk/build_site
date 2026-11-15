-- create table package and package item

BEGIN;

 -- probably can be ENUM
ALTER TABLE legacy_account_private_file ADD COLUMN package_toc_type VARCHAR(255) DEFAULT NULL;
 -- reference to a specific template, TBD
ALTER TABLE legacy_account_private_file ADD COLUMN  package_toc_template VARCHAR(255) DEFAULT NULL;
ALTER TABLE legacy_account_private_file ADD COLUMN  package_toc_data text DEFAULT NULL;

CREATE TYPE package_item_type AS ENUM( 'file', 'document', 'toc' );

CREATE TABLE package_item (
  package_item_id BIGSERIAL PRIMARY KEY, -- autoincrement

  package_id VARCHAR(255) NOT NULL REFERENCES legacy_account_private_file(private_file_id),
  position INT NOT NULL,   -- 1, 2, 3, ... to preserve ordering within a package

  item_type package_item_type, 
  document_id VARCHAR(255) REFERENCES document(document_id),
  file_id VARCHAR(255) REFERENCES legacy_account_private_file(private_file_id),
  CONSTRAINT unique_package_item UNIQUE( package_id, position )
);
ALTER TABLE package_item OWNER TO bsadmin;


COMMIT;
