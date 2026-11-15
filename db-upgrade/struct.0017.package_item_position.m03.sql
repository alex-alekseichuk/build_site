-- add trigger to increase position on new package_item automatically

BEGIN;

DROP TRIGGER IF EXISTS tr_package_item_position ON package_item;

CREATE OR REPLACE FUNCTION f_package_item_position()
RETURNS TRIGGER
AS $package_item_position$
BEGIN
IF(TG_OP='INSERT') THEN
	NEW.position := (SELECT MAX(pi.position)+1 FROM package_item AS pi WHERE pi.package_id=NEW.package_id);
	IF (NEW.position IS NULL) THEN
		NEW.position := 1;
	END IF;
END IF;
RETURN NEW;
END;
$package_item_position$ LANGUAGE plpgsql;

CREATE TRIGGER tr_package_item_position
BEFORE INSERT 
ON package_item
FOR EACH ROW
EXECUTE PROCEDURE f_package_item_position();

COMMIT;
