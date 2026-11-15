-- added column to save special md5 hash to identify the message to get attachment send as URL
-- added column to save the type of attachment

ALTER TABLE message ADD COLUMN message_ext_id character varying(250) null;
create index message_ext_id_i on message (message_ext_id);

CREATE TYPE message_attach_type AS ENUM( '', 'file', 'url' );
ALTER TABLE message ADD COLUMN attach_type message_attach_type null;
UPDATE message SET attach_type = '';


