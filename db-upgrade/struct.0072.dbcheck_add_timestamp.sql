-- add timestamp filed to dbcheck_reports

DELETE FROM dbcheck_reports;

ALTER TABLE dbcheck_reports ADD COLUMN auto_ctime timestamp with time zone;
ALTER TABLE dbcheck_reports ALTER COLUMN auto_ctime SET STORAGE PLAIN;
ALTER TABLE dbcheck_reports ALTER COLUMN auto_ctime SET NOT NULL;
ALTER TABLE dbcheck_reports ALTER COLUMN auto_ctime SET DEFAULT now();

