UPDATE
    file
SET
    file_extension = LOWER( REGEXP_REPLACE(file_original_path, E'^.*?(\\.([^\\.]{2,4}))?$', E'\\2') )
WHERE 
    file_class = 'file' AND 
    file_original_path <> '';

    
UPDATE file SET file_format_type = 'word' WHERE file_extension IN ('doc', 'docx');
UPDATE file SET file_format_type = 'excel' WHERE file_extension IN ('xls', 'xlsx');
UPDATE file SET file_format_type = 'html' WHERE file_extension IN ('htm', 'mht');
UPDATE file SET file_format_type = 'text' WHERE file_extension IN ('txt');
UPDATE file SET file_format_type = 'tiff' WHERE file_extension IN ('tif');
UPDATE file SET file_format_type = 'jpeg' WHERE file_extension IN ('jpg');