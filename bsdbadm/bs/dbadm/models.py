import re
from django.db import models
from django.db import connection
from datetime import datetime

class CustomModel(object):
    def __strip_name(self, name): # generic strip
        name = name.lower()
        name = re.sub('[^a-z0-9]', '_', name)
        name = re.sub('^_+|_+$', '', name)
        name = re.sub('_+', '_', name)
        return name

    def gen_MODERN_pk(self):
        cursor = connection.cursor()
        cursor.execute("SELECT nextval('main')")
        row = cursor.fetchone()
        return "%s_%s" % (self.__class__._meta.db_table, row[0])

    def gen_company_pk(self):
        return self.__strip_name( self.company_nickname )

    def gen_product_pk(self):
        return self.__strip_name( self.product_name )

    def gen_pk(self):
        if self.pk:
            return

        for f in self.__class__._meta.local_fields:
            if f.primary_key:
                if isinstance(f, models.fields.AutoField):
                    return
                break

        model = self.__class__.__name__.lower()
        f = getattr(self, 'gen_%s_pk' % model, self.gen_MODERN_pk)
        pk = f()
        if not pk:
            return
        self.pk = pk

    def save(self):
        if not hasattr(self, 'exclude_submit_fields'):
            self.exclude_submit_fields = []
        self.exclude_submit_fields.extend(['auto_ctime', 'auto_mtime'])
        base = self.__class__
        while base._meta.proxy:
            base = base._meta.proxy_for_model
        meta = base._meta
        meta.local_fields = [ f for f in meta.local_fields if not f.attname in self.exclude_submit_fields ]

        self.gen_pk()
        if hasattr(self, 'admin_mtime'):
            self.admin_mtime = datetime.now()
        super(CustomModel, self).save()

class Account(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account'

class AccountLocation(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_location'

class AccountPrivateLocation(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_private_location'

class AccountUser(CustomModel, models.Model):
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
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'account_user'

class AddressbookCompany(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'addressbook_company'

class AddressbookPerson(CustomModel, models.Model):
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
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'addressbook_person'

Attribute_data_choices = (("boolean", "boolean"),
                    ("fraction", "fraction"),
                    ("integer", "integer"),
                    ("float", "float"),
                    ("textline", "textline"))
Attribute_type_choices = (("leed_product", "leed_product"),
                        ("leed_entry", "leed_entry"))

class Attribute(CustomModel, models.Model):
    attribute_id = models.CharField(max_length=250, primary_key=True)
    attribute_name = models.CharField(unique=True, max_length=250)
    attribute_type = models.CharField(max_length=100)
    attribute_description = models.CharField(max_length=30000)
    data_type_id = models.CharField(max_length=100)
    value_units = models.CharField(max_length=100, blank=True, null=True)
    detail_display_order = models.IntegerField()
    result_display_type = models.CharField(max_length=100, blank=True, null=True)
    result_display_order = models.IntegerField()
    search_display_order = models.IntegerField()
    comments = models.CharField(max_length=10000, blank=True, null=True)
    class Meta:
        db_table = u'attribute'
        verbose_name = 'leed attribute'
    def __unicode__(self):
        a = ['[', self.attribute_id, ']']
        if self.value_units:
            a.extend([' ', '%s' % self.value_units])
        return ''.join(a)

class Category(CustomModel, models.Model):
    category_id = models.CharField(max_length=250, primary_key=True)
    parent = models.ForeignKey('self')
    category_title = models.CharField(max_length=250)
    category_full_title = models.CharField(max_length=1024)
    buildsite_description = models.CharField(max_length=1024, blank=True, null=True)
    see_also_category_ids = models.CharField(max_length=1024, help_text='Enter each value on the separate line', blank=True, null=True)
    see_instead_category_ids = models.CharField(max_length=1024, help_text='Enter each value on the separate line', blank=True, null=True)
    mf_see_also_category_ids = models.CharField(max_length=1024, help_text='Enter each value on the separate line', blank=True, null=True)
    mf_see_instead_category_ids = models.CharField(max_length=1024, help_text='Enter each value on the separate line', blank=True, null=True)
    mf_references_from = models.CharField(max_length=1024, blank=True, null=True)
    mf_includes = models.CharField(max_length=1024, blank=True, null=True)
    mf_usually_includes = models.CharField(max_length=1024, blank=True, null=True)
    mf_may_include = models.CharField(max_length=1024, blank=True, null=True)
    mf_note = models.CharField(max_length=1024, blank=True, null=True)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250, blank=True, null=True, default='afterqa')
    check_flags = models.CharField(max_length=250, blank=True, null=True)
    buildsite_private_notes = models.CharField(max_length=11000, blank=True, null=True)
    buildsite_public_notes = models.CharField(max_length=11000, blank=True, null=True)
    category_search_tsvector = models.TextField(blank=True, null=True) # This field type is a guess.
    category_search_keywords = models.TextField(blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'category'
        verbose_name_plural = 'categories'

    def __unicode__(self):
        return self.category_id


class CategoryAttribute(models.Model):
    category_attribute_id = models.AutoField(primary_key=True)
    category = models.ForeignKey('Category')
    attribute = models.ForeignKey('Attribute')
    class Meta:
        db_table = u'category_attribute'

class CategoryCounts(CustomModel, models.Model):
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

class CategoryDescendant(models.Model):
    category = models.ForeignKey('Category')
    descendant = models.ForeignKey('Category', related_name='descendant_set')
    descendant_distance = models.IntegerField()
    class Meta:
        db_table = u'category_descendant'

class CategoryGrouping(CustomModel, models.Model):
    category_grouping_id = models.AutoField(primary_key=True)
    category = models.ForeignKey('Category')
    grouping = models.ForeignKey('Grouping')
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'category_grouping'

class CategoryKeyword(models.Model):
    keyword_id = models.IntegerField(primary_key=True)
    keyword = models.CharField(max_length=250)
    keyword_type = models.TextField() # This field type is a guess.
    category = models.ForeignKey('Category')
    score = models.IntegerField()
    class Meta:
        db_table = u'category_keyword'


Company_company_type_options = (
    ('contractor', 'contractor'),
    ('dealer', 'dealer'),
    ('library_publisher', 'library_publisher'),
    ('manufacturer', 'manufacturer'),
    ('other_company', 'other_company'),
)

Company_web_update_interval_options = (
    ('day','day'),
    ('month', 'month'),
    ('quarter', 'quarter'),
    ('semi_annual', 'semi-annual'),
    ('week', 'week'),
    ('year', 'year'),
)

class Company(CustomModel, models.Model):
    company_id = models.CharField(max_length=250, primary_key=True, blank=True)
    company_type = models.CharField(max_length=250, choices=Company_company_type_options)
    branch_of = models.ForeignKey('self', related_name='branches_set', blank=True, null=True)
    division_of = models.ForeignKey('self', related_name='divisions_set', blank=True, null=True)
    linecard_grouping = models.ForeignKey('Grouping', blank=True, null=True)
    location_phone = models.CharField(max_length=250, blank=True, null=True)
    location_fax = models.CharField(max_length=250, blank=True, null=True)
    addr_po = models.CharField(max_length=250, blank=True, null=True)
    addr_street = models.CharField(max_length=250, blank=True, null=True)
    addr_city = models.CharField(max_length=250, blank=True, null=True)
    addr_region = models.CharField(max_length=250, blank=True, null=True)
    addr_postal_code = models.CharField(max_length=250, blank=True, null=True)
    addr_country = models.CharField(max_length=250, blank=True, null=True)
    legal_name = models.CharField(max_length=250)
    company_nickname = models.CharField(max_length=250, blank=True, null=True)
    company_url = models.CharField(max_length=250, blank=True, null=True)
    company_logo_file = models.CharField(max_length=250, blank=True, null=True)
    sweets_id = models.CharField(max_length=250, blank=True, null=True)
    company_summary_text = models.CharField(max_length=11000, blank=True, null=True)
    public_contact_type = models.CharField(max_length=250, blank=True, null=True)
    public_contact_name = models.CharField(max_length=250, blank=True, null=True)
    public_contact_phone = models.CharField(max_length=250, blank=True, null=True)
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250, blank=True, null=True, default='afterqa')
    buildsite_public_notes = models.CharField(max_length=11000, blank=True, null=True)
    check_flags = models.CharField(max_length=250, blank=True, null=True)
    buildsite_private_notes = models.CharField(max_length=15000, blank=True, null=True)
    incident_log = models.CharField(max_length=30000, blank=True, null=True)
    publisher_status = models.CharField(max_length=250, blank=True, null=True)
    permission_granted = models.CharField(max_length=250)
    content_via = models.CharField(max_length=250, blank=True, null=True)
    last_qa_complete_date = models.CharField(max_length=250, blank=True, null=True)
    last_media_received_date = models.CharField(max_length=250, blank=True, null=True)
    last_publish_date = models.CharField(max_length=250, blank=True, null=True)
    last_update_date = models.CharField(max_length=250, blank=True, null=True)
    next_media_update_date = models.CharField(max_length=250, blank=True, null=True)
    next_paper_update_date = models.CharField(max_length=250, blank=True, null=True)
    next_web_update_date = models.CharField(max_length=250, blank=True, null=True)
    web_update_interval = models.CharField(max_length=250, blank=True, null=True, choices=Company_web_update_interval_options)
    went_live_date = models.CharField(max_length=250, blank=True, null=True)
    company_search_tsvector = models.TextField(blank=True, null=True) # This field type is a guess.
    company_search_keywords = models.TextField(blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    count_product = models.IntegerField()
    count_green = models.IntegerField()
    count_product_admin = models.IntegerField()
    count_green_admin = models.IntegerField()
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'company'
        ordering = ['company_nickname', 'legal_name']
        verbose_name_plural='companies'
    def __unicode__(self):
        return self.company_id
        a = ['[', self.company_id, ']']
        return ''.join(a)

CompanyFeature_names = (
    ("companyresource", "companyresource"),
    ("directory", "directory"),
    ("productmatch", "productmatch"),
    ("systemseller", "systemseller"),
)

CompanyFeature_statuses = (
    ("live", "live"),
    ("qa", "qa"),
)
CompanyFeature_levels = (
    ("economy", "economy"),
)

class CompanyFeature(CustomModel, models.Model):
    company_feature_id = models.AutoField(primary_key=True)
    company = models.ForeignKey('Company')
    feature_name = models.CharField(max_length=250, choices=CompanyFeature_names)
    feature_level = models.CharField(max_length=250, choices=CompanyFeature_levels)
    feature_status = models.CharField(max_length=250, choices=CompanyFeature_statuses)
    feature_params = models.CharField(max_length=1024, blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'company_feature'

class CompanyGrouping(CustomModel, models.Model):
    company_grouping_id = models.AutoField(primary_key=True)
    company = models.ForeignKey('Company')
    grouping = models.ForeignKey('Grouping')
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'company_grouping'

class CompanyKeyword(models.Model):
    keyword_id = models.IntegerField(primary_key=True)
    keyword = models.CharField(max_length=250)
    keyword_type = models.TextField() # This field type is a guess.
    company = models.ForeignKey('Company')
    score = models.IntegerField()
    class Meta:
        db_table = u'company_keyword'

class CreditCard(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'credit_card'

account_type_options = (
    ('individual', 'individual'),
)
account_purpose_options = (
    ('normal', 'normal'),
    ('test', 'test'),
)

class CustomerAccount(CustomModel, models.Model):
    customer_account_id = models.IntegerField(primary_key=True)
    account_name = models.CharField(unique=True, max_length=250)
    company = models.ForeignKey('Company', blank=True, null=True)
    account_type = models.CharField(max_length=250, choices=account_type_options)
    account_purpose = models.CharField(max_length=250, choices=account_purpose_options)
    block_reason = models.CharField(max_length=250, blank=True, null=True)
    location_phone = models.CharField(max_length=250, blank=True, null=True)
    location_fax = models.CharField(max_length=250, blank=True, null=True)
    addr_po = models.CharField(max_length=250, blank=True, null=True)
    addr_street = models.CharField(max_length=250)
    addr_city = models.CharField(max_length=250)
    addr_region = models.CharField(max_length=250)
    addr_postal_code = models.CharField(max_length=250)
    addr_country = models.CharField(max_length=250)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_account'
    def __unicode__(self):
        return self.account_name

class CustomerOrder(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    account = models.ForeignKey('Account')
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_order'

class CustomerUser(CustomModel, models.Model):
    customer_user_id = models.IntegerField(primary_key=True)
    customer_account = models.ForeignKey('CustomerAccount')
    login_id = models.CharField(unique=True, max_length=250)
    login_password = models.CharField(max_length=250)
    user_role = models.CharField(max_length=250)
    fullname = models.CharField(max_length=1024)
    email = models.CharField(max_length=250)
    phone = models.CharField(max_length=250)
    employer_name = models.CharField(max_length=250, blank=True, null=True)
    last_login = models.DateTimeField(blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'customer_user'
    def __unicode__(self):
        return self.fullname

class DocTypeInfo(models.Model):
    doc_type = models.CharField(max_length=250, primary_key=True)
    dt_order = models.FloatField()
    dt_abbrev = models.CharField(unique=True, max_length=3)
    dt_label = models.CharField(unique=True, max_length=250)
    dt_flags = models.CharField(max_length=250, blank=True, null=True)
    dt_help = models.CharField(max_length=10000, blank=True, null=True)
    class Meta:
        db_table = u'doc_type_info'
    def __unicode__(self):
        return self.doc_type

Docset_media_type_options = (
    ('CD', 'CD'),
    ('email', 'email'),
    ('floppy', 'floppy'),
    ('ftp', 'ftp'),
    ('intermediary', 'intermediary'),
    ('paper', 'paper'),
    ('scan', 'scan'),
    ('webspider', 'webspider'),
    ('zipdrive', 'zipdrive'),
)

Docset_docset_status_options = (
    ('no_progress', 'no_progress'),
    ('received', 'received'),
)
Docset_docset_type_options = (
    ('electronic', 'electronic'),
    ('paper', 'paper'),
)

class Docset(CustomModel, models.Model):
    docset_id = models.CharField(max_length=250, primary_key=True, blank=True, null=True)
    docset_type = models.CharField(max_length=10, choices=Docset_docset_type_options, default=Docset_docset_type_options[0])
    publication = models.ForeignKey('Publication')
    media_type = models.CharField(max_length=250, choices=Docset_media_type_options)
    is_standard = models.CharField(max_length=250)
    received_date = models.CharField(max_length=250)
    received_staff_id = models.CharField(max_length=250)
    acceptance = models.CharField(max_length=250)
    is_authoritative = models.CharField(max_length=250)
    filter_expr = models.CharField(max_length=1024)
    exclude_expr = models.CharField(max_length=1024)
    auto_ctime = models.CharField(max_length=100, blank=True, null=True)
    auto_mtime = models.CharField(max_length=100, blank=True, null=True)
    sent_update_reg_card = models.CharField(max_length=250)
    replaces_docset_id = models.CharField(max_length=250)
    incident_log = models.CharField(max_length=30000)
    docset_status = models.CharField(max_length=250, choices=Docset_docset_status_options)
    derived_from = models.CharField(max_length=250)
    buildsite_private_notes = models.CharField(max_length=11000)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'docset'
    def __unicode__(self):
        return self.docset_id

Document_is_generic_options = (
    ('f', 'f'),
)
Document_document_role_options = (
    ('none', 'none'),
    ('companyresource', 'companyresource'),
)
Document_file_format_types = (
    ('pdf', 'pdf'),
    ('excel', 'excel'),
    ('word', 'word'),
    ('text', 'text'),
    ('rtf', 'rtf'),
    ('html', 'html'),
    ('suffix_guess', 'suffix_guess'),
)

class Document(models.Model):
    document_id = models.CharField(max_length=250, primary_key=True, blank=True)
    document_type = models.CharField(max_length=250)
    publication = models.ForeignKey('Publication')
    replaced_by_document = models.ForeignKey('self', blank=True, null=True)
    original_publisher = models.ForeignKey('Company', related_name='published_documents_set', blank=True, null=True)
    about_company = models.ForeignKey('Company', related_name='documents_about_set', blank=True, null=True)
    doc_type = models.ForeignKey('DocTypeInfo', db_column='doc_type')
    other_doc_types = models.CharField(max_length=250, blank=True, null=True)
    publisher_document_title = models.CharField(max_length=250, blank=True, null=True)
    publisher_doc_id = models.CharField(max_length=250, blank=True, null=True)
    publisher_doc_date = models.CharField(max_length=250, blank=True, null=True)
    sweets_doc_id = models.CharField(max_length=250, blank=True, null=True)
    lang_id = models.CharField(max_length=250)
    country_id = models.CharField(max_length=250)
    source_url = models.CharField(max_length=1024, blank=True, null=True)
    source_path = models.CharField(max_length=1024, blank=True, null=True)
    source_mtime = models.IntegerField(blank=True, null=True)
    source_filesize = models.IntegerField(blank=True, null=True)
    source_checksum = models.IntegerField(blank=True, null=True)
    derived_path = models.CharField(max_length=1024, blank=True, null=True)
    derived_format = models.CharField(max_length=250, blank=True, null=True)
    derived_how = models.CharField(max_length=250, blank=True, null=True)
    derived_params = models.CharField(max_length=1024, blank=True, null=True)
    derived_pagecount = models.IntegerField(blank=True, null=True)
    derived_filesize = models.IntegerField(blank=True, null=True)
    authoritative_docset = models.CharField(max_length=250, blank=True, null=True)
    image_path = models.CharField(max_length=250, blank=True, null=True)
    document_derived_from = models.CharField(max_length=250, blank=True, null=True)
    file_format_type = models.CharField(max_length=250, choices=Document_file_format_types, default=Document_file_format_types[0])
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250, blank=True, null=True, default='afterqa')
    buildsite_private_notes = models.CharField(max_length=11000, blank=True, null=True)
    buildsite_public_notes = models.CharField(max_length=11000, blank=True, null=True)
    check_flags = models.CharField(max_length=250, blank=True, null=True)
    product = models.ForeignKey('Product', blank=True, null=True)
    category = models.ForeignKey('Category', blank=True, null=True)
    is_generic = models.BooleanField(choices=Document_is_generic_options)
    document_role = models.CharField(max_length=250, choices=Document_document_role_options, default=Document_document_role_options[0])
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'document'
    def __unicode__(self):
        a = [ self.doc_type.doc_type.replace('_', ' ').title() ]
        if self.publisher_document_title:
            a.extend([' - ', self.publisher_document_title])

        words = []

        if self.replaced_by_document_id:
            words.extend(['replaced with %s' % self.replaced_by_document_id])
        if self.suppress_reason_code:
            words.extend([' suppress reason: %s' % self.suppress_reason_code ])
        if len(words):
            a.extend([' (', ', '.join(words), ')'])

        return ''.join(a)

class File(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'file'

class GatewayPayment(CustomModel, models.Model):
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'gateway_payment'

class Grouping(CustomModel, models.Model):
    grouping_id = models.IntegerField(primary_key=True)
    grouping_name = models.CharField(unique=True, max_length=250)
    grouping_type = models.CharField(max_length=250)
    parent = models.ForeignKey('self', blank=True, null=True)
    buildsite_private_notes = models.CharField(max_length=11000, blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'grouping'
    def __unicode__(self):
        return self.grouping_name

class LeedArea(models.Model):
    leed_area_id = models.CharField(max_length=10, primary_key=True)
    leed_area_title = models.CharField(max_length=1000)
    leed_area_display_order = models.IntegerField()
    class Meta:
        db_table = u'leed_area'
    def __unicode__(self):
        return self.leed_area_id
        a = ['[', self.leed_area_id, ']']
        return ''.join(a)

class LeedCredit(models.Model):
    leed_credit_id = models.CharField(max_length=250, primary_key=True)
    leed_area = models.ForeignKey('LeedArea')
    leed_section_name = models.CharField(max_length=250)
    leed_title = models.CharField(max_length=1000)
    buildsite_description_html = models.CharField(max_length=30000, blank=True, null=True)
    leed_version = models.CharField(max_length=250)
    buildsite_template_id = models.CharField(max_length=250, blank=True, null=True)
    standard_url = models.CharField(max_length=1000, blank=True, null=True)
    pdf_file = models.CharField(max_length=1000, blank=True, null=True)
    leed_credit_type = models.CharField(max_length=250, blank=True, null=True)
    class Meta:
        db_table = u'leed_credit'
    def __unicode__(self):
        return self.leed_credit_id
        a = ['[', self.leed_credit_id, ']']
        return ''.join(a)

class LeedCreditAttribute(models.Model):
    leed_credit_attribute_id = models.AutoField(primary_key=True)
    leed_credit = models.ForeignKey('LeedCredit')
    attribute = models.ForeignKey('Attribute')
    display_order = models.IntegerField()
    class Meta:
        db_table = u'leed_credit_attribute'

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

class Message(CustomModel, models.Model):
    message_id = models.CharField(max_length=250, primary_key=True, blank=True)
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
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'message'

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

class MsdsDocument(models.Model):
    msds_group = models.ForeignKey('MsdsGroup', db_column='msds_group_id')
    document = models.ForeignKey('Document', db_column='document_id')
    position = models.SmallIntegerField()
    msds_document_id = models.IntegerField(primary_key=True)
    class Meta:
        db_table = u'msds_document'

class MsdsGroup(models.Model):
    msds_group_id = models.CharField(max_length=250, primary_key=True)
    name = models.CharField(max_length=250)
    position = models.IntegerField()
    class Meta:
        db_table = u'msds_group'

class PackageItem(models.Model):
    package_item_id = models.CharField(max_length=255, primary_key=True)
    package = models.ForeignKey('File', related_name='items_set')
    position = models.IntegerField()
    item_type = models.TextField() # This field type is a guess.
    document = models.ForeignKey('Document')
    file = models.ForeignKey('File')
    class Meta:
        db_table = u'package_item'

is_accessory_options = (
    ('true', 'true'),
    ('false', 'false'),
)

systemness_options = (
    ('yes', 'yes'),
    ('not', 'not'),
    ('application', 'application'),
    ('parts', 'parts'),
    ('whole', 'whole'),
)

class Product(CustomModel, models.Model):
    product_id = models.CharField(max_length=250, primary_key=True, blank=True, help_text='Derived from product name by default.')
    manufacturer = models.ForeignKey('Company')
    category = models.ForeignKey('Category')
    superseded_by_product = models.ForeignKey('self', blank=True, null=True)
    product_name = models.CharField(max_length=250)
    brand = models.CharField(max_length=250, blank=True, null=True)
    mfg_product_id = models.CharField(max_length=250, blank=True, null=True)
    mfg_categories = models.CharField(max_length=1024, blank=True, null=True, help_text='Enter each value on the separate line')
    mfg_product_kicker = models.CharField(max_length=1024, blank=True, null=True)
    mfg_flags = models.CharField(max_length=250, blank=True, null=True)
    mfg_short_text = models.CharField(max_length=1024, blank=True, null=True)
    mfg_long_text = models.CharField(max_length=1024, blank=True, null=True)
    discontinued_date = models.CharField(max_length=250, blank=True, null=True)
    is_accessory = models.CharField(max_length=250, choices=is_accessory_options, default='false')
    systemness = models.CharField(max_length=250, choices=systemness_options, default='not')
    system_parts = models.CharField(max_length=1024, blank=True, null=True, help_text='Enter each value on the separate line')
    related_products = models.CharField(max_length=1024, blank=True, null=True, help_text='Enter each value on the separate line')
    public_visible = models.BooleanField()
    suppress_reason_code = models.CharField(max_length=250, blank=True, null=True, default='afterqa')
    buildsite_public_notes = models.CharField(max_length=11000, blank=True, null=True)
    buildsite_private_notes = models.CharField(max_length=11000, blank=True, null=True)
    check_flags = models.CharField(max_length=250, blank=True, null=True)
    product_name_search_tsvector = models.TextField(blank=True, null=True) # This field type is a guess.
    product_name_search_keywords = models.TextField(blank=True, null=True)
    product_name_ext_search_tsvector = models.TextField(blank=True, null=True) # This field type is a guess.
    is_green = models.BooleanField()
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product'
        ordering = ['brand', 'product_name']
    def __unicode__(self):
        return self.product_id
        a = ['[', self.product_id, ']']
        return ''.join(a)

class ProductAttributeValue(models.Model):
    product_attribute_value_id = models.AutoField(primary_key=True)
    product = models.ForeignKey('Product')
    attribute = models.ForeignKey('Attribute')
    val = models.CharField(max_length=1000)
    max_val = models.CharField(max_length=1000, blank=True, null=True)
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

class ProductLeedCredit(models.Model):
    product_leed_credit_id = models.AutoField(primary_key=True)
    product = models.ForeignKey('Product')
    leed_credit = models.ForeignKey('LeedCredit')
    class Meta:
        db_table = u'product_leed_credit'

class ProductRelated(CustomModel, models.Model):
    product_related_id = models.AutoField(primary_key=True)
    product = models.ForeignKey('Product', related_name='rel_product')
    related_product = models.ForeignKey('Product', related_name='related_products_set')
    related_product_name = models.CharField(max_length=250)
    related_type = models.CharField(max_length=250)
    display_order = models.IntegerField()
    section_title = models.CharField(max_length=250)
    section_document = models.ForeignKey('Document')
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product_related'


class ProductStandard(CustomModel, models.Model):
    product_standard_id = models.AutoField(primary_key=True)
    product = models.ForeignKey('Product')
    standard = models.ForeignKey('Standard')
    standard_org_id = models.CharField(max_length=250, blank=True, null=True)
    standard_document_identifier = models.CharField(max_length=250, help_text='For example: "C309" for ASTM. Enter "Approved" for UL, FM, etc...',
                                                    blank=True, null=True)
    standard_parameters = models.CharField(max_length=1024, blank=True, null=True, help_text='For example: "Type I or Class B"')
    astm_search_tsvector = models.TextField(blank=True, null=True) # This field type is a guess.
    astm_search_keywords = models.TextField(blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'product_standard'

    def __unicode__(self):
        return '%s %s (%s)' % (self.standard.standard_org_id.upper(), self.standard.standard_document_identifier,
                                self.standard_parameters)

publication_type_options = (
    ('product', 'product'),
)

class Publication(CustomModel, models.Model):
    publication_id = models.CharField(max_length=250, primary_key=True)
    company = models.ForeignKey('Company')
    buildsite_publication_title = models.CharField(max_length=250, blank=True, null=True)
    publisher_publication_title = models.CharField(max_length=250, blank=True, null=True)
    publisher_publication_id = models.CharField(max_length=250, blank=True, null=True)
    publication_type = models.CharField(max_length=250, choices=publication_type_options)
    web_url = models.CharField(max_length=250, blank=True, null=True)
    web_completeness = models.CharField(max_length=250, blank=True, null=True)
    web_file_format = models.CharField(max_length=250, blank=True, null=True)
    standard_electronic_offered = models.CharField(max_length=250, blank=True, null=True)
    electronic_completeness = models.CharField(max_length=250, blank=True, null=True)
    electronic_file_format = models.CharField(max_length=250, blank=True, null=True)
    auto_ctime = models.DateTimeField(blank=True, null=True)
    auto_mtime = models.DateTimeField(blank=True, null=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'publication'
        ordering = ['publication_id']
    def __unicode__(self):
        return self.publication_id

class Schemaversions(models.Model):
    version = models.IntegerField()
    type = models.CharField(max_length=8)
    installed = models.CharField(max_length=20)
    class Meta:
        db_table = u'schemaversions'

class Service(models.Model):
    service_nickname = models.CharField(max_length=250, primary_key=True)
    service_title = models.CharField(unique=True, max_length=250)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    recur_interval = models.CharField(max_length=250)
    service_discontinue_date = models.DateField()
    class Meta:
        db_table = u'service'

class Setting(CustomModel, models.Model):
    setting_id = models.CharField(max_length=250, primary_key=True)
    scope = models.CharField(max_length=250)
    scope_value = models.CharField(max_length=250)
    att_name = models.CharField(max_length=250)
    att_val = models.CharField(max_length=10000)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'setting'
    def __unicode__(self):
        return self.setting_id

Standard_org_ids = [
    ('aama', 'AAMA'),
    ('aashto', 'AASHTO'),
    ('aci', 'ACI'),
    ('ansi', 'ANSI'),
    ('apa', 'APA'),
    ('astm', 'ASTM'),
    ('boca', 'BOCA'),
    ('coe', 'COE'),
    ('crrc', 'CRRC'),
    ('csa', 'CSA'),
    ('energystar', 'ENERGYSTAR'),
    ('epa', 'EPA'),
    ('faa', 'FAA'),
    ('fedspec', 'FEDSPEC'),
    ('fm', 'FM'),
    ('gsa', 'GSA'),
    ('hud', 'HUD'),
    ('icbo', 'ICBO'),
    ('icc', 'ICC'),
    ('navdocks', 'NAVDOCKS'),
    ('nchrp', 'NCHRP'),
    ('nfpa', 'NFPA'),
    ('nsf', 'NSF'),
    ('osha', 'OSHA'),
    ('otc', 'OTC'),
    ('sbcci', 'SBCCI'),
    ('ul', 'UL'),
    ('usda', 'USDA'),
    ('wh', 'WH'),
]

class Standard(CustomModel, models.Model):
    standard_id = models.IntegerField(primary_key=True)
    standard_org_id = models.CharField(max_length=250, choices=Standard_org_ids)
    standard_document_identifier = models.CharField(max_length=250)
    other_identifiers = models.CharField(max_length=1024)
    category = models.ForeignKey('Category')
    official_title = models.CharField(max_length=250)
    official_description = models.CharField(max_length=30000)
    buildsite_private_notes = models.CharField(max_length=30000)
    parameter_info = models.CharField(max_length=1024)
    auto_ctime = models.DateTimeField(blank=True)
    auto_mtime = models.DateTimeField(blank=True)
    admin_mtime = models.DateTimeField()
    class Meta:
        db_table = u'standard'
        ordering = ['standard_org_id', 'standard_document_identifier']
    def __unicode__(self):
        return '%s %s' % (self.standard_org_id.upper(), self.standard_document_identifier)

class SystemInfo(models.Model):
    att_name = models.CharField(unique=True, max_length=250)
    att_val = models.CharField(max_length=10000)
    class Meta:
        db_table = u'system_info'

class CompanyDocumentManager(models.Manager):
    def get_query_set(self):
        return super(CompanyDocumentManager, self).get_query_set().filter(document_type='company')

class ProductDocumentManager(models.Manager):
    def get_query_set(self):
        return super(ProductDocumentManager, self).get_query_set().filter(document_type='product')

class CategoryDocumentManager(models.Manager):
    def get_query_set(self):
        return super(CategoryDocumentManager, self).get_query_set().filter(document_type='category')

class CompanyDocument(CustomModel, Document):
    objects = CompanyDocumentManager()
    class Meta:
        proxy = True

class ProductDocument(CustomModel, Document):
    objects = ProductDocumentManager()
    class Meta:
        proxy = True

class CategoryDocument(CustomModel, Document):
    objects = CategoryDocumentManager()
    class Meta:
        proxy = True

