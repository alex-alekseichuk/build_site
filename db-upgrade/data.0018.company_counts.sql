ALTER TABLE company DISABLE TRIGGER USER;
update company set count_product = (
    select 
	count(*) 
    from 
	product 
    where 
	product.manufacturer_id = company.company_id
	and product.public_visible = 't' 
	and product.suppress_reason_code = ''
), count_product_admin = (
    select 
	count(*) 
    from 
	product 
    where 
	product.manufacturer_id = company.company_id
), count_green = (
    select 
	count(*) 
    from 
	product 
    where 
	product.manufacturer_id = company.company_id
	and product.public_visible = 't' 
	and product.suppress_reason_code = ''
	and product.is_green
), count_green_admin = (
    select 
	count(*) 
    from 
	product 
    where 
	product.manufacturer_id = company.company_id
	and product.is_green
);
ALTER TABLE company ENABLE TRIGGER USER;