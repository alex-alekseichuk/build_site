
-- remove unique constraint for package_item position

ALTER TABLE package_item DROP CONSTRAINT unique_package_item RESTRICT;

