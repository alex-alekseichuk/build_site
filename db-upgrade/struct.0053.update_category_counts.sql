
-- create or update category_counts view and materializaed view table
-- we call it during regular db_upgrade and as daily counters update
SELECT create_update_category_counts();
