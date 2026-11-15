-- add body content field for sent messages table
BEGIN;

ALTER TABLE legacy_sent_message ADD body text;

COMMIT;