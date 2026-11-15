-- doing send message upgrade to store all attachments in database as packages
ALTER TABLE legacy_sent_message
      ADD COLUMN package_id varchar(250) DEFAULT NULL;

-- create index on derived_path for best perfomance of data.0004.....pl
CREATE INDEX i_document_derived_path ON document(derived_path);
