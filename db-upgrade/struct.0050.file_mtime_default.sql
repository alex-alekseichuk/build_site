
-- set default value for file.file_mtime
ALTER TABLE file
      ALTER COLUMN file_mtime SET DEFAULT round(date_part('epoch', now()))
;
