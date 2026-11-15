ALTER TABLE msds_document DROP CONSTRAINT pk_msds_document;
CREATE UNIQUE INDEX msds_document_ui ON msds_document (msds_group_id, document_id);
ALTER TABLE msds_document ADD column msds_document_id serial primary key;