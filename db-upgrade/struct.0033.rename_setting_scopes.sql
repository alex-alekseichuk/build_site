
-- rename scope fields
update setting set scope='user' where scope='buildsite_user';
update setting set scope='location' where scope='account_location';
update setting set scope='all' where scope='world';
update setting set scope='hidden' where scope='abstract';