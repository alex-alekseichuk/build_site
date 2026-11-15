
-- function to copy items of one package into another one
CREATE OR REPLACE FUNCTION f_copy_package_items(src_package_id text, dst_package_id text)
RETURNS void
LANGUAGE plpgsql
AS $copy_package_items$
DECLARE
	item RECORD;
BEGIN
	FOR item IN SELECT * FROM package_item where package_id = src_package_id LOOP
		INSERT INTO package_item (package_item_id, package_id, position, item_type, document_id, file_id)
		VALUES ('package_item_' || CAST((select nextval('main')) AS text), dst_package_id, item.position, item.item_type, item.document_id, item.file_id);
	END LOOP;
	RETURN;
END;
$copy_package_items$;


