
-- the same doc or file should be in package one time only
-- disabled by Ivan, because these constraints are
-- incompatible with data.0003.import-packages.m03.pl 
-- the following error happens:
/*

 DBIx::Class::Row::update_or_insert(): DBI Exception: DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "package_item_doc" [for Statement "INSERT INTO package_item (document_id, item_type, package_id, package_item_id) VALUES (?, ?, ?, ?)" with ParamValues: 4='package_item_145803', 1='document247236', 3='private255737', 2='document'] at /home/buildsite/database-integration/bs-app/db-upgrade/../lib/BST/Core.pm line 55
/home/buildsite/database-integration/bs-app/bin/../db-upgrade/data.0003.import-packages.m03.pl: 65280

*/

/*

BEGIN;
ALTER TABLE package_item ADD CONSTRAINT package_item_file UNIQUE (package_id, file_id);
ALTER TABLE package_item ADD CONSTRAINT package_item_doc UNIQUE (package_id, document_id);
COMMIT;

*/
