ALTER TABLE product_standard
  ADD CONSTRAINT standard_fk FOREIGN KEY (standard_id)
      REFERENCES standard (standard_id);

CREATE UNIQUE INDEX product_standard_ui ON product_standard (product_id, standard_id, standard_org_id);