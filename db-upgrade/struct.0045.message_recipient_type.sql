-- add send_type column for recording the to/bcc recipient roles

ALTER TABLE message_recipient ADD COLUMN send_type character varying(10) DEFAULT 'to' NOT NULL -- "to" or "bcc"