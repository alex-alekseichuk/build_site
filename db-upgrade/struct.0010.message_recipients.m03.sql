-- add special table to hold sent messages recipients
BEGIN;

DROP TABLE IF EXISTS message_recipient;
DROP TYPE IF EXISTS message_status;
DROP TYPE IF EXISTS message_type;

--CREATE TYPE message_type AS ENUM ('fax', 'email');
--CREATE TYPE message_status AS ENUM ('pending', 'processed');
--CREATE TYPE recipient_status AS ENUM ('pending', 'sent', 'received', 'failed');
CREATE TABLE message_recipient
(
  recipient_id character varying(250) NOT NULL,
  message_id character varying(250) NOT NULL,
  --type message_type NOT NULL,
  type character varying(10) NOT NULL,
  address character varying(250) NOT NULL,
  contact_id character varying(250),
  --status message_status NOT NULL DEFAULT 'pending',
  status character varying(250) NOT NULL DEFAULT 'pending',
  CONSTRAINT message_id_fkey FOREIGN KEY (message_id)
      REFERENCES legacy_sent_message (message_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT pk_message_recipient PRIMARY KEY (recipient_id)
);
ALTER TABLE message_recipient OWNER TO bsadmin;


ALTER TABLE legacy_sent_message ALTER COLUMN recipient_fkey DROP NOT NULL;
ALTER TABLE legacy_sent_message ALTER COLUMN recipient_address DROP NOT NULL;
ALTER TABLE legacy_sent_message ALTER COLUMN recipient_address_type DROP NOT NULL;
ALTER TABLE legacy_sent_message ALTER COLUMN time_sent DROP NOT NULL;

COMMIT;
