
-- rename settings table
ALTER TABLE legacy_setting RENAME TO setting;

-- rename scope fields
ALTER TABLE setting RENAME COLUMN level_type_id TO scope;
ALTER TABLE setting RENAME COLUMN level_restrict_val TO scope_value;
