
my $pattern = <<END_PATTERN;


-----------------------------------
-- TARGET
-----------------------------------
DROP TRIGGER IF EXISTS tr_TARGET_auto_mtime ON TARGET;
DROP FUNCTION IF EXISTS f_TARGET_auto_mtime();

-- update auto_ctime
UPDATE TARGET
SET auto_ctime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_ctime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_ctime like '1%';

ALTER TABLE TARGET ALTER COLUMN auto_ctime DROP DEFAULT;
UPDATE TARGET SET auto_ctime = auto_ctime || '-07' WHERE auto_ctime !~ e'(\\\\+|-)\\\\d{1,2}\$';

ALTER TABLE TARGET ADD COLUMN auto_ctime2 varchar(255);
UPDATE TARGET SET auto_ctime2 = auto_ctime;
ALTER TABLE TARGET DROP COLUMN auto_ctime;
ALTER TABLE TARGET ADD COLUMN auto_ctime timestamp with time zone;
UPDATE TARGET SET auto_ctime = CASE WHEN auto_ctime2 LIKE '200%' THEN CAST(auto_ctime2 AS timestamp with time zone) ELSE CURRENT_TIMESTAMP END;
ALTER TABLE TARGET DROP COLUMN auto_ctime2;

ALTER TABLE TARGET ALTER COLUMN auto_ctime SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE TARGET ALTER COLUMN auto_ctime SET NOT NULL;

-- update auto_mtime
UPDATE TARGET
SET auto_mtime = CAST((SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + CAST(auto_mtime AS int) * INTERVAL '1 second') AS varchar)
WHERE auto_mtime like '1%';

ALTER TABLE TARGET ALTER COLUMN auto_mtime DROP NOT NULL;
UPDATE TARGET SET auto_mtime = NULL WHERE auto_mtime NOT LIKE '2%';

ALTER TABLE TARGET ALTER COLUMN auto_mtime DROP DEFAULT;
UPDATE TARGET SET auto_mtime = auto_mtime || '-07' WHERE auto_mtime !~ e'(\\\\+|-)\\\\d{1,2}\$';

ALTER TABLE TARGET ADD COLUMN auto_mtime2 varchar(255);
UPDATE TARGET SET auto_mtime2 = auto_mtime;
ALTER TABLE TARGET DROP COLUMN auto_mtime;
ALTER TABLE TARGET ADD COLUMN auto_mtime timestamp with time zone;
UPDATE TARGET SET auto_mtime = CAST(auto_mtime2 AS timestamp with time zone);
ALTER TABLE TARGET DROP COLUMN auto_mtime2;



CREATE OR REPLACE FUNCTION f_TARGET_mtime()
RETURNS TRIGGER
AS \$f_TARGET_mtime\$
BEGIN
NEW.auto_mtime := CURRENT_TIMESTAMP;
RETURN NEW;
END;
\$f_TARGET_mtime\$ LANGUAGE plpgsql;

CREATE TRIGGER tr_TARGET_mtime
BEFORE UPDATE
ON TARGET
FOR EACH ROW
EXECUTE PROCEDURE f_TARGET_mtime();




END_PATTERN

while(<>)
{
    chomp;
    my $block = $pattern;
    $block =~ s/TARGET/$_/g;
    print $block;
}
