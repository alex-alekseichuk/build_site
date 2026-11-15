--BEGIN;

--ALTER TABLE product ADD COLUMN search_product_name tsvector;
--ALTER TABLE product ADD COLUMN search_keywords_product_name VARCHAR(10000);

-- create a separate tsvector column to hold the output of to_tsvector.
-- It is a concatenation of needed fields, using coalesce to ensure that one field will still be indexed when the other is NULL
--UPDATE product p SET search_product_name = to_tsvector('public.fts', p.search_keywords_product_name);

-- Then we create a GiST index to speed up the search
--CREATE INDEX product_name_textsearch_idx ON product USING gist(search_product_name);

-- create a trigger to keep the tsvector column current anytime title or body changes
--CREATE TRIGGER tsvectorupdate_product_name BEFORE INSERT OR UPDATE
--ON product FOR EACH ROW EXECUTE PROCEDURE
--tsvector_update_trigger(search_product_name, 'public.fts', search_keywords_product_name);

--COMMIT;

BEGIN;

ALTER TABLE product ADD COLUMN product_name_search_tsvector tsvector;
ALTER TABLE product ADD COLUMN product_name_search_keywords TEXT;
ALTER TABLE product ADD COLUMN product_name_ext_search_tsvector tsvector;

ALTER TABLE company ADD COLUMN company_search_tsvector tsvector;
ALTER TABLE company ADD COLUMN company_search_keywords TEXT;

ALTER TABLE category ADD COLUMN category_search_tsvector tsvector;
ALTER TABLE category ADD COLUMN category_search_keywords TEXT;

ALTER TABLE product_standard ADD COLUMN astm_search_tsvector tsvector;
ALTER TABLE product_standard ADD COLUMN astm_search_keywords TEXT;

COMMIT;

BEGIN;


CREATE INDEX astm_textsearch_idx ON product_standard USING gist(astm_search_tsvector);
CREATE INDEX category_textsearch_idx ON category USING gist(category_search_tsvector);
CREATE INDEX company_textsearch_idx ON company USING gist(company_search_tsvector);
CREATE INDEX product_name_textsearch_idx ON product USING gist(product_name_search_tsvector);
CREATE INDEX product_name_ext_textsearch_idx ON product USING gist(product_name_ext_search_tsvector);

COMMIT;
