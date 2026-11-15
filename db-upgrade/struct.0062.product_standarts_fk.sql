ALTER TABLE "product_standard"
  ADD CONSTRAINT "product_standard_fk" FOREIGN KEY ("product_id")
    REFERENCES "product"("product_id");