
-- add FK column
ALTER TABLE account ADD COLUMN company_id varchar(250) DEFAULT null;

-- add FK
ALTER TABLE account ADD CONSTRAINT account_company_id_fkey FOREIGN KEY (company_id)
      REFERENCES company (company_id);

-- import FK value from another column with check of existing company record
update account 
set company_id = case 
	when customer_id like '%-company_id-%' 
		and exists(select * from company where company_id=substring(substring(customer_id from '-company_id-.*$') from 13))
		then substring(substring(customer_id from '-company_id-.*$') from 13)
	when customer_id not like '%-company_id-%' 
		and exists(select * from company where company_id=customer_id)
		then customer_id
	else null
end;
