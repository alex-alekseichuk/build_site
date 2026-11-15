SET CONSTRAINTS ALL IMMEDIATE;


-----------------------------------
-- file
-----------------------------------
DROP TRIGGER IF EXISTS tr_file_mtime ON file;
DROP FUNCTION IF EXISTS f_file_mtime();

-- update auto_ctime
UPDATE file
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE file ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE file SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE file ADD COLUMN auto_ctime2 varchar(255);
UPDATE file SET auto_ctime2 = auto_ctime;
ALTER TABLE file DROP COLUMN auto_ctime;
ALTER TABLE file ADD COLUMN auto_ctime timestamp with time zone;
UPDATE file SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE file DROP COLUMN auto_ctime2;

ALTER TABLE file ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE file ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE file
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE file ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE file SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE file ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE file SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE file ADD COLUMN auto_mtime2 varchar(255);
UPDATE file SET auto_mtime2 = auto_mtime;
ALTER TABLE file DROP COLUMN auto_mtime;
ALTER TABLE file ADD COLUMN auto_mtime timestamp with time zone;
UPDATE file SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE file DROP COLUMN auto_mtime2;

CREATE OR REPLACE FUNCTION f_file_mtime()
RETURNS TRIGGER
AS $f_file_mtime$
BEGIN
NEW.file_mtime := round(date_part('epoch', now()));
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_file_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_file_mtime
BEFORE UPDATE
ON file
FOR EACH ROW
EXECUTE PROCEDURE f_file_mtime();









-----------------------------------
-- account_location
-----------------------------------
DROP TRIGGER IF EXISTS tr_account_location_auto_mtime ON account_location;
DROP FUNCTION IF EXISTS f_account_location_auto_mtime();

-- update auto_ctime
UPDATE account_location
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE account_location ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE account_location SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_location ADD COLUMN auto_ctime2 varchar(255);
UPDATE account_location SET auto_ctime2 = auto_ctime;
ALTER TABLE account_location DROP COLUMN auto_ctime;
ALTER TABLE account_location ADD COLUMN auto_ctime timestamp with time zone;
UPDATE account_location SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE account_location DROP COLUMN auto_ctime2;

ALTER TABLE account_location ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE account_location ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE account_location
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE account_location ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE account_location SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE account_location ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE account_location SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_location ADD COLUMN auto_mtime2 varchar(255);
UPDATE account_location SET auto_mtime2 = auto_mtime;
ALTER TABLE account_location DROP COLUMN auto_mtime;
ALTER TABLE account_location ADD COLUMN auto_mtime timestamp with time zone;
UPDATE account_location SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE account_location DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_account_location_mtime()
RETURNS TRIGGER
AS $f_account_location_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_account_location_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_location_mtime
BEFORE UPDATE
ON account_location
FOR EACH ROW
EXECUTE PROCEDURE f_account_location_mtime();






-----------------------------------
-- account
-----------------------------------
DROP TRIGGER IF EXISTS tr_account_auto_mtime ON account;
DROP FUNCTION IF EXISTS f_account_auto_mtime();

-- update auto_ctime
UPDATE account
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE account ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE account SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account ADD COLUMN auto_ctime2 varchar(255);
UPDATE account SET auto_ctime2 = auto_ctime;
ALTER TABLE account DROP COLUMN auto_ctime;
ALTER TABLE account ADD COLUMN auto_ctime timestamp with time zone;
UPDATE account SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE account DROP COLUMN auto_ctime2;

ALTER TABLE account ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE account ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE account
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE account ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE account SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE account ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE account SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account ADD COLUMN auto_mtime2 varchar(255);
UPDATE account SET auto_mtime2 = auto_mtime;
ALTER TABLE account DROP COLUMN auto_mtime;
ALTER TABLE account ADD COLUMN auto_mtime timestamp with time zone;
UPDATE account SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE account DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_account_mtime()
RETURNS TRIGGER
AS $f_account_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_account_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_mtime
BEFORE UPDATE
ON account
FOR EACH ROW
EXECUTE PROCEDURE f_account_mtime();






-----------------------------------
-- account_private_location
-----------------------------------
DROP TRIGGER IF EXISTS tr_account_private_location_auto_mtime ON account_private_location;
DROP FUNCTION IF EXISTS f_account_private_location_auto_mtime();

-- update auto_ctime
UPDATE account_private_location
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE account_private_location ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE account_private_location SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_private_location ADD COLUMN auto_ctime2 varchar(255);
UPDATE account_private_location SET auto_ctime2 = auto_ctime;
ALTER TABLE account_private_location DROP COLUMN auto_ctime;
ALTER TABLE account_private_location ADD COLUMN auto_ctime timestamp with time zone;
UPDATE account_private_location SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE account_private_location DROP COLUMN auto_ctime2;

ALTER TABLE account_private_location ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE account_private_location ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE account_private_location
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE account_private_location ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE account_private_location SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE account_private_location ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE account_private_location SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_private_location ADD COLUMN auto_mtime2 varchar(255);
UPDATE account_private_location SET auto_mtime2 = auto_mtime;
ALTER TABLE account_private_location DROP COLUMN auto_mtime;
ALTER TABLE account_private_location ADD COLUMN auto_mtime timestamp with time zone;
UPDATE account_private_location SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE account_private_location DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_account_private_location_mtime()
RETURNS TRIGGER
AS $f_account_private_location_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_account_private_location_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_private_location_mtime
BEFORE UPDATE
ON account_private_location
FOR EACH ROW
EXECUTE PROCEDURE f_account_private_location_mtime();






-----------------------------------
-- account_user
-----------------------------------
DROP TRIGGER IF EXISTS tr_account_user_auto_mtime ON account_user;
DROP FUNCTION IF EXISTS f_account_user_auto_mtime();

-- update auto_ctime
UPDATE account_user
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE account_user ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE account_user SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_user ADD COLUMN auto_ctime2 varchar(255);
UPDATE account_user SET auto_ctime2 = auto_ctime;
ALTER TABLE account_user DROP COLUMN auto_ctime;
ALTER TABLE account_user ADD COLUMN auto_ctime timestamp with time zone;
UPDATE account_user SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE account_user DROP COLUMN auto_ctime2;

ALTER TABLE account_user ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE account_user ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE account_user
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE account_user ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE account_user SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE account_user ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE account_user SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE account_user ADD COLUMN auto_mtime2 varchar(255);
UPDATE account_user SET auto_mtime2 = auto_mtime;
ALTER TABLE account_user DROP COLUMN auto_mtime;
ALTER TABLE account_user ADD COLUMN auto_mtime timestamp with time zone;
UPDATE account_user SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE account_user DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_account_user_mtime()
RETURNS TRIGGER
AS $f_account_user_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_account_user_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_user_mtime
BEFORE UPDATE
ON account_user
FOR EACH ROW
EXECUTE PROCEDURE f_account_user_mtime();






-----------------------------------
-- addressbook_company
-----------------------------------
DROP TRIGGER IF EXISTS tr_addressbook_company_auto_mtime ON addressbook_company;
DROP FUNCTION IF EXISTS f_addressbook_company_auto_mtime();

-- update auto_ctime
UPDATE addressbook_company
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE addressbook_company ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE addressbook_company SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE addressbook_company ADD COLUMN auto_ctime2 varchar(255);
UPDATE addressbook_company SET auto_ctime2 = auto_ctime;
ALTER TABLE addressbook_company DROP COLUMN auto_ctime;
ALTER TABLE addressbook_company ADD COLUMN auto_ctime timestamp with time zone;
UPDATE addressbook_company SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE addressbook_company DROP COLUMN auto_ctime2;

ALTER TABLE addressbook_company ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE addressbook_company ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE addressbook_company
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE addressbook_company ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE addressbook_company SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE addressbook_company ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE addressbook_company SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE addressbook_company ADD COLUMN auto_mtime2 varchar(255);
UPDATE addressbook_company SET auto_mtime2 = auto_mtime;
ALTER TABLE addressbook_company DROP COLUMN auto_mtime;
ALTER TABLE addressbook_company ADD COLUMN auto_mtime timestamp with time zone;
UPDATE addressbook_company SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE addressbook_company DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_addressbook_company_mtime()
RETURNS TRIGGER
AS $f_addressbook_company_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_addressbook_company_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_addressbook_company_mtime
BEFORE UPDATE
ON addressbook_company
FOR EACH ROW
EXECUTE PROCEDURE f_addressbook_company_mtime();






-----------------------------------
-- addressbook_person
-----------------------------------
DROP TRIGGER IF EXISTS tr_addressbook_person_auto_mtime ON addressbook_person;
DROP FUNCTION IF EXISTS f_addressbook_person_auto_mtime();

-- update auto_ctime
UPDATE addressbook_person
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE addressbook_person ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE addressbook_person SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE addressbook_person ADD COLUMN auto_ctime2 varchar(255);
UPDATE addressbook_person SET auto_ctime2 = auto_ctime;
ALTER TABLE addressbook_person DROP COLUMN auto_ctime;
ALTER TABLE addressbook_person ADD COLUMN auto_ctime timestamp with time zone;
UPDATE addressbook_person SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE addressbook_person DROP COLUMN auto_ctime2;

ALTER TABLE addressbook_person ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE addressbook_person ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE addressbook_person
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE addressbook_person ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE addressbook_person SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE addressbook_person ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE addressbook_person SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE addressbook_person ADD COLUMN auto_mtime2 varchar(255);
UPDATE addressbook_person SET auto_mtime2 = auto_mtime;
ALTER TABLE addressbook_person DROP COLUMN auto_mtime;
ALTER TABLE addressbook_person ADD COLUMN auto_mtime timestamp with time zone;
UPDATE addressbook_person SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE addressbook_person DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_addressbook_person_mtime()
RETURNS TRIGGER
AS $f_addressbook_person_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_addressbook_person_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_addressbook_person_mtime
BEFORE UPDATE
ON addressbook_person
FOR EACH ROW
EXECUTE PROCEDURE f_addressbook_person_mtime();






-----------------------------------
-- category_grouping
-----------------------------------
DROP TRIGGER IF EXISTS tr_category_grouping_auto_mtime ON category_grouping;
DROP FUNCTION IF EXISTS f_category_grouping_auto_mtime();

-- update auto_ctime
UPDATE category_grouping
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE category_grouping ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE category_grouping SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE category_grouping ADD COLUMN auto_ctime2 varchar(255);
UPDATE category_grouping SET auto_ctime2 = auto_ctime;
ALTER TABLE category_grouping DROP COLUMN auto_ctime;
ALTER TABLE category_grouping ADD COLUMN auto_ctime timestamp with time zone;
UPDATE category_grouping SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE category_grouping DROP COLUMN auto_ctime2;

ALTER TABLE category_grouping ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE category_grouping ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE category_grouping
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE category_grouping ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE category_grouping SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE category_grouping ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE category_grouping SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE category_grouping ADD COLUMN auto_mtime2 varchar(255);
UPDATE category_grouping SET auto_mtime2 = auto_mtime;
ALTER TABLE category_grouping DROP COLUMN auto_mtime;
ALTER TABLE category_grouping ADD COLUMN auto_mtime timestamp with time zone;
UPDATE category_grouping SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE category_grouping DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_category_grouping_mtime()
RETURNS TRIGGER
AS $f_category_grouping_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_category_grouping_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_category_grouping_mtime
BEFORE UPDATE
ON category_grouping
FOR EACH ROW
EXECUTE PROCEDURE f_category_grouping_mtime();






-----------------------------------
-- category
-----------------------------------
DROP TRIGGER IF EXISTS tr_category_auto_mtime ON category;
DROP FUNCTION IF EXISTS f_category_auto_mtime();

-- update auto_ctime
UPDATE category
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE category ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE category SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE category ADD COLUMN auto_ctime2 varchar(255);
UPDATE category SET auto_ctime2 = auto_ctime;
ALTER TABLE category DROP COLUMN auto_ctime;
ALTER TABLE category ADD COLUMN auto_ctime timestamp with time zone;
UPDATE category SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE category DROP COLUMN auto_ctime2;

ALTER TABLE category ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE category ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE category
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE category ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE category SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE category ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE category SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE category ADD COLUMN auto_mtime2 varchar(255);
UPDATE category SET auto_mtime2 = auto_mtime;
ALTER TABLE category DROP COLUMN auto_mtime;
ALTER TABLE category ADD COLUMN auto_mtime timestamp with time zone;
UPDATE category SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE category DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_category_mtime()
RETURNS TRIGGER
AS $f_category_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_category_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_category_mtime
BEFORE UPDATE
ON category
FOR EACH ROW
EXECUTE PROCEDURE f_category_mtime();






-----------------------------------
-- company_feature
-----------------------------------
DROP TRIGGER IF EXISTS tr_company_feature_auto_mtime ON company_feature;
DROP FUNCTION IF EXISTS f_company_feature_auto_mtime();

-- update auto_ctime
UPDATE company_feature
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE company_feature ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE company_feature SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company_feature ADD COLUMN auto_ctime2 varchar(255);
UPDATE company_feature SET auto_ctime2 = auto_ctime;
ALTER TABLE company_feature DROP COLUMN auto_ctime;
ALTER TABLE company_feature ADD COLUMN auto_ctime timestamp with time zone;
UPDATE company_feature SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE company_feature DROP COLUMN auto_ctime2;

ALTER TABLE company_feature ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE company_feature ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE company_feature
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE company_feature ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE company_feature SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE company_feature ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE company_feature SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company_feature ADD COLUMN auto_mtime2 varchar(255);
UPDATE company_feature SET auto_mtime2 = auto_mtime;
ALTER TABLE company_feature DROP COLUMN auto_mtime;
ALTER TABLE company_feature ADD COLUMN auto_mtime timestamp with time zone;
UPDATE company_feature SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE company_feature DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_company_feature_mtime()
RETURNS TRIGGER
AS $f_company_feature_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_company_feature_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_feature_mtime
BEFORE UPDATE
ON company_feature
FOR EACH ROW
EXECUTE PROCEDURE f_company_feature_mtime();






-----------------------------------
-- company_grouping
-----------------------------------
DROP TRIGGER IF EXISTS tr_company_grouping_auto_mtime ON company_grouping;
DROP FUNCTION IF EXISTS f_company_grouping_auto_mtime();

-- update auto_ctime
UPDATE company_grouping
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE company_grouping ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE company_grouping SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company_grouping ADD COLUMN auto_ctime2 varchar(255);
UPDATE company_grouping SET auto_ctime2 = auto_ctime;
ALTER TABLE company_grouping DROP COLUMN auto_ctime;
ALTER TABLE company_grouping ADD COLUMN auto_ctime timestamp with time zone;
UPDATE company_grouping SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE company_grouping DROP COLUMN auto_ctime2;

ALTER TABLE company_grouping ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE company_grouping ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE company_grouping
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE company_grouping ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE company_grouping SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE company_grouping ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE company_grouping SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company_grouping ADD COLUMN auto_mtime2 varchar(255);
UPDATE company_grouping SET auto_mtime2 = auto_mtime;
ALTER TABLE company_grouping DROP COLUMN auto_mtime;
ALTER TABLE company_grouping ADD COLUMN auto_mtime timestamp with time zone;
UPDATE company_grouping SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE company_grouping DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_company_grouping_mtime()
RETURNS TRIGGER
AS $f_company_grouping_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_company_grouping_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_grouping_mtime
BEFORE UPDATE
ON company_grouping
FOR EACH ROW
EXECUTE PROCEDURE f_company_grouping_mtime();






-----------------------------------
-- company
-----------------------------------
DROP TRIGGER IF EXISTS tr_company_auto_mtime ON company;
DROP FUNCTION IF EXISTS f_company_auto_mtime();

-- update auto_ctime
UPDATE company
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE company ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE company SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company ADD COLUMN auto_ctime2 varchar(255);
UPDATE company SET auto_ctime2 = auto_ctime;
ALTER TABLE company DROP COLUMN auto_ctime;
ALTER TABLE company ADD COLUMN auto_ctime timestamp with time zone;
UPDATE company SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE company DROP COLUMN auto_ctime2;

ALTER TABLE company ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE company ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE company
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE company ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE company SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE company ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE company SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE company ADD COLUMN auto_mtime2 varchar(255);
UPDATE company SET auto_mtime2 = auto_mtime;
ALTER TABLE company DROP COLUMN auto_mtime;
ALTER TABLE company ADD COLUMN auto_mtime timestamp with time zone;
UPDATE company SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE company DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_company_mtime()
RETURNS TRIGGER
AS $f_company_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_company_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_mtime
BEFORE UPDATE
ON company
FOR EACH ROW
EXECUTE PROCEDURE f_company_mtime();






-----------------------------------
-- credit_card
-----------------------------------
DROP TRIGGER IF EXISTS tr_credit_card_auto_mtime ON credit_card;
DROP FUNCTION IF EXISTS f_credit_card_auto_mtime();

-- update auto_ctime
UPDATE credit_card
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE credit_card ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE credit_card SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE credit_card ADD COLUMN auto_ctime2 varchar(255);
UPDATE credit_card SET auto_ctime2 = auto_ctime;
ALTER TABLE credit_card DROP COLUMN auto_ctime;
ALTER TABLE credit_card ADD COLUMN auto_ctime timestamp with time zone;
UPDATE credit_card SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE credit_card DROP COLUMN auto_ctime2;

ALTER TABLE credit_card ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE credit_card ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE credit_card
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE credit_card ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE credit_card SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE credit_card ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE credit_card SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE credit_card ADD COLUMN auto_mtime2 varchar(255);
UPDATE credit_card SET auto_mtime2 = auto_mtime;
ALTER TABLE credit_card DROP COLUMN auto_mtime;
ALTER TABLE credit_card ADD COLUMN auto_mtime timestamp with time zone;
UPDATE credit_card SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE credit_card DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_credit_card_mtime()
RETURNS TRIGGER
AS $f_credit_card_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_credit_card_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_credit_card_mtime
BEFORE UPDATE
ON credit_card
FOR EACH ROW
EXECUTE PROCEDURE f_credit_card_mtime();






-----------------------------------
-- customer_account
-----------------------------------
DROP TRIGGER IF EXISTS tr_customer_account_auto_mtime ON customer_account;
DROP FUNCTION IF EXISTS f_customer_account_auto_mtime();

-- update auto_ctime
UPDATE customer_account
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE customer_account ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE customer_account SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_account ADD COLUMN auto_ctime2 varchar(255);
UPDATE customer_account SET auto_ctime2 = auto_ctime;
ALTER TABLE customer_account DROP COLUMN auto_ctime;
ALTER TABLE customer_account ADD COLUMN auto_ctime timestamp with time zone;
UPDATE customer_account SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE customer_account DROP COLUMN auto_ctime2;

ALTER TABLE customer_account ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE customer_account ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE customer_account
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE customer_account ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE customer_account SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE customer_account ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE customer_account SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_account ADD COLUMN auto_mtime2 varchar(255);
UPDATE customer_account SET auto_mtime2 = auto_mtime;
ALTER TABLE customer_account DROP COLUMN auto_mtime;
ALTER TABLE customer_account ADD COLUMN auto_mtime timestamp with time zone;
UPDATE customer_account SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE customer_account DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_customer_account_mtime()
RETURNS TRIGGER
AS $f_customer_account_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_customer_account_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_account_mtime
BEFORE UPDATE
ON customer_account
FOR EACH ROW
EXECUTE PROCEDURE f_customer_account_mtime();






-----------------------------------
-- customer_order
-----------------------------------
DROP TRIGGER IF EXISTS tr_customer_order_auto_mtime ON customer_order;
DROP FUNCTION IF EXISTS f_customer_order_auto_mtime();

-- update auto_ctime
UPDATE customer_order
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE customer_order ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE customer_order SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_order ADD COLUMN auto_ctime2 varchar(255);
UPDATE customer_order SET auto_ctime2 = auto_ctime;
ALTER TABLE customer_order DROP COLUMN auto_ctime;
ALTER TABLE customer_order ADD COLUMN auto_ctime timestamp with time zone;
UPDATE customer_order SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE customer_order DROP COLUMN auto_ctime2;

ALTER TABLE customer_order ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE customer_order ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE customer_order
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE customer_order ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE customer_order SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE customer_order ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE customer_order SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_order ADD COLUMN auto_mtime2 varchar(255);
UPDATE customer_order SET auto_mtime2 = auto_mtime;
ALTER TABLE customer_order DROP COLUMN auto_mtime;
ALTER TABLE customer_order ADD COLUMN auto_mtime timestamp with time zone;
UPDATE customer_order SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE customer_order DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_customer_order_mtime()
RETURNS TRIGGER
AS $f_customer_order_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_customer_order_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_order_mtime
BEFORE UPDATE
ON customer_order
FOR EACH ROW
EXECUTE PROCEDURE f_customer_order_mtime();






-----------------------------------
-- customer_user
-----------------------------------
DROP TRIGGER IF EXISTS tr_customer_user_auto_mtime ON customer_user;
DROP FUNCTION IF EXISTS f_customer_user_auto_mtime();

-- update auto_ctime
UPDATE customer_user
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE customer_user ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE customer_user SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_user ADD COLUMN auto_ctime2 varchar(255);
UPDATE customer_user SET auto_ctime2 = auto_ctime;
ALTER TABLE customer_user DROP COLUMN auto_ctime;
ALTER TABLE customer_user ADD COLUMN auto_ctime timestamp with time zone;
UPDATE customer_user SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE customer_user DROP COLUMN auto_ctime2;

ALTER TABLE customer_user ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE customer_user ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE customer_user
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE customer_user ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE customer_user SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE customer_user ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE customer_user SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE customer_user ADD COLUMN auto_mtime2 varchar(255);
UPDATE customer_user SET auto_mtime2 = auto_mtime;
ALTER TABLE customer_user DROP COLUMN auto_mtime;
ALTER TABLE customer_user ADD COLUMN auto_mtime timestamp with time zone;
UPDATE customer_user SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE customer_user DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_customer_user_mtime()
RETURNS TRIGGER
AS $f_customer_user_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_customer_user_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_user_mtime
BEFORE UPDATE
ON customer_user
FOR EACH ROW
EXECUTE PROCEDURE f_customer_user_mtime();






-----------------------------------
-- document_list
-----------------------------------
DROP TRIGGER IF EXISTS tr_document_list_auto_mtime ON document_list;
DROP FUNCTION IF EXISTS f_document_list_auto_mtime();

-- update auto_ctime
UPDATE document_list
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE document_list ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE document_list SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE document_list ADD COLUMN auto_ctime2 varchar(255);
UPDATE document_list SET auto_ctime2 = auto_ctime;
ALTER TABLE document_list DROP COLUMN auto_ctime;
ALTER TABLE document_list ADD COLUMN auto_ctime timestamp with time zone;
UPDATE document_list SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE document_list DROP COLUMN auto_ctime2;

ALTER TABLE document_list ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE document_list ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE document_list
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE document_list ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE document_list SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE document_list ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE document_list SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE document_list ADD COLUMN auto_mtime2 varchar(255);
UPDATE document_list SET auto_mtime2 = auto_mtime;
ALTER TABLE document_list DROP COLUMN auto_mtime;
ALTER TABLE document_list ADD COLUMN auto_mtime timestamp with time zone;
UPDATE document_list SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE document_list DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_document_list_mtime()
RETURNS TRIGGER
AS $f_document_list_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_document_list_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_document_list_mtime
BEFORE UPDATE
ON document_list
FOR EACH ROW
EXECUTE PROCEDURE f_document_list_mtime();






-----------------------------------
-- document
-----------------------------------
DROP TRIGGER IF EXISTS tr_document_auto_mtime ON document;
DROP FUNCTION IF EXISTS f_document_auto_mtime();

-- update auto_ctime
UPDATE document
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE document ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE document SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE document ADD COLUMN auto_ctime2 varchar(255);
UPDATE document SET auto_ctime2 = auto_ctime;
ALTER TABLE document DROP COLUMN auto_ctime;
ALTER TABLE document ADD COLUMN auto_ctime timestamp with time zone;
UPDATE document SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE document DROP COLUMN auto_ctime2;

ALTER TABLE document ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE document ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE document
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE document ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE document SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE document ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE document SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE document ADD COLUMN auto_mtime2 varchar(255);
UPDATE document SET auto_mtime2 = auto_mtime;
ALTER TABLE document DROP COLUMN auto_mtime;
ALTER TABLE document ADD COLUMN auto_mtime timestamp with time zone;
UPDATE document SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE document DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_document_mtime()
RETURNS TRIGGER
AS $f_document_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_document_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_document_mtime
BEFORE UPDATE
ON document
FOR EACH ROW
EXECUTE PROCEDURE f_document_mtime();






-----------------------------------
-- gateway_payment
-----------------------------------
DROP TRIGGER IF EXISTS tr_gateway_payment_auto_mtime ON gateway_payment;
DROP FUNCTION IF EXISTS f_gateway_payment_auto_mtime();

-- update auto_ctime
UPDATE gateway_payment
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE gateway_payment ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE gateway_payment SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE gateway_payment ADD COLUMN auto_ctime2 varchar(255);
UPDATE gateway_payment SET auto_ctime2 = auto_ctime;
ALTER TABLE gateway_payment DROP COLUMN auto_ctime;
ALTER TABLE gateway_payment ADD COLUMN auto_ctime timestamp with time zone;
UPDATE gateway_payment SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE gateway_payment DROP COLUMN auto_ctime2;

ALTER TABLE gateway_payment ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE gateway_payment ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE gateway_payment
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE gateway_payment ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE gateway_payment SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE gateway_payment ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE gateway_payment SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE gateway_payment ADD COLUMN auto_mtime2 varchar(255);
UPDATE gateway_payment SET auto_mtime2 = auto_mtime;
ALTER TABLE gateway_payment DROP COLUMN auto_mtime;
ALTER TABLE gateway_payment ADD COLUMN auto_mtime timestamp with time zone;
UPDATE gateway_payment SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE gateway_payment DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_gateway_payment_mtime()
RETURNS TRIGGER
AS $f_gateway_payment_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_gateway_payment_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gateway_payment_mtime
BEFORE UPDATE
ON gateway_payment
FOR EACH ROW
EXECUTE PROCEDURE f_gateway_payment_mtime();






-----------------------------------
-- grouping
-----------------------------------
DROP TRIGGER IF EXISTS tr_grouping_auto_mtime ON grouping;
DROP FUNCTION IF EXISTS f_grouping_auto_mtime();

-- update auto_ctime
UPDATE grouping
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE grouping ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE grouping SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE grouping ADD COLUMN auto_ctime2 varchar(255);
UPDATE grouping SET auto_ctime2 = auto_ctime;
ALTER TABLE grouping DROP COLUMN auto_ctime;
ALTER TABLE grouping ADD COLUMN auto_ctime timestamp with time zone;
UPDATE grouping SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE grouping DROP COLUMN auto_ctime2;

ALTER TABLE grouping ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE grouping ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE grouping
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE grouping ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE grouping SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE grouping ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE grouping SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE grouping ADD COLUMN auto_mtime2 varchar(255);
UPDATE grouping SET auto_mtime2 = auto_mtime;
ALTER TABLE grouping DROP COLUMN auto_mtime;
ALTER TABLE grouping ADD COLUMN auto_mtime timestamp with time zone;
UPDATE grouping SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE grouping DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_grouping_mtime()
RETURNS TRIGGER
AS $f_grouping_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_grouping_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_grouping_mtime
BEFORE UPDATE
ON grouping
FOR EACH ROW
EXECUTE PROCEDURE f_grouping_mtime();






-----------------------------------
-- message
-----------------------------------
DROP TRIGGER IF EXISTS tr_message_auto_mtime ON message;
DROP FUNCTION IF EXISTS f_message_auto_mtime();

-- update auto_ctime
UPDATE message
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE message ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE message SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE message ADD COLUMN auto_ctime2 varchar(255);
UPDATE message SET auto_ctime2 = auto_ctime;
ALTER TABLE message DROP COLUMN auto_ctime;
ALTER TABLE message ADD COLUMN auto_ctime timestamp with time zone;
UPDATE message SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE message DROP COLUMN auto_ctime2;

ALTER TABLE message ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE message ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE message
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE message ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE message SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE message ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE message SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE message ADD COLUMN auto_mtime2 varchar(255);
UPDATE message SET auto_mtime2 = auto_mtime;
ALTER TABLE message DROP COLUMN auto_mtime;
ALTER TABLE message ADD COLUMN auto_mtime timestamp with time zone;
UPDATE message SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE message DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_message_mtime()
RETURNS TRIGGER
AS $f_message_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_message_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_message_mtime
BEFORE UPDATE
ON message
FOR EACH ROW
EXECUTE PROCEDURE f_message_mtime();






-----------------------------------
-- product
-----------------------------------
DROP TRIGGER IF EXISTS tr_product_auto_mtime ON product;
DROP FUNCTION IF EXISTS f_product_auto_mtime();

-- update auto_ctime
UPDATE product
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE product ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE product SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product ADD COLUMN auto_ctime2 varchar(255);
UPDATE product SET auto_ctime2 = auto_ctime;
ALTER TABLE product DROP COLUMN auto_ctime;
ALTER TABLE product ADD COLUMN auto_ctime timestamp with time zone;
UPDATE product SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE product DROP COLUMN auto_ctime2;

ALTER TABLE product ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE product ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE product
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE product ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE product SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE product ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE product SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product ADD COLUMN auto_mtime2 varchar(255);
UPDATE product SET auto_mtime2 = auto_mtime;
ALTER TABLE product DROP COLUMN auto_mtime;
ALTER TABLE product ADD COLUMN auto_mtime timestamp with time zone;
UPDATE product SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE product DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_product_mtime()
RETURNS TRIGGER
AS $f_product_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_product_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_mtime
BEFORE UPDATE
ON product
FOR EACH ROW
EXECUTE PROCEDURE f_product_mtime();






-----------------------------------
-- product_related
-----------------------------------
DROP TRIGGER IF EXISTS tr_product_related_auto_mtime ON product_related;
DROP FUNCTION IF EXISTS f_product_related_auto_mtime();

-- update auto_ctime
UPDATE product_related
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE product_related ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE product_related SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product_related ADD COLUMN auto_ctime2 varchar(255);
UPDATE product_related SET auto_ctime2 = auto_ctime;
ALTER TABLE product_related DROP COLUMN auto_ctime;
ALTER TABLE product_related ADD COLUMN auto_ctime timestamp with time zone;
UPDATE product_related SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE product_related DROP COLUMN auto_ctime2;

ALTER TABLE product_related ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE product_related ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE product_related
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE product_related ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE product_related SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE product_related ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE product_related SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product_related ADD COLUMN auto_mtime2 varchar(255);
UPDATE product_related SET auto_mtime2 = auto_mtime;
ALTER TABLE product_related DROP COLUMN auto_mtime;
ALTER TABLE product_related ADD COLUMN auto_mtime timestamp with time zone;
UPDATE product_related SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE product_related DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_product_related_mtime()
RETURNS TRIGGER
AS $f_product_related_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_product_related_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_related_mtime
BEFORE UPDATE
ON product_related
FOR EACH ROW
EXECUTE PROCEDURE f_product_related_mtime();






-----------------------------------
-- product_standard
-----------------------------------
DROP TRIGGER IF EXISTS tr_product_standard_auto_mtime ON product_standard;
DROP FUNCTION IF EXISTS f_product_standard_auto_mtime();

-- update auto_ctime
UPDATE product_standard
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE product_standard ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE product_standard SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product_standard ADD COLUMN auto_ctime2 varchar(255);
UPDATE product_standard SET auto_ctime2 = auto_ctime;
ALTER TABLE product_standard DROP COLUMN auto_ctime;
ALTER TABLE product_standard ADD COLUMN auto_ctime timestamp with time zone;
UPDATE product_standard SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE product_standard DROP COLUMN auto_ctime2;

ALTER TABLE product_standard ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE product_standard ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE product_standard
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE product_standard ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE product_standard SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE product_standard ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE product_standard SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE product_standard ADD COLUMN auto_mtime2 varchar(255);
UPDATE product_standard SET auto_mtime2 = auto_mtime;
ALTER TABLE product_standard DROP COLUMN auto_mtime;
ALTER TABLE product_standard ADD COLUMN auto_mtime timestamp with time zone;
UPDATE product_standard SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE product_standard DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_product_standard_mtime()
RETURNS TRIGGER
AS $f_product_standard_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_product_standard_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_standard_mtime
BEFORE UPDATE
ON product_standard
FOR EACH ROW
EXECUTE PROCEDURE f_product_standard_mtime();






-----------------------------------
-- publication
-----------------------------------
DROP TRIGGER IF EXISTS tr_publication_auto_mtime ON publication;
DROP FUNCTION IF EXISTS f_publication_auto_mtime();

-- update auto_ctime
UPDATE publication
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE publication ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE publication SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE publication ADD COLUMN auto_ctime2 varchar(255);
UPDATE publication SET auto_ctime2 = auto_ctime;
ALTER TABLE publication DROP COLUMN auto_ctime;
ALTER TABLE publication ADD COLUMN auto_ctime timestamp with time zone;
UPDATE publication SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE publication DROP COLUMN auto_ctime2;

ALTER TABLE publication ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE publication ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE publication
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE publication ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE publication SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE publication ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE publication SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE publication ADD COLUMN auto_mtime2 varchar(255);
UPDATE publication SET auto_mtime2 = auto_mtime;
ALTER TABLE publication DROP COLUMN auto_mtime;
ALTER TABLE publication ADD COLUMN auto_mtime timestamp with time zone;
UPDATE publication SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE publication DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_publication_mtime()
RETURNS TRIGGER
AS $f_publication_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_publication_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_publication_mtime
BEFORE UPDATE
ON publication
FOR EACH ROW
EXECUTE PROCEDURE f_publication_mtime();






-----------------------------------
-- setting
-----------------------------------
DROP TRIGGER IF EXISTS tr_setting_auto_mtime ON setting;
DROP FUNCTION IF EXISTS f_setting_auto_mtime();

-- update auto_ctime
UPDATE setting
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE setting ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE setting SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE setting ADD COLUMN auto_ctime2 varchar(255);
UPDATE setting SET auto_ctime2 = auto_ctime;
ALTER TABLE setting DROP COLUMN auto_ctime;
ALTER TABLE setting ADD COLUMN auto_ctime timestamp with time zone;
UPDATE setting SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE setting DROP COLUMN auto_ctime2;

ALTER TABLE setting ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE setting ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE setting
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE setting ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE setting SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE setting ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE setting SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE setting ADD COLUMN auto_mtime2 varchar(255);
UPDATE setting SET auto_mtime2 = auto_mtime;
ALTER TABLE setting DROP COLUMN auto_mtime;
ALTER TABLE setting ADD COLUMN auto_mtime timestamp with time zone;
UPDATE setting SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE setting DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_setting_mtime()
RETURNS TRIGGER
AS $f_setting_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_setting_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_setting_mtime
BEFORE UPDATE
ON setting
FOR EACH ROW
EXECUTE PROCEDURE f_setting_mtime();






-----------------------------------
-- standard
-----------------------------------
DROP TRIGGER IF EXISTS tr_standard_auto_mtime ON standard;
DROP FUNCTION IF EXISTS f_standard_auto_mtime();

-- update auto_ctime
UPDATE standard
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE standard ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE standard SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE standard ADD COLUMN auto_ctime2 varchar(255);
UPDATE standard SET auto_ctime2 = auto_ctime;
ALTER TABLE standard DROP COLUMN auto_ctime;
ALTER TABLE standard ADD COLUMN auto_ctime timestamp with time zone;
UPDATE standard SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE standard DROP COLUMN auto_ctime2;

ALTER TABLE standard ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE standard ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE standard
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE standard ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE standard SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE standard ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE standard SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\+|-)\\d{1,2}$';

ALTER TABLE standard ADD COLUMN auto_mtime2 varchar(255);
UPDATE standard SET auto_mtime2 = auto_mtime;
ALTER TABLE standard DROP COLUMN auto_mtime;
ALTER TABLE standard ADD COLUMN auto_mtime timestamp with time zone;
UPDATE standard SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE standard DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_standard_mtime()
RETURNS TRIGGER
AS $f_standard_mtime$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$f_standard_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_standard_mtime
BEFORE UPDATE
ON standard
FOR EACH ROW
EXECUTE PROCEDURE f_standard_mtime();




