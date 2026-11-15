
-- add category_counts view
CREATE OR REPLACE VIEW category_counts_v AS
SELECT
	cats_admin.category_id as category_id
	,cats.products as products
	,cats.manufacturers as manufacturers
	,cats_admin.products as products_admin
	,cats_admin.manufacturers as manufacturers_admin
FROM
	(
		SELECT
			p.category_id as category_id
			,count(DISTINCT p.product_id) as products
			,count(DISTINCT c.company_id) as manufacturers
		FROM
			product as p
			join company as c ON p.manufacturer_id = c.company_id
		group by
			p.category_id
		order by
			p.category_id
	) AS cats_admin
	LEFT JOIN
	(
		SELECT
			p.category_id as category_id
			,count(DISTINCT p.product_id) as products
			,count(DISTINCT c.company_id) as manufacturers
		FROM
			product as p
			join company as c
				ON p.manufacturer_id = c.company_id
					AND c.suppress_reason_code = '' AND c.public_visible
		WHERE
			p.suppress_reason_code = '' AND p.public_visible
		group by
			p.category_id
		order by
			p.category_id
	) AS cats
	ON cats_admin.category_id = cats.category_id

ORDER BY
	cats_admin.category_id
;

-- add SP to create or update mat.view
CREATE OR REPLACE FUNCTION create_update_category_counts() RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql AS '
DECLARE 
    entry matviews%ROWTYPE;
BEGIN
    SELECT * INTO entry FROM matviews WHERE mv_name = ''category_counts'';
    IF NOT FOUND THEN
        PERFORM create_matview(''category_counts'', ''category_counts_v'');
    ELSE
        ALTER TABLE category_counts DROP CONSTRAINT category_counts_category_id;
        PERFORM refresh_matview(''category_counts'');
    END IF;
    ALTER TABLE category_counts ADD CONSTRAINT category_counts_category_id UNIQUE (category_id);

    RETURN;
END
';
