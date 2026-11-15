ALTER TABLE "customer_order" ADD COLUMN account_id varchar(250) DEFAULT null;
ALTER TABLE "customer_order"
  ADD CONSTRAINT "customer_order_fk" FOREIGN KEY ("account_id")
    REFERENCES "account"("account_id");