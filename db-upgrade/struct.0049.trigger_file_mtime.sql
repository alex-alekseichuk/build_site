
-- add trigger to update file.file_mtime timestamp column for each file record touch
DROP TRIGGER IF EXISTS tr_file_mtime ON file;

CREATE OR REPLACE FUNCTION f_file_mtime()
RETURNS TRIGGER
AS $file_mtime$
BEGIN
NEW.file_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$file_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_file_mtime
BEFORE INSERT OR UPDATE
ON file
FOR EACH ROW
EXECUTE PROCEDURE f_file_mtime();


-- add triggers to update file.file_mtime timestamp column for each package_item record touch
DROP TRIGGER IF EXISTS tr_package_item_mtime ON package_item;
DROP TRIGGER IF EXISTS tr_package_item_mtime_delete ON package_item;

CREATE OR REPLACE FUNCTION f_package_item_mtime()
RETURNS TRIGGER
AS $package_item_mtime$
BEGIN
IF(TG_OP='INSERT') THEN
	UPDATE file SET file_mtime = round(date_part('epoch', now())) WHERE file_id = NEW.package_id;
END IF;
IF(TG_OP='UPDATE') THEN
	UPDATE file SET file_mtime = round(date_part('epoch', now())) WHERE file_id = NEW.package_id;
END IF;
IF(TG_OP='DELETE') THEN
	UPDATE file SET file_mtime = round(date_part('epoch', now())) WHERE file_id = OLD.package_id;
END IF;
RETURN NEW;
END;
$package_item_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_package_item_mtime
AFTER INSERT OR UPDATE
ON package_item
FOR EACH ROW
EXECUTE PROCEDURE f_package_item_mtime();

CREATE TRIGGER tr_package_item_mtime_delete
BEFORE DELETE
ON package_item
FOR EACH ROW
EXECUTE PROCEDURE f_package_item_mtime();
