ALTER TABLE message_recipient 
  ADD CONSTRAINT fk_contact_id FOREIGN KEY (contact_id)
      REFERENCES addressbook_person (private_person_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL;