
-- add trigger to update file.file_mtime, file.auto_mtime timestamp column for each file record touch
DROP TRIGGER IF EXISTS tr_file_mtime ON file;

CREATE OR REPLACE FUNCTION f_file_mtime()
RETURNS TRIGGER
AS $file_mtime$
BEGIN
NEW.file_mtime := round(date_part('epoch', now()));
NEW.auto_mtime := NEW.file_mtime;
RETURN NEW;
END;
$file_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_file_mtime
BEFORE INSERT OR UPDATE
ON file
FOR EACH ROW
EXECUTE PROCEDURE f_file_mtime();




-- add trigger to update account_location.auto_mtime timestamp column for each account_location record touch
DROP TRIGGER IF EXISTS tr_account_location_auto_mtime ON account_location;

CREATE OR REPLACE FUNCTION f_account_location_auto_mtime()
RETURNS TRIGGER
AS $account_location_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$account_location_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_location_auto_mtime
BEFORE INSERT OR UPDATE
ON account_location
FOR EACH ROW
EXECUTE PROCEDURE f_account_location_auto_mtime();



-- add trigger to update account.auto_mtime timestamp column for each account record touch
DROP TRIGGER IF EXISTS tr_account_auto_mtime ON account;

CREATE OR REPLACE FUNCTION f_account_auto_mtime()
RETURNS TRIGGER
AS $account_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$account_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_auto_mtime
BEFORE INSERT OR UPDATE
ON account
FOR EACH ROW
EXECUTE PROCEDURE f_account_auto_mtime();



-- add trigger to update account_private_location.auto_mtime timestamp column for each account_private_location record touch
DROP TRIGGER IF EXISTS tr_account_private_location_auto_mtime ON account_private_location;

CREATE OR REPLACE FUNCTION f_account_private_location_auto_mtime()
RETURNS TRIGGER
AS $account_private_location_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$account_private_location_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_private_location_auto_mtime
BEFORE INSERT OR UPDATE
ON account_private_location
FOR EACH ROW
EXECUTE PROCEDURE f_account_private_location_auto_mtime();



-- add trigger to update account_user.auto_mtime timestamp column for each account_user record touch
DROP TRIGGER IF EXISTS tr_account_user_auto_mtime ON account_user;

CREATE OR REPLACE FUNCTION f_account_user_auto_mtime()
RETURNS TRIGGER
AS $account_user_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$account_user_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_account_user_auto_mtime
BEFORE INSERT OR UPDATE
ON account_user
FOR EACH ROW
EXECUTE PROCEDURE f_account_user_auto_mtime();



-- add trigger to update addressbook_company.auto_mtime timestamp column for each addressbook_company record touch
DROP TRIGGER IF EXISTS tr_addressbook_company_auto_mtime ON addressbook_company;

CREATE OR REPLACE FUNCTION f_addressbook_company_auto_mtime()
RETURNS TRIGGER
AS $addressbook_company_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$addressbook_company_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_addressbook_company_auto_mtime
BEFORE INSERT OR UPDATE
ON addressbook_company
FOR EACH ROW
EXECUTE PROCEDURE f_addressbook_company_auto_mtime();



-- add trigger to update addressbook_person.auto_mtime timestamp column for each addressbook_person record touch
DROP TRIGGER IF EXISTS tr_addressbook_person_auto_mtime ON addressbook_person;

CREATE OR REPLACE FUNCTION f_addressbook_person_auto_mtime()
RETURNS TRIGGER
AS $addressbook_person_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$addressbook_person_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_addressbook_person_auto_mtime
BEFORE INSERT OR UPDATE
ON addressbook_person
FOR EACH ROW
EXECUTE PROCEDURE f_addressbook_person_auto_mtime();



-- add trigger to update category_grouping.auto_mtime timestamp column for each category_grouping record touch
DROP TRIGGER IF EXISTS tr_category_grouping_auto_mtime ON category_grouping;

CREATE OR REPLACE FUNCTION f_category_grouping_auto_mtime()
RETURNS TRIGGER
AS $category_grouping_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$category_grouping_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_category_grouping_auto_mtime
BEFORE INSERT OR UPDATE
ON category_grouping
FOR EACH ROW
EXECUTE PROCEDURE f_category_grouping_auto_mtime();



-- add trigger to update category.auto_mtime timestamp column for each category record touch
DROP TRIGGER IF EXISTS tr_category_auto_mtime ON category;

CREATE OR REPLACE FUNCTION f_category_auto_mtime()
RETURNS TRIGGER
AS $category_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$category_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_category_auto_mtime
BEFORE INSERT OR UPDATE
ON category
FOR EACH ROW
EXECUTE PROCEDURE f_category_auto_mtime();



-- add trigger to update company_feature.auto_mtime timestamp column for each company_feature record touch
DROP TRIGGER IF EXISTS tr_company_feature_auto_mtime ON company_feature;

CREATE OR REPLACE FUNCTION f_company_feature_auto_mtime()
RETURNS TRIGGER
AS $company_feature_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$company_feature_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_feature_auto_mtime
BEFORE INSERT OR UPDATE
ON company_feature
FOR EACH ROW
EXECUTE PROCEDURE f_company_feature_auto_mtime();



-- add trigger to update company_grouping.auto_mtime timestamp column for each company_grouping record touch
DROP TRIGGER IF EXISTS tr_company_grouping_auto_mtime ON company_grouping;

CREATE OR REPLACE FUNCTION f_company_grouping_auto_mtime()
RETURNS TRIGGER
AS $company_grouping_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$company_grouping_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_grouping_auto_mtime
BEFORE INSERT OR UPDATE
ON company_grouping
FOR EACH ROW
EXECUTE PROCEDURE f_company_grouping_auto_mtime();



-- add trigger to update company.auto_mtime timestamp column for each company record touch
DROP TRIGGER IF EXISTS tr_company_auto_mtime ON company;

CREATE OR REPLACE FUNCTION f_company_auto_mtime()
RETURNS TRIGGER
AS $company_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$company_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_company_auto_mtime
BEFORE INSERT OR UPDATE
ON company
FOR EACH ROW
EXECUTE PROCEDURE f_company_auto_mtime();



-- add trigger to update credit_card.auto_mtime timestamp column for each credit_card record touch
DROP TRIGGER IF EXISTS tr_credit_card_auto_mtime ON credit_card;

CREATE OR REPLACE FUNCTION f_credit_card_auto_mtime()
RETURNS TRIGGER
AS $credit_card_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$credit_card_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_credit_card_auto_mtime
BEFORE INSERT OR UPDATE
ON credit_card
FOR EACH ROW
EXECUTE PROCEDURE f_credit_card_auto_mtime();



-- add trigger to update customer_account.auto_mtime timestamp column for each customer_account record touch
DROP TRIGGER IF EXISTS tr_customer_account_auto_mtime ON customer_account;

CREATE OR REPLACE FUNCTION f_customer_account_auto_mtime()
RETURNS TRIGGER
AS $customer_account_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$customer_account_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_account_auto_mtime
BEFORE INSERT OR UPDATE
ON customer_account
FOR EACH ROW
EXECUTE PROCEDURE f_customer_account_auto_mtime();



-- add trigger to update customer_order.auto_mtime timestamp column for each customer_order record touch
DROP TRIGGER IF EXISTS tr_customer_order_auto_mtime ON customer_order;

CREATE OR REPLACE FUNCTION f_customer_order_auto_mtime()
RETURNS TRIGGER
AS $customer_order_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$customer_order_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_order_auto_mtime
BEFORE INSERT OR UPDATE
ON customer_order
FOR EACH ROW
EXECUTE PROCEDURE f_customer_order_auto_mtime();



-- add trigger to update customer_user.auto_mtime timestamp column for each customer_user record touch
DROP TRIGGER IF EXISTS tr_customer_user_auto_mtime ON customer_user;

CREATE OR REPLACE FUNCTION f_customer_user_auto_mtime()
RETURNS TRIGGER
AS $customer_user_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$customer_user_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customer_user_auto_mtime
BEFORE INSERT OR UPDATE
ON customer_user
FOR EACH ROW
EXECUTE PROCEDURE f_customer_user_auto_mtime();



-- add trigger to update document_list.auto_mtime timestamp column for each document_list record touch
DROP TRIGGER IF EXISTS tr_document_list_auto_mtime ON document_list;

CREATE OR REPLACE FUNCTION f_document_list_auto_mtime()
RETURNS TRIGGER
AS $document_list_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$document_list_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_document_list_auto_mtime
BEFORE INSERT OR UPDATE
ON document_list
FOR EACH ROW
EXECUTE PROCEDURE f_document_list_auto_mtime();



-- add trigger to update document.auto_mtime timestamp column for each document record touch
DROP TRIGGER IF EXISTS tr_document_auto_mtime ON document;

CREATE OR REPLACE FUNCTION f_document_auto_mtime()
RETURNS TRIGGER
AS $document_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$document_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_document_auto_mtime
BEFORE INSERT OR UPDATE
ON document
FOR EACH ROW
EXECUTE PROCEDURE f_document_auto_mtime();



-- add trigger to update gateway_payment.auto_mtime timestamp column for each gateway_payment record touch
DROP TRIGGER IF EXISTS tr_gateway_payment_auto_mtime ON gateway_payment;

CREATE OR REPLACE FUNCTION f_gateway_payment_auto_mtime()
RETURNS TRIGGER
AS $gateway_payment_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$gateway_payment_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gateway_payment_auto_mtime
BEFORE INSERT OR UPDATE
ON gateway_payment
FOR EACH ROW
EXECUTE PROCEDURE f_gateway_payment_auto_mtime();



-- add trigger to update grouping.auto_mtime timestamp column for each grouping record touch
DROP TRIGGER IF EXISTS tr_grouping_auto_mtime ON grouping;

CREATE OR REPLACE FUNCTION f_grouping_auto_mtime()
RETURNS TRIGGER
AS $grouping_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$grouping_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_grouping_auto_mtime
BEFORE INSERT OR UPDATE
ON grouping
FOR EACH ROW
EXECUTE PROCEDURE f_grouping_auto_mtime();



-- add trigger to update message.auto_mtime timestamp column for each message record touch
DROP TRIGGER IF EXISTS tr_message_auto_mtime ON message;

CREATE OR REPLACE FUNCTION f_message_auto_mtime()
RETURNS TRIGGER
AS $message_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$message_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_message_auto_mtime
BEFORE INSERT OR UPDATE
ON message
FOR EACH ROW
EXECUTE PROCEDURE f_message_auto_mtime();



-- add trigger to update product.auto_mtime timestamp column for each product record touch
DROP TRIGGER IF EXISTS tr_product_auto_mtime ON product;

CREATE OR REPLACE FUNCTION f_product_auto_mtime()
RETURNS TRIGGER
AS $product_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$product_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_auto_mtime
BEFORE INSERT OR UPDATE
ON product
FOR EACH ROW
EXECUTE PROCEDURE f_product_auto_mtime();



-- add trigger to update product_related.auto_mtime timestamp column for each product_related record touch
DROP TRIGGER IF EXISTS tr_product_related_auto_mtime ON product_related;

CREATE OR REPLACE FUNCTION f_product_related_auto_mtime()
RETURNS TRIGGER
AS $product_related_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$product_related_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_related_auto_mtime
BEFORE INSERT OR UPDATE
ON product_related
FOR EACH ROW
EXECUTE PROCEDURE f_product_related_auto_mtime();



-- add trigger to update product_standard.auto_mtime timestamp column for each product_standard record touch
DROP TRIGGER IF EXISTS tr_product_standard_auto_mtime ON product_standard;

CREATE OR REPLACE FUNCTION f_product_standard_auto_mtime()
RETURNS TRIGGER
AS $product_standard_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$product_standard_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_standard_auto_mtime
BEFORE INSERT OR UPDATE
ON product_standard
FOR EACH ROW
EXECUTE PROCEDURE f_product_standard_auto_mtime();



-- add trigger to update publication.auto_mtime timestamp column for each publication record touch
DROP TRIGGER IF EXISTS tr_publication_auto_mtime ON publication;

CREATE OR REPLACE FUNCTION f_publication_auto_mtime()
RETURNS TRIGGER
AS $publication_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$publication_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_publication_auto_mtime
BEFORE INSERT OR UPDATE
ON publication
FOR EACH ROW
EXECUTE PROCEDURE f_publication_auto_mtime();



-- add trigger to update setting.auto_mtime timestamp column for each setting record touch
DROP TRIGGER IF EXISTS tr_setting_auto_mtime ON setting;

CREATE OR REPLACE FUNCTION f_setting_auto_mtime()
RETURNS TRIGGER
AS $setting_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$setting_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_setting_auto_mtime
BEFORE INSERT OR UPDATE
ON setting
FOR EACH ROW
EXECUTE PROCEDURE f_setting_auto_mtime();



-- add trigger to update standard.auto_mtime timestamp column for each standard record touch
DROP TRIGGER IF EXISTS tr_standard_auto_mtime ON standard;

CREATE OR REPLACE FUNCTION f_standard_auto_mtime()
RETURNS TRIGGER
AS $standard_auto_mtime$
BEGIN
NEW.auto_mtime := round(date_part('epoch', now()));
RETURN NEW;
END;
$standard_auto_mtime$ LANGUAGE plpgsql;

CREATE TRIGGER tr_standard_auto_mtime
BEFORE INSERT OR UPDATE
ON standard
FOR EACH ROW
EXECUTE PROCEDURE f_standard_auto_mtime();


