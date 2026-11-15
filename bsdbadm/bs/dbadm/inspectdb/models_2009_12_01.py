# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#     * Rearrange models' order
#     * Make sure each model has one field with primary_key=True
# Feel free to rename the models, but don't rename db_table values or field names.
#
# Also note: You'll have to insert the output of 'django-admin.py sqlcustom [appname]'
# into your database.

from django.db import models

class DjangoSession(models.Model):
    session_key = models.CharField(max_length=40, primary_key=True)
    session_data = models.TextField()
    expire_date = models.DateTimeField()
    class Meta:
        db_table = u'django_session'

class DjangoSite(models.Model):
    id = models.IntegerField(primary_key=True)
    domain = models.CharField(max_length=100)
    name = models.CharField(max_length=50)
    class Meta:
        db_table = u'django_site'

class LegacySetting(models.Model):
    setting_id = models.CharField(max_length=250, primary_key=True)
    level_type_id = models.CharField(max_length=250)
    level_restrict_val = models.CharField(max_length=250)
    att_name = models.CharField(max_length=250)
    att_val = models.CharField(max_length=10000)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    class Meta:
        db_table = u'legacy_setting'

class Matviews(models.Model):
    mv_name = models.TextField(primary_key=True) # This field type is a guess.
    v_name = models.TextField() # This field type is a guess.
    last_refresh = models.DateTimeField()
    class Meta:
        db_table = u'matviews'

class SystemInfo(models.Model):
    att_name = models.CharField(unique=True, max_length=250)
    att_val = models.CharField(max_length=10000)
    class Meta:
        db_table = u'system_info'

class Setting(models.Model):
    setting_id = models.CharField(max_length=250, primary_key=True)
    scope = models.CharField(max_length=250)
    scope_value = models.CharField(max_length=250)
    att_name = models.CharField(max_length=250)
    att_val = models.CharField(max_length=10000)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'setting'

class AuthGroupPermissions(models.Model):
    id = models.IntegerField(primary_key=True)
    group = models.ForeignKey('AuthGroup')
    permission = models.ForeignKey('AuthPermission')
    class Meta:
        db_table = u'auth_group_permissions'

class AuthMessage(models.Model):
    id = models.IntegerField(primary_key=True)
    user = models.ForeignKey('AuthUser')
    message = models.TextField()
    class Meta:
        db_table = u'auth_message'

class AuthGroup(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(unique=True, max_length=80)
    class Meta:
        db_table = u'auth_group'

class AuthUserGroups(models.Model):
    id = models.IntegerField(primary_key=True)
    user = models.ForeignKey('AuthUser')
    group = models.ForeignKey('AuthGroup')
    class Meta:
        db_table = u'auth_user_groups'

class AuthUserUserPermissions(models.Model):
    id = models.IntegerField(primary_key=True)
    user = models.ForeignKey('AuthUser')
    permission = models.ForeignKey('AuthPermission')
    class Meta:
        db_table = u'auth_user_user_permissions'

class CategoryDescendant(models.Model):
    category = models.ForeignKey('Category')
    descendant = models.ForeignKey('Category')
    descendant_distance = models.IntegerField()
    class Meta:
        db_table = u'category_descendant'

class CategoryGrouping(models.Model):
    category_grouping_id = models.IntegerField(primary_key=True)
    category = models.ForeignKey('Category')
    grouping = models.ForeignKey('Grouping')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'category_grouping'

class CompanyGrouping(models.Model):
    company_grouping_id = models.IntegerField(primary_key=True)
    company = models.ForeignKey('Company')
    grouping = models.ForeignKey('Grouping')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'company_grouping'

class AuthPermission(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=50)
    content_type = models.ForeignKey('DjangoContentType')
    codename = models.CharField(max_length=100)
    class Meta:
        db_table = u'auth_permission'

class DjangoContentType(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=100)
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)
    class Meta:
        db_table = u'django_content_type'

class Service(models.Model):
    service_nickname = models.CharField(max_length=250)
    service_title = models.CharField(unique=True, max_length=250)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    recur_interval = models.CharField(max_length=250)
    service_discontinue_date = models.DateField()
    class Meta:
        db_table = u'service'

class CustomerAccount(models.Model):
    customer_account_id = models.IntegerField(primary_key=True)
    account_name = models.CharField(max_length=250)
    company = models.ForeignKey('Company')
    account_type = models.CharField(max_length=250)
    account_purpose = models.CharField(max_length=250)
    block_reason = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_account'

class CustomerUser(models.Model):
    customer_user_id = models.IntegerField(primary_key=True)
    customer_account = models.ForeignKey('CustomerAccount')
    login_id = models.CharField(max_length=250)
    login_password = models.CharField(max_length=250)
    user_role = models.CharField(max_length=250)
    fullname = models.CharField(max_length=1024)
    email = models.CharField(max_length=250)
    phone = models.CharField(max_length=250)
    employer_name = models.CharField(max_length=250)
    last_login = models.DateTimeField()
    document_list = models.ForeignKey('DocumentList')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_user'

class DocTypeInfo(models.Model):
    doc_type = models.CharField(max_length=250)
    dt_order = models.FloatField()
    dt_abbrev = models.CharField(unique=True, max_length=3)
    dt_label = models.CharField(unique=True, max_length=250)
    dt_flags = models.CharField(max_length=250)
    dt_help = models.CharField(max_length=10000)
    class Meta:
        db_table = u'doc_type_info'

class DocumentListMember(models.Model):
    document_list = models.ForeignKey('DocumentList')
    document = models.ForeignKey('Document')
    position = models.IntegerField()
    class Meta:
        db_table = u'document_list_member'

class DocumentList(models.Model):
    document_list_id = models.IntegerField(primary_key=True)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'document_list'

class Account(models.Model):
    account_id = models.CharField(max_length=250, primary_key=True)
    account_type = models.CharField(max_length=250)
    access_constraints = models.CharField(max_length=250)
    allow_self_registration = models.CharField(max_length=250)
    block_access = models.BooleanField()
    block_reason = models.CharField(max_length=250)
    signed_final_date = models.CharField(max_length=250)
    signed_trial_date = models.CharField(max_length=250)
    expiration_date = models.CharField(max_length=250)
    mail_opt_out = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    sponsor_id = models.CharField(max_length=250)
    company = models.ForeignKey('Company')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account'

class AccountPrivateLocation(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    private_location_id = models.CharField(max_length=250, primary_key=True)
    account_private_company_ref = models.ForeignKey('AddressbookCompany', db_column='account_private_company_ref')
    location_nickname = models.CharField(max_length=250)
    location_state = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_private_location'

class AddressbookCompany(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    owner = models.ForeignKey('AccountLocation', db_column='owner')
    addressbook_company_id = models.CharField(max_length=250, primary_key=True)
    company_fullname = models.CharField(max_length=250)
    company_url = models.CharField(max_length=250)
    company_state = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'addressbook_company'

class AccountLocation(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    account_location_id = models.CharField(max_length=250, primary_key=True)
    location_nickname = models.CharField(max_length=250)
    location_fullname = models.CharField(max_length=250)
    location_url = models.CharField(max_length=250)
    account = models.ForeignKey('Account')
    company_location_ref = models.ForeignKey('Company', db_column='company_location_ref')
    mail_opt_out = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    block_date = models.CharField(max_length=250)
    block_access = models.BooleanField()
    block_reason = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_location'

class CategoryAttribute(models.Model):
    category_attribute_id = models.IntegerField(primary_key=True)
    category = models.ForeignKey('Category')
    attribute = models.ForeignKey('Attribute')
    class Meta:
        db_table = u'category_attribute'

class CategoryKeyword(models.Model):
    keyword_id = models.IntegerField(primary_key=True)
    keyword = models.CharField(max_length=250)
    keyword_type = models.TextField() # This field type is a guess.
    category = models.ForeignKey('Category')
    score = models.IntegerField()
    class Meta:
        db_table = u'category_keyword'

class CompanyFeature(models.Model):
    company_feature_id = models.IntegerField(primary_key=True)
    company = models.ForeignKey('Company')
    feature_name = models.CharField(max_length=250)
    feature_level = models.CharField(max_length=250)
    feature_status = models.CharField(max_length=250)
    feature_params = models.CharField(max_length=1024)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'company_feature'

class CompanyKeyword(models.Model):
    keyword_id = models.IntegerField(primary_key=True)
    keyword = models.CharField(max_length=250)
    keyword_type = models.TextField() # This field type is a guess.
    company = models.ForeignKey('Company')
    score = models.IntegerField()
    class Meta:
        db_table = u'company_keyword'

class AddressbookPerson(models.Model):
    given_name = models.CharField(max_length=250)
    family_name = models.CharField(max_length=250)
    vcard_fullname = models.CharField(max_length=250)
    vcard_name = models.CharField(max_length=250)
    job_title = models.CharField(max_length=250)
    work_phone = models.CharField(max_length=250)
    cell_phone = models.CharField(max_length=250)
    fax_phone = models.CharField(max_length=250)
    home_phone = models.CharField(max_length=250)
    pager_phone = models.CharField(max_length=250)
    email_address = models.CharField(max_length=250)
    comment = models.CharField(max_length=1024)
    private_person_id = models.CharField(max_length=250, primary_key=True)
    person_state = models.CharField(max_length=250)
    addressbook_company = models.ForeignKey('AddressbookCompany')
    primary_location = models.CharField(max_length=250)
    owner = models.ForeignKey('AccountLocation', db_column='owner')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'addressbook_person'

class AccountUser(models.Model):
    given_name = models.CharField(max_length=250)
    family_name = models.CharField(max_length=250)
    vcard_fullname = models.CharField(max_length=250)
    vcard_name = models.CharField(max_length=250)
    job_title = models.CharField(max_length=250)
    work_phone = models.CharField(max_length=250)
    cell_phone = models.CharField(max_length=250)
    fax_phone = models.CharField(max_length=250)
    home_phone = models.CharField(max_length=250)
    pager_phone = models.CharField(max_length=250)
    email_address = models.CharField(max_length=250)
    comment = models.CharField(max_length=1024)
    user_id = models.CharField(max_length=250, primary_key=True)
    staff_user = models.CharField(max_length=250)
    user_password = models.CharField(max_length=250)
    preferences = models.CharField(max_length=250)
    user_role = models.CharField(max_length=250)
    primary_location = models.CharField(max_length=250)
    primary_only = models.CharField(max_length=250)
    login_id = models.CharField(max_length=250)
    mail_opt_out = models.CharField(max_length=250)
    user_department = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    block_date = models.CharField(max_length=250)
    block_access = models.BooleanField()
    block_reason = models.CharField(max_length=250)
    test_user = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    document_queue = models.CharField(max_length=11000)
    current_message = models.ForeignKey('Message')
    current_package = models.ForeignKey('File')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_user'

class Docset(models.Model):
    docset_id = models.CharField(max_length=250, primary_key=True)
    docset_type = models.CharField(max_length=10)
    publication = models.ForeignKey('Publication')
    media_type = models.CharField(max_length=250)
    is_standard = models.CharField(max_length=250)
    received_date = models.CharField(max_length=250)
    received_staff_id = models.CharField(max_length=250)
    acceptance = models.CharField(max_length=250)
    is_authoritative = models.CharField(max_length=250)
    filter_expr = models.CharField(max_length=1024)
    exclude_expr = models.CharField(max_length=1024)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    sent_update_reg_card = models.CharField(max_length=250)
    replaces_docset_id = models.CharField(max_length=250)
    incident_log = models.CharField(max_length=30000)
    docset_status = models.CharField(max_length=250)
    derived_from = models.CharField(max_length=250)
    buildsite_private_notes = models.CharField(max_length=11000)
    class Meta:
        db_table = u'docset'

class LeedArea(models.Model):
    leed_area_id = models.CharField(max_length=10, primary_key=True)
    leed_area_title = models.CharField(max_length=1000)
    leed_area_display_order = models.IntegerField()
    class Meta:
        db_table = u'leed_area'

class LeedCreditAttribute(models.Model):
    leed_credit_attribute_id = models.IntegerField(primary_key=True)
    leed_credit = models.ForeignKey('LeedCredit')
    attribute = models.ForeignKey('Attribute')
    display_order = models.IntegerField()
    class Meta:
        db_table = u'leed_credit_attribute'

class MsdsDocument(models.Model):
    msds_group = models.ForeignKey('MsdsGroup')
    document = models.ForeignKey('Document')
    position = models.SmallIntegerField()
    class Meta:
        db_table = u'msds_document'

class MsdsGroup(models.Model):
    msds_group_id = models.CharField(max_length=250, primary_key=True)
    name = models.CharField(max_length=250)
    position = models.IntegerField()
    class Meta:
        db_table = u'msds_group'

class Attribute(models.Model):
    attribute_id = models.CharField(max_length=250, primary_key=True)
    attribute_name = models.CharField(unique=True, max_length=250)
    attribute_type = models.CharField(max_length=100)
    attribute_description = models.CharField(max_length=30000)
    data_type_id = models.CharField(max_length=100)
    value_units = models.CharField(max_length=100)
    detail_display_order = models.IntegerField()
    result_display_type = models.CharField(max_length=100)
    result_display_order = models.IntegerField()
    search_display_order = models.IntegerField()
    comments = models.CharField(max_length=10000)
    class Meta:
        db_table = u'attribute'

class ProductAttributeValue(models.Model):
    product_attribute_value_id = models.IntegerField(primary_key=True)
    product = models.ForeignKey('Product')
    attribute = models.ForeignKey('Attribute')
    val = models.CharField(max_length=1000)
    max_val = models.CharField(max_length=1000)
    class Meta:
        db_table = u'product_attribute_value'

class ProductKeyword(models.Model):
    keyword_id = models.IntegerField(primary_key=True)
    keyword = models.CharField(max_length=250)
    keyword_type = models.TextField() # This field type is a guess.
    product = models.ForeignKey('Product')
    score = models.IntegerField()
    class Meta:
        db_table = u'product_keyword'

class LeedCredit(models.Model):
    leed_credit_id = models.CharField(max_length=250, primary_key=True)
    leed_area = models.ForeignKey('LeedArea')
    leed_section_name = models.CharField(max_length=250)
    leed_title = models.CharField(max_length=1000)
    buildsite_description_html = models.CharField(max_length=30000)
    leed_version = models.CharField(max_length=250)
    buildsite_template_id = models.CharField(max_length=250)
    standard_url = models.CharField(max_length=1000)
    pdf_file = models.CharField(max_length=1000)
    leed_credit_type = models.CharField(max_length=250)
    class Meta:
        db_table = u'leed_credit'

class ProductLeedCredit(models.Model):
    product_leed_credit_id = models.IntegerField(primary_key=True)
    product = models.ForeignKey('Product')
    leed_credit = models.ForeignKey('LeedCredit')
    class Meta:
        db_table = u'product_leed_credit'

class ProductRelated(models.Model):
    product_related_id = models.IntegerField(primary_key=True)
    product = models.ForeignKey('Product')
    related_product = models.ForeignKey('Product')
    related_product_name = models.CharField(max_length=250)
    related_type = models.CharField(max_length=250)
    display_order = models.IntegerField()
    section_title = models.CharField(max_length=250)
    section_document = models.ForeignKey('Document')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product_related'

class Company(models.Model):
    company_id = models.CharField(max_length=250, primary_key=True)
    company_type = models.CharField(max_length=250)
    branch_of = models.ForeignKey('self')
    division_of = models.ForeignKey('self')
    linecard_grouping = models.ForeignKey('Grouping')
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    legal_name = models.CharField(max_length=250)
    company_nickname = models.CharField(max_length=250)
    company_url = models.CharField(max_length=250)
    company_logo_file = models.CharField(max_length=250)
    sweets_id = models.CharField(max_length=250)
    company_summary_text = models.CharField(max_length=11000)
    public_contact_type = models.CharField(max_length=250)
    public_contact_name = models.CharField(max_length=250)
    public_contact_phone = models.CharField(max_length=250)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250)
    buildsite_public_notes = models.CharField(max_length=11000)
    check_flags = models.CharField(max_length=250)
    buildsite_private_notes = models.CharField(max_length=15000)
    incident_log = models.CharField(max_length=30000)
    publisher_status = models.CharField(max_length=250)
    permission_granted = models.CharField(max_length=250)
    content_via = models.CharField(max_length=250)
    last_qa_complete_date = models.CharField(max_length=250)
    last_media_received_date = models.CharField(max_length=250)
    last_publish_date = models.CharField(max_length=250)
    last_update_date = models.CharField(max_length=250)
    next_media_update_date = models.CharField(max_length=250)
    next_paper_update_date = models.CharField(max_length=250)
    next_web_update_date = models.CharField(max_length=250)
    web_update_interval = models.CharField(max_length=250)
    went_live_date = models.CharField(max_length=250)
    company_search_tsvector = models.TextField() # This field type is a guess.
    company_search_keywords = models.TextField()
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    count_product = models.IntegerField()
    count_green = models.IntegerField()
    count_product_admin = models.IntegerField()
    count_green_admin = models.IntegerField()
    class Meta:
        db_table = u'company'

class Publication(models.Model):
    publication_id = models.CharField(max_length=250, primary_key=True)
    company = models.ForeignKey('Company')
    buildsite_publication_title = models.CharField(max_length=250)
    publisher_publication_title = models.CharField(max_length=250)
    publisher_publication_id = models.CharField(max_length=250)
    publication_type = models.CharField(max_length=250)
    web_url = models.CharField(max_length=250)
    web_completeness = models.CharField(max_length=250)
    web_file_format = models.CharField(max_length=250)
    standard_electronic_offered = models.CharField(max_length=250)
    electronic_completeness = models.CharField(max_length=250)
    electronic_file_format = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'publication'

class Standard(models.Model):
    standard_id = models.IntegerField(primary_key=True)
    standard_org_id = models.CharField(max_length=250)
    standard_document_identifier = models.CharField(max_length=250)
    other_identifiers = models.CharField(max_length=1024)
    category = models.ForeignKey('Category')
    official_title = models.CharField(max_length=250)
    official_description = models.CharField(max_length=30000)
    buildsite_private_notes = models.CharField(max_length=30000)
    parameter_info = models.CharField(max_length=1024)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'standard'

class Category(models.Model):
    category_id = models.CharField(max_length=250, primary_key=True)
    parent = models.ForeignKey('self')
    category_title = models.CharField(max_length=250)
    category_full_title = models.CharField(max_length=1024)
    buildsite_description = models.CharField(max_length=1024)
    see_also_category_ids = models.CharField(max_length=1024)
    see_instead_category_ids = models.CharField(max_length=1024)
    mf_see_also_category_ids = models.CharField(max_length=1024)
    mf_see_instead_category_ids = models.CharField(max_length=1024)
    mf_references_from = models.CharField(max_length=1024)
    mf_includes = models.CharField(max_length=1024)
    mf_usually_includes = models.CharField(max_length=1024)
    mf_may_include = models.CharField(max_length=1024)
    mf_note = models.CharField(max_length=1024)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250)
    check_flags = models.CharField(max_length=250)
    buildsite_private_notes = models.CharField(max_length=11000)
    buildsite_public_notes = models.CharField(max_length=11000)
    category_search_tsvector = models.TextField() # This field type is a guess.
    category_search_keywords = models.TextField()
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'category'

class CreditCard(models.Model):
    credit_card_id = models.IntegerField(primary_key=True)
    customer_account = models.ForeignKey('CustomerAccount')
    card_active = models.BooleanField()
    billing_from_account = models.BooleanField()
    billing_name = models.CharField(max_length=250)
    billing_street = models.CharField(max_length=250)
    billing_city = models.CharField(max_length=250)
    billing_region = models.CharField(max_length=250)
    billing_postal_code = models.CharField(max_length=250)
    billing_country = models.CharField(max_length=250)
    cc_type = models.CharField(max_length=250)
    cc_number_encrypted = models.CharField(max_length=1024)
    cc_number_last4 = models.CharField(max_length=20)
    cc_expire_month = models.TextField() # This field type is a guess.
    cc_expire_year = models.TextField() # This field type is a guess.
    cc_verif_number = models.TextField() # This field type is a guess.
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'credit_card'

class GatewayPayment(models.Model):
    payment_id = models.IntegerField(primary_key=True)
    customer_order = models.ForeignKey('CustomerOrder')
    credit_card = models.ForeignKey('CreditCard')
    recur_index = models.IntegerField()
    txn_start_epoch = models.IntegerField()
    txn_finish_epoch = models.IntegerField()
    txn_status_flag = models.TextField() # This field type is a guess.
    txn_type = models.CharField(max_length=20)
    txn_amount = models.DecimalField(max_digits=10, decimal_places=2)
    txn_avs_flags = models.CharField(max_length=10)
    txn_verif_flags = models.CharField(max_length=10)
    txn_id = models.CharField(max_length=250)
    txn_refnum = models.CharField(max_length=250)
    txn_result_code = models.CharField(max_length=250)
    txn_message = models.CharField(max_length=1024)
    gw_system = models.CharField(max_length=250)
    gw_account = models.CharField(max_length=250)
    gw_testmode = models.BooleanField()
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'gateway_payment'

class CustomerOrder(models.Model):
    customer_order_id = models.IntegerField(primary_key=True)
    customer_user = models.ForeignKey('CustomerUser')
    service_nickname = models.ForeignKey('Service', db_column='service_nickname')
    service_dsn = models.CharField(max_length=250)
    product_params = models.CharField(max_length=1024)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    recur_interval = models.CharField(max_length=250)
    created_epoch = models.IntegerField()
    order_start = models.DateField()
    order_expires = models.DateField()
    order_status = models.CharField(max_length=250)
    free_until = models.DateField()
    ipaddr = models.CharField(max_length=20)
    private_comments = models.CharField(max_length=11000)
    credit_card = models.ForeignKey('CreditCard')
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_order'

class Grouping(models.Model):
    grouping_id = models.IntegerField(primary_key=True)
    grouping_name = models.CharField(unique=True, max_length=250)
    grouping_type = models.CharField(max_length=250)
    parent = models.ForeignKey('self')
    buildsite_private_notes = models.CharField(max_length=11000)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'grouping'

class LegacyAccount(models.Model):
    account_id = models.CharField(max_length=250, primary_key=True)
    customer_id = models.CharField(max_length=250)
    account_type = models.CharField(max_length=250)
    access_constraints = models.CharField(max_length=250)
    allow_self_registration = models.CharField(max_length=250)
    block_access = models.CharField(max_length=250)
    block_reason = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    signed_final_date = models.CharField(max_length=250)
    signed_trial_date = models.CharField(max_length=250)
    expiration_date = models.CharField(max_length=250)
    mail_opt_out = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    sponsor_id = models.CharField(max_length=250)
    class Meta:
        db_table = u'legacy_account'

class LegacyAccountPrivateFile(models.Model):
    private_file_id = models.CharField(max_length=250, primary_key=True)
    creator_user = models.ForeignKey('LegacyBuildsiteUser', db_column='creator_user')
    owner = models.ForeignKey('LegacyAccountLocation', db_column='owner')
    file_original_path = models.CharField(max_length=250)
    file_format_type = models.CharField(max_length=250)
    file_mtime = models.CharField(max_length=250)
    file_title = models.CharField(max_length=250)
    file_comment = models.CharField(max_length=1024)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    page_count = models.CharField(max_length=250)
    is_public = models.CharField(max_length=250)
    scope = models.CharField(max_length=250)
    parent = models.ForeignKey('self', db_column='parent')
    file_class = models.CharField(max_length=250)
    shortcut_to = models.CharField(max_length=250)
    file_size = models.CharField(max_length=250)
    replaced_by_doc = models.CharField(max_length=250)
    deleted_date = models.CharField(max_length=250)
    is_deleted = models.CharField(max_length=250)
    replaced_by_date = models.CharField(max_length=250)
    deleted_by_user = models.CharField(max_length=250)
    replaced_by_user = models.CharField(max_length=250)
    class Meta:
        db_table = u'legacy_account_private_file'

class LegacyAccountPrivateLocation(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    private_location_id = models.CharField(max_length=250, primary_key=True)
    account_private_company_ref = models.ForeignKey('LegacyAccountPrivateCompany', db_column='account_private_company_ref')
    location_nickname = models.CharField(max_length=250)
    location_state = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    class Meta:
        db_table = u'legacy_account_private_location'

class LegacyAccountPrivateCompany(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    owner = models.ForeignKey('LegacyAccountLocation', db_column='owner')
    private_company_id = models.CharField(max_length=250, primary_key=True)
    company_fullname = models.CharField(max_length=250)
    company_url = models.CharField(max_length=250)
    company_state = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    class Meta:
        db_table = u'legacy_account_private_company'

class LegacyAccountLocation(models.Model):
    in_directory = models.CharField(max_length=250)
    location_phone = models.CharField(max_length=250)
    location_fax = models.CharField(max_length=250)
    addr_po = models.CharField(max_length=250)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_region_i = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_postal_code_i = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    account_location_id = models.CharField(max_length=250, primary_key=True)
    location_nickname = models.CharField(max_length=250)
    location_fullname = models.CharField(max_length=250)
    location_url = models.CharField(max_length=250)
    account = models.ForeignKey('LegacyAccount')
    company_location_ref = models.ForeignKey('Company', db_column='company_location_ref')
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    mail_opt_out = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    block_date = models.CharField(max_length=250)
    block_access = models.CharField(max_length=250)
    block_reason = models.CharField(max_length=250)
    class Meta:
        db_table = u'legacy_account_location'

class LegacyAccountPrivatePerson(models.Model):
    given_name = models.CharField(max_length=250)
    family_name = models.CharField(max_length=250)
    vcard_fullname = models.CharField(max_length=250)
    vcard_name = models.CharField(max_length=250)
    job_title = models.CharField(max_length=250)
    work_phone = models.CharField(max_length=250)
    cell_phone = models.CharField(max_length=250)
    fax_phone = models.CharField(max_length=250)
    home_phone = models.CharField(max_length=250)
    pager_phone = models.CharField(max_length=250)
    email_address = models.CharField(max_length=250)
    comment = models.CharField(max_length=1024)
    private_person_id = models.CharField(max_length=250, primary_key=True)
    person_state = models.CharField(max_length=250)
    account_private_company_ref = models.CharField(max_length=250)
    primary_location = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    class Meta:
        db_table = u'legacy_account_private_person'

class LegacySentMessage(models.Model):
    message_id = models.CharField(max_length=250, primary_key=True)
    body_file_name = models.CharField(max_length=250)
    sender = models.ForeignKey('LegacyBuildsiteUser', db_column='sender')
    owner = models.ForeignKey('LegacyAccountLocation', db_column='owner')
    recipient_fkey = models.ForeignKey('LegacyAccountPrivatePerson', db_column='recipient_fkey')
    recipient_address = models.CharField(max_length=250)
    recipient_address_type = models.CharField(max_length=250)
    time_sent = models.CharField(max_length=250)
    message_template_type = models.CharField(max_length=250)
    status_received_epoch = models.CharField(max_length=250)
    message_status = models.CharField(max_length=250)
    message_status_ack = models.CharField(max_length=250)
    group_message_id = models.CharField(max_length=250)
    base_message_id = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    attached_file_ids = models.CharField(max_length=30000)
    subject = models.CharField(max_length=250)
    class Meta:
        db_table = u'legacy_sent_message'

class LegacyBuildsiteUser(models.Model):
    given_name = models.CharField(max_length=250)
    family_name = models.CharField(max_length=250)
    vcard_fullname = models.CharField(max_length=250)
    vcard_name = models.CharField(max_length=250)
    job_title = models.CharField(max_length=250)
    work_phone = models.CharField(max_length=250)
    cell_phone = models.CharField(max_length=250)
    fax_phone = models.CharField(max_length=250)
    home_phone = models.CharField(max_length=250)
    pager_phone = models.CharField(max_length=250)
    email_address = models.CharField(max_length=250)
    comment = models.CharField(max_length=1024)
    user_id = models.CharField(max_length=250, primary_key=True)
    staff_user = models.CharField(max_length=250)
    user_password = models.CharField(max_length=250)
    preferences = models.CharField(max_length=250)
    user_role = models.CharField(max_length=250)
    primary_location = models.ForeignKey('LegacyAccountLocation', db_column='primary_location')
    primary_only = models.CharField(max_length=250)
    auto_ctime = models.CharField(max_length=100)
    auto_mtime = models.CharField(max_length=100)
    login_id = models.CharField(max_length=250)
    mail_opt_out = models.CharField(max_length=250)
    user_department = models.CharField(max_length=250)
    email_opt_out = models.CharField(max_length=250)
    block_date = models.CharField(max_length=250)
    block_access = models.CharField(max_length=250)
    block_reason = models.CharField(max_length=250)
    test_user = models.CharField(max_length=250)
    email_opt_out_date = models.CharField(max_length=250)
    mail_opt_out_date = models.CharField(max_length=250)
    document_queue = models.CharField(max_length=11000)
    current_message = models.CharField(max_length=11000)
    class Meta:
        db_table = u'legacy_buildsite_user'

class MessageRecipient(models.Model):
    recipient_id = models.CharField(max_length=250, primary_key=True)
    message = models.ForeignKey('Message')
    type = models.CharField(max_length=10)
    address = models.CharField(max_length=250)
    contact = models.ForeignKey('AddressbookPerson')
    status = models.CharField(max_length=250)
    send_type = models.CharField(max_length=10)
    class Meta:
        db_table = u'message_recipient'

class Message(models.Model):
    message_id = models.CharField(max_length=250, primary_key=True)
    body_file_name = models.CharField(max_length=250)
    sender = models.CharField(max_length=250)
    owner = models.CharField(max_length=250)
    recipient_fkey = models.CharField(max_length=250)
    recipient_address = models.CharField(max_length=250)
    recipient_address_type = models.CharField(max_length=250)
    time_sent = models.DateTimeField()
    message_template_type = models.CharField(max_length=250)
    status_received_epoch = models.CharField(max_length=250)
    message_status = models.CharField(max_length=250)
    message_status_ack = models.CharField(max_length=250)
    group_message_id = models.CharField(max_length=250)
    base_message_id = models.CharField(max_length=250)
    attached_file_ids = models.CharField(max_length=30000)
    subject = models.CharField(max_length=250)
    body = models.TextField()
    package_id = models.CharField(max_length=250)
    message_ext_id = models.CharField(max_length=250)
    attach_type = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'message'

class Document(models.Model):
    document_id = models.CharField(max_length=250, primary_key=True)
    document_type = models.CharField(max_length=250)
    publication = models.ForeignKey('Publication')
    replaced_by_document = models.ForeignKey('self')
    original_publisher = models.ForeignKey('Company')
    about_company = models.ForeignKey('Company')
    doc_type = models.ForeignKey('DocTypeInfo', db_column='doc_type')
    other_doc_types = models.CharField(max_length=250)
    publisher_document_title = models.CharField(max_length=250)
    publisher_doc_id = models.CharField(max_length=250)
    publisher_doc_date = models.CharField(max_length=250)
    sweets_doc_id = models.CharField(max_length=250)
    lang_id = models.CharField(max_length=250)
    country_id = models.CharField(max_length=250)
    source_url = models.CharField(max_length=1024)
    source_path = models.CharField(max_length=1024)
    source_mtime = models.IntegerField()
    source_filesize = models.IntegerField()
    source_checksum = models.IntegerField()
    derived_path = models.CharField(max_length=1024)
    derived_format = models.CharField(max_length=250)
    derived_how = models.CharField(max_length=250)
    derived_params = models.CharField(max_length=1024)
    derived_pagecount = models.IntegerField()
    derived_filesize = models.IntegerField()
    authoritative_docset = models.CharField(max_length=250)
    image_path = models.CharField(max_length=250)
    document_derived_from = models.CharField(max_length=250)
    file_format_type = models.CharField(max_length=250)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250)
    buildsite_private_notes = models.CharField(max_length=11000)
    buildsite_public_notes = models.CharField(max_length=11000)
    check_flags = models.CharField(max_length=250)
    product = models.ForeignKey('Product')
    category = models.ForeignKey('Category')
    is_generic = models.BooleanField()
    document_role = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'document'

class PackageItem(models.Model):
    package_item_id = models.CharField(max_length=255, primary_key=True)
    package = models.ForeignKey('File')
    position = models.IntegerField()
    item_type = models.TextField() # This field type is a guess.
    document = models.ForeignKey('Document')
    file = models.ForeignKey('File')
    class Meta:
        db_table = u'package_item'

class File(models.Model):
    file_id = models.CharField(max_length=250, primary_key=True)
    creator_user = models.ForeignKey('AccountUser', db_column='creator_user')
    owner = models.ForeignKey('AccountLocation', db_column='owner')
    file_original_path = models.CharField(max_length=250)
    file_format_type = models.CharField(max_length=250)
    file_mtime = models.CharField(max_length=250)
    file_title = models.CharField(max_length=250)
    file_comment = models.CharField(max_length=1024)
    page_count = models.CharField(max_length=250)
    is_public = models.BooleanField()
    scope = models.CharField(max_length=250)
    parent = models.ForeignKey('self', db_column='parent')
    shortcut_to = models.CharField(max_length=250)
    file_size = models.CharField(max_length=250)
    replaced_by_doc = models.CharField(max_length=250)
    deleted_date = models.CharField(max_length=250)
    is_deleted = models.BooleanField()
    replaced_by_date = models.CharField(max_length=250)
    deleted_by_user = models.CharField(max_length=250)
    replaced_by_user = models.CharField(max_length=250)
    file_class = models.TextField() # This field type is a guess.
    package_toc_type = models.CharField(max_length=255)
    package_toc_template = models.CharField(max_length=255)
    package_toc_data = models.TextField()
    package_ext_id = models.CharField(max_length=250)
    file_extension = models.CharField(max_length=10)
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'file'

class ProductStandard(models.Model):
    product_standard_id = models.IntegerField(primary_key=True)
    product = models.ForeignKey('Product')
    standard_id = models.IntegerField()
    standard_org_id = models.CharField(max_length=250)
    standard_document_identifier = models.CharField(max_length=250)
    standard_parameters = models.CharField(max_length=1024)
    astm_search_tsvector = models.TextField() # This field type is a guess.
    astm_search_keywords = models.TextField()
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product_standard'

class Product(models.Model):
    product_id = models.CharField(max_length=250, primary_key=True)
    manufacturer = models.ForeignKey('Company')
    category = models.ForeignKey('Category')
    superseded_by_product = models.ForeignKey('self')
    product_name = models.CharField(max_length=250)
    brand = models.CharField(max_length=250)
    mfg_product_id = models.CharField(max_length=250)
    mfg_categories = models.CharField(max_length=1024)
    mfg_product_kicker = models.CharField(max_length=1024)
    mfg_flags = models.CharField(max_length=250)
    mfg_short_text = models.CharField(max_length=1024)
    mfg_long_text = models.CharField(max_length=1024)
    discontinued_date = models.CharField(max_length=250)
    is_accessory = models.CharField(max_length=250)
    systemness = models.CharField(max_length=250)
    system_parts = models.CharField(max_length=1024)
    related_products = models.CharField(max_length=1024)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250)
    buildsite_public_notes = models.CharField(max_length=11000)
    buildsite_private_notes = models.CharField(max_length=11000)
    check_flags = models.CharField(max_length=250)
    product_name_search_tsvector = models.TextField() # This field type is a guess.
    product_name_search_keywords = models.TextField()
    product_name_ext_search_tsvector = models.TextField() # This field type is a guess.
    is_green = models.BooleanField()
    auto_ctime = models.DateTimeField()
    auto_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product'

class DjangoAdminLog(models.Model):
    id = models.IntegerField(primary_key=True)
    action_time = models.DateTimeField()
    user = models.ForeignKey('AuthUser')
    content_type = models.ForeignKey('DjangoContentType')
    object_id = models.TextField()
    object_repr = models.CharField(max_length=200)
    action_flag = models.SmallIntegerField()
    change_message = models.TextField()
    class Meta:
        db_table = u'django_admin_log'

class AuthUser(models.Model):
    id = models.IntegerField(primary_key=True)
    username = models.CharField(unique=True, max_length=30)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    email = models.CharField(max_length=75)
    password = models.CharField(max_length=128)
    is_staff = models.BooleanField()
    is_active = models.BooleanField()
    is_superuser = models.BooleanField()
    last_login = models.DateTimeField()
    date_joined = models.DateTimeField()
    class Meta:
        db_table = u'auth_user'

class CategoryCounts(models.Model):
    category_id = models.CharField(max_length=250, primary_key=True)
    products = models.TextField() # This field type is a guess.
    manufacturers = models.TextField() # This field type is a guess.
    products_admin = models.TextField() # This field type is a guess.
    manufacturers_admin = models.TextField() # This field type is a guess.
    green_products = models.TextField() # This field type is a guess.
    green_manufacturers = models.TextField() # This field type is a guess.
    green_products_admin = models.TextField() # This field type is a guess.
    green_manufacturers_admin = models.TextField() # This field type is a guess.
    class Meta:
        db_table = u'category_counts'

class CategoryCountsV(models.Model):
    category_id = models.CharField(max_length=250)
    products = models.TextField() # This field type is a guess.
    manufacturers = models.TextField() # This field type is a guess.
    products_admin = models.TextField() # This field type is a guess.
    manufacturers_admin = models.TextField() # This field type is a guess.
    green_products = models.TextField() # This field type is a guess.
    green_manufacturers = models.TextField() # This field type is a guess.
    green_products_admin = models.TextField() # This field type is a guess.
    green_manufacturers_admin = models.TextField() # This field type is a guess.
    class Meta:
        db_table = u'category_counts_v'

class Schemaversions(models.Model):
    version = models.IntegerField()
    type = models.CharField(max_length=8)
    installed = models.CharField(max_length=20)
    class Meta:
        db_table = u'schemaversions'

