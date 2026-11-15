BEGIN;

-- Table: msds_group

-- DROP TABLE msds_document;
-- DROP TABLE msds_group;

CREATE TABLE msds_group
(
  msds_group_id character varying(250) NOT NULL,
  "name" character varying(250),
  "position" integer,
  CONSTRAINT ps_msds_group PRIMARY KEY (msds_group_id)
)
WITH (OIDS=TRUE);
ALTER TABLE msds_group OWNER TO bsadmin;


-- Table: msds_document


CREATE TABLE msds_document
(
  msds_group_id character varying(250) NOT NULL,
  document_id character varying(250) NOT NULL,
  "position" smallint,
  CONSTRAINT pk_msds_document PRIMARY KEY (msds_group_id, document_id),
  CONSTRAINT fk_document_id FOREIGN KEY (document_id)
      REFERENCES "document" (document_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT fk_msds_group_id FOREIGN KEY (msds_group_id)
      REFERENCES msds_group (msds_group_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (OIDS=TRUE);
ALTER TABLE msds_document OWNER TO bsadmin;

-- Index: fki_document

-- DROP INDEX fki_document;

CREATE INDEX fki_document
  ON msds_document
  USING btree
  (document_id);

COMMIT;