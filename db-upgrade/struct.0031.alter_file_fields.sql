-- remove hidden field
update file set scope='hidden' where is_hidden=true;
alter table file drop column is_hidden;

ALTER TABLE file ALTER COLUMN scope SET DEFAULT 'location';

-- switch to new file scope scheme
update file set scope='user' where scope='buildsite_user';
update file set scope='location' where scope='account_location';
update file set scope='all' where scope='' or scope is null;

