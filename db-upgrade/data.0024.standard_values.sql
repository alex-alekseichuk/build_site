ALTER TABLE standard ALTER COLUMN official_title DROP NOT NULL;
ALTER TABLE standard ALTER COLUMN standard_document_identifier DROP NOT NULL;

INSERT INTO
    standard
    (standard_org_id, official_title, standard_document_identifier)
SELECT
    DISTINCT
    standard_org_id, standard_document_identifier, standard_document_identifier
FROM
    product_standard; 