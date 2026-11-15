UPDATE
    product_standard
SET
    standard_id = (SELECT
        standard_id
    FROM
        standard
    WHERE
        standard.standard_org_id = product_standard.standard_org_id AND
        ((standard.standard_document_identifier = product_standard.standard_document_identifier) OR
        (standard.standard_document_identifier IS NULL AND product_standard.standard_document_identifier IS NULL))
    )
