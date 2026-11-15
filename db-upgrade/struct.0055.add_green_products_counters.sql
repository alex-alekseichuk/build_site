
-- remove old mat. view
ALTER TABLE category_counts DROP CONSTRAINT category_counts_category_id;
SELECT drop_matview('category_counts');

-- drop old version of the view
DROP VIEW category_counts_v;

-- re-create new version of the view with  green counter
CREATE OR REPLACE VIEW category_counts_v AS
SELECT
	cats_admin.category_id as category_id
	,cats.products as products
	,cats.manufacturers as manufacturers
	,cats_admin.products as products_admin
	,cats_admin.manufacturers as manufacturers_admin
	,green_cats.products as green_products
	,green_cats.manufacturers as green_manufacturers
	,green_cats_admin.products as green_products_admin
	,green_cats_admin.manufacturers as green_manufacturers_admin
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

	LEFT JOIN
	(
		SELECT
			p.category_id as category_id
			,count(DISTINCT p.product_id) as products
			,count(DISTINCT c.company_id) as manufacturers
		FROM
			product as p
			join company as c ON p.manufacturer_id = c.company_id
            join product_attribute_value as pav ON pav.product_id = p.product_id
		group by
			p.category_id
		order by
			p.category_id
	) AS green_cats_admin
	ON green_cats_admin.category_id = cats.category_id
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
            join product_attribute_value as pav ON pav.product_id = p.product_id
		WHERE
			p.suppress_reason_code = '' AND p.public_visible
		group by
			p.category_id
		order by
			p.category_id
	) AS green_cats
	ON green_cats.category_id = cats.category_id

ORDER BY
	cats_admin.category_id
;


-- re-create mat. view
SELECT create_update_category_counts();

