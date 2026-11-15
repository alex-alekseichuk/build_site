ALTER TABLE legacy_account_private_person RENAME TO addressbook_person;

ALTER TABLE legacy_account_private_company RENAME TO addressbook_company;

ALTER TABLE addressbook_company RENAME COLUMN private_company_id TO addressbook_company_id;

ALTER TABLE addressbook_person RENAME COLUMN account_private_company_ref TO addressbook_company_id;

ALTER TABLE addressbook_person ALTER COLUMN addressbook_company_id DROP NOT NULL;

ALTER TABLE addressbook_person
  ADD CONSTRAINT fk_app_ac FOREIGN KEY (addressbook_company_id)
      REFERENCES addressbook_company (addressbook_company_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL;