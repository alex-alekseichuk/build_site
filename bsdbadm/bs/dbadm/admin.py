import re
from django.contrib import admin
from django.contrib.admin.util import unquote

from django import forms
from django.forms.models import modelform_factory, inlineformset_factory, BaseInlineFormSet
from django.forms.formsets import formset_factory
from models import *

from autocomplete_admin import FkAutocompleteAdmin, InlineAutocompleteAdmin
from widgets import *
from django.utils.functional import curry

class RememberLastValueAdmin(object):
    def render_change_form(self, request, context, add=False, change=False, form_url='', obj=None):
       if self.remembered_fields:
           context['remembered_fields'] = self.remembered_fields
           context['model_name'] = self.opts.object_name.lower()
       return super(RememberLastValueAdmin, self).render_change_form(request, context, add, change, form_url, obj)

class ChangeListForm(forms.ModelForm): # validation for changelists
    def clean_check_flags(self):
        data = self.cleaned_data.get("check_flags")
        allowed = select_options['check_flags']

        if data:
            for val in data.split(';'):
                if not val in allowed:
                    raise forms.ValidationError("Invalid value: %s" % val)
        return data

class ChangeListMixin(object):
    def get_changelist_form(self, request, **kwargs):
        defaults = {
           "form": ChangeListForm,
           "formfield_callback": curry(self.formfield_for_dbfield, request=request),
        }
        defaults.update(kwargs)
        return modelform_factory(self.model, **defaults)

class PublicationInline(WidgetsOverwriteMixin, admin.StackedInline):
    model = Publication
    extra = 1
    exclude = (
        'electronic_completeness',
        'electronic_file_format',
        #'publication_id', # CharField
        'standard_electronic_offered',
        'web_completeness',
        'web_file_format',
        'web_url',
    )
    overwritten_fields = {('auto_ctime', 'auto_mtime'): DateTimeLabel}

class CompanyGroupingInline(admin.TabularInline):
    model = CompanyGrouping
    extra = 3
    fields = ['grouping']

class CompanyFeatureInline(admin.TabularInline):
    model = CompanyFeature
    extra = 1
    fields = ['feature_name', 'feature_level', 'feature_status', 'feature_params']

class CompanyAdminForm(forms.ModelForm):
    class Meta:
        model = Company

    def clean(self):
        cleaned_data = super(CompanyAdminForm, self).clean()
        if cleaned_data['last_qa_complete_date'] and cleaned_data['suppress_reason_code'] == 'noqadate':
            cleaned_data['suppress_reason_code'] = ""
        return cleaned_data

class CompanyAdmin(CustomLinksMixin, WidgetsOverwriteMixin, FkAutocompleteAdmin):
    form = CompanyAdminForm
    list_per_page = 50
    fields = [
       'company_type',
       'company_nickname',
       'legal_name',
       'company_id',
       'publisher_status',
       'permission_granted',
       'check_flags',
       'location_phone',
       'location_fax',
       'addr_street',
       'addr_city',
       'addr_region',
       'addr_postal_code',
       'addr_country',
       'company_url',
       'company_logo_file',
       'went_live_date',
       'web_update_interval',
       'last_qa_complete_date',
       'last_update_date',
       'last_media_received_date',
       'next_media_update_date',
       'suppress_reason_code',
       'auto_ctime',
       'auto_mtime',
    ]
    list_display  = [
        'company_id',
        'legal_name',
        'publisher_status',
        'went_live_date',
        'last_qa_complete_date',
        'last_update_date',
        'permission_granted',
        'auto_ctime',
        'auto_mtime',
    ]
    list_editable = [
        'legal_name',
        'publisher_status',
        'went_live_date',
        'last_qa_complete_date',
        'last_update_date',
        'permission_granted',
    ]
    list_filter   = ['company_type']
    search_fields = ['legal_name', 'company_nickname', 'company_type']

    overwritten_fields = {
        ('company_summary_text', 'buildsite_public_notes', 'buildsite_private_notes'): forms.Textarea,
        ('auto_ctime', 'auto_mtime'): DateTimeLabel,
        ('suppress_reason_code',): Label,
        ('check_flags',): MultiSelect,
        (
            'last_media_received_date',
            'last_publish_date',
            'last_qa_complete_date',
            'last_update_date',
            'next_media_update_date',
            'next_paper_update_date',
            'next_web_update_date',
            'went_live_date',): admin.widgets.AdminDateWidget,
    }
    related_search_fields = {'branch_of': ['legal_name', 'company_nickname'],
        'division_of': ['legal_name', 'company_nickname']}
    inlines = [PublicationInline, CompanyGroupingInline, CompanyFeatureInline]

    custom_links = [('Related products', '../../product/?manufacturer={{ object_id }}'),
                    ('Related documents', '../../companydocument/?publication__company={{ object_id }}'),
                    ('Related products\' documents', '../../productdocument/?product__manufacturer={{ object_id }}')]
    class Media:
        js = ('js/jquery.js', "js/fill_publication_id.js",)


class AttributeCategoryInline(InlineAutocompleteAdmin):
    model = CategoryAttribute
    extra = 3
    fields = ['category']
    related_search_fields = {'category': ('category_id', )}

class AttributeAdmin(WidgetsOverwriteMixin, FkAutocompleteAdmin):
    list_per_page = 50
    #fields = ['attribute_name', 'data_type_id', 'value_units', 'attribute_type',
    #    'attribute_description', 'comments'
    #]
    list_display = ['__unicode__']
    search_fields = ['attribute_name', 'comments']
    inlines = [AttributeCategoryInline]
    overwritten_fields = {('attribute_description', 'comments'): forms.Textarea}

class GroupingAdmin(WidgetsOverwriteMixin, admin.ModelAdmin):
    list_per_page = 50
    model = Grouping
    fields = ['grouping_name', 'grouping_type', 'parent',
        'buildsite_private_notes']

    overwritten_fields = { ('buildsite_private_notes',): forms.Textarea }

class CategoryGroupingInline(admin.TabularInline):
    model = CategoryGrouping
    extra = 3
    fields=['grouping']

class CategoryAdmin(CustomLinksMixin, WidgetsOverwriteMixin, FkAutocompleteAdmin):
    list_per_page = 50
    custom_links = [
        ('Related products', '../../product/?category={{ object_id }}'),
    ]
    #fieldsets = [
    #    (None, {'fields': ['category_title', 'category_full_title',
    #        'parent', 'public_visible', 'suppress_reason_code']}),
    #    ('Notes', {'fields': ['buildsite_description', 'buildsite_public_notes',
    #        'buildsite_private_notes'], 'classes': ['collapse']})
    #]
    exclude = (
        'public_visible',
        'category_search_keywords',
    )

    inlines = [CategoryGroupingInline]
    list_display = [
        'category_id',
        'parent_link',
        'category_title',
        'category_full_title',
    ]
    list_editable = [
        'category_title',
        'category_full_title',
    ]

    parent_link = obj_link('parent')

    search_fields = ['category_id', 'category_title', 'category_full_title']
    overwritten_fields = {
        ('buildsite_description', 'buildsite_public_notes', 'buildsite_private_notes'): forms.Textarea,
        ('auto_ctime', 'auto_mtime'): DateTimeLabel,
        ('suppress_reason_code',
        #'mf_see_also_category_ids',
        #'mf_see_instead_category_ids',
        'mf_references_from', 'mf_includes', 'mf_usually_includes',
        'mf_may_include', 'mf_note'): Label,
        ('see_also_category_ids', 'see_instead_category_ids', 'mf_see_also_category_ids', 'mf_see_instead_category_ids'): SeparatedList,
        ('check_flags',): MultiSelect,
        ('category_full_title',): WideTextInput,
    }

    related_search_fields = {'parent': ('category_id', )}

class StandardAdmin(WidgetsOverwriteMixin, FkAutocompleteAdmin):
    list_per_page = 50
    model = Standard
    fields = ['standard_org_id', 'standard_document_identifier', 'official_title', 'category',
        'official_description', 'buildsite_private_notes']
    list_display = ['__unicode__']
    search_fields = ['category_title', 'category_full_title']

    overwritten_fields = {('official_description', 'buildsite_private_notes'): forms.Textarea }
    related_search_fields = { 'category': ('category_id',) }

class ProductAttributeValueInline(admin.TabularInline):
    model = ProductAttributeValue
    extra = 3
    fields = ('attribute', 'val', 'max_val')

class ProductLeedCreditInline(admin.TabularInline):
    model = ProductLeedCredit
    fields = ['leed_credit']

class ProductStandardInline(WidgetsOverwriteMixin, InlineAutocompleteAdmin):
    model = ProductStandard
    extra = 3
    fields = [
        'standard',
        #'standard_org_id',
        #'standard_document_identifier',
        'standard_parameters',
        'auto_ctime',
        'auto_mtime'
    ]
    overwritten_fields = {
        ('standard_parameters', ): SeparatedList,
        ('auto_ctime', 'auto_mtime'): DateTimeLabel
    }
    related_search_fields = {'standard': ('standard_org_id', 'standard_document_identifier')}

class ProductDocumentInline(OrderInlinesMixin, LinkedInline):
    model = ProductDocument
    fields = [
        'document_id',
        'doc_type',
    ]
    ordering = ('doc_type',)

class ProductAdmin(ChangeListMixin, CustomLinksMixin, WidgetsOverwriteMixin, RememberLastValueAdmin, FkAutocompleteAdmin):
    list_per_page = 50
    remembered_fields = ('manufacturer',)
    fieldsets = [
        (None, {'fields': [
            'manufacturer',
            'product_name',
            'product_id',
            'category',
            'mfg_product_kicker',
            'mfg_product_id',
            'check_flags',
            'brand',
            'mfg_categories',
            'superseded_by_product',
            'discontinued_date',
            'suppress_reason_code',
            'is_accessory',
            'systemness',
            'buildsite_private_notes',
            'buildsite_public_notes',
            'is_green',
            'auto_ctime',
            'auto_mtime',
        ]}),
        ('Mfg advertising fields', {'classes': ['collapse'], 'fields': [
            'mfg_flags',
            'mfg_short_text',
            'mfg_long_text',
        ]}),
    ]
    list_display = [
        'product_id',
        'suppress_reason_code',
        'check_flags',
        'manufacturer_link',
        #'category_link',
        'category',
        'product_name',
        'mfg_product_kicker',
        'mfg_product_id',
        'auto_ctime',
        'auto_mtime',
        'admin_mtime',
    ]
    ordering = ('-admin_mtime',)
    list_editable = [
#       'manufacturer',
        'product_name',
        'category',
        'mfg_product_kicker',
        'mfg_product_id',
        'check_flags',
    ]

    manufacturer_link = obj_link('manufacturer')
    category_link     = obj_link('category')

    search_fields = [
        'brand',
        'category__category_full_title',
        'category__category_title',
        'manufacturer__company_nickname',
        'manufacturer__legal_name',
        'product_id',
        'product_name',
    ]
    inlines = [
        ProductLeedCreditInline,
        ProductAttributeValueInline,
       # ProductRelatedInline,
        ProductStandardInline,
        ProductDocumentInline,
    ]
    related_search_fields = {
        'superseded_by_product': ('product_name', 'brand'),
        'manufacturer': ('legal_name', 'company_nickname'),
        'category': ('category_id',),
    }
    overwritten_fields = {
        ('buildsite_public_notes', 'buildsite_private_notes',): forms.Textarea,
        ('mfg_short_text', 'mfg_long_text'): TinyMCEEditor,
        ('mfg_product_kicker',): MultilineHtmlInput,
        ('auto_ctime', 'auto_mtime'): DateTimeLabel,
        ('suppress_reason_code',): Label,
        ('mfg_categories',): SeparatedList,
        ('check_flags', 'mfg_flags'): MultiSelect,
        ('system_parts', 'related_products'): MixedSeparatedList,
        ('product_id',): CreateOnlyInput,
        ('product_name',): HtmlInput,
    }
    #class Media:
    #    js = ['js/collapsed_tabular_inlines.js', 'js/collapsed_stacked_inlines.js']
    custom_links = [
        ('Related documents', '../../productdocument/?product={{ object_id }}'),
        ('Products superseded by', '../?superseded_by_product={{ object_id }}'),
    ]
    class Media:
        js = ('js/jquery.js', "js/fill_product_id.js",)
        css = {'all': ('css/products_list.css', )}

class LeedCreditAttributeInline(admin.TabularInline):
    model = LeedCreditAttribute
    extra = 3
    fields = ['attribute']

class LeedCreditAdmin(admin.ModelAdmin):
    list_per_page = 50
    model = LeedCredit
    #fields = ['leed_title', 'leed_section_name', 'leed_version', 'leed_area', 'standard_url']
    inlines = [LeedCreditAttributeInline]
    list_display = ['__unicode__']
    search_fields = ['leed_title', 'leed_area', 'leed_section_name']

class LeedAreaAdmin(admin.ModelAdmin):
    list_per_page = 50
    model = LeedArea
    #fields = ['leed_area_title']
    list_display = ['__unicode__']
    search_fields = ['leed_area_title']

class DocumentAdmin(ChangeListMixin, WidgetsOverwriteMixin, CustomLinksMixin, FkAutocompleteAdmin):
    list_per_page = 50
    list_display = [
        'document_id',
        'product_link',
        'category_link',
        'publication_link',
        'document_type',
        'check_flags',
        'doc_type',
        'publisher_document_title',
        'suppress_reason_code',
        'image_path',
        'replaced_by_document_link',
        'auto_ctime',
        'auto_mtime',
    ]
    list_editable = [
#        'document_type',
        'suppress_reason_code',
        'image_path',
        'check_flags',
        'doc_type',
        'publisher_document_title',
    ]

    publication_link          = obj_link('publication')
    replaced_by_document_link = obj_link('replaced_by_document')
    product_link              = obj_link('product')
    category_link             = obj_link('category')

    list_filter = ['document_type']

    fieldsets = [
        (None, {
            'fields': [
                'document_id',
                'publication',
                'document_type',
                'product',
                'category',
                'doc_type',
                'replaced_by_document',
                'image_path',
                'file_format_type',
                'publisher_document_title',
                'publisher_doc_date',
                'check_flags',
                'buildsite_private_notes',
                'buildsite_public_notes',
                'auto_ctime',
                'auto_mtime',
                'suppress_reason_code',
                'document_role', ]},
        ),
        ('Derived Info', {
            'fields': [
                'derived_path',
                'derived_format',
                'derived_how',
                'derived_params',
                'derived_pagecount',
                'derived_filesize',],
            'classes': ['collapse']}
        ),
    ]

    search_fields = ['document_id', '=product__product_id', 'publisher_document_title', 'document_type', 'product__product_name', ]
    related_search_fields = {
        'replaced_by_document': ('publisher_document_title', 'source_url'),
        'original_publisher': ('legal_name', 'company_nickname'),
        'about_company': ('legal_name', 'company_nickname'),
        'category': ('category_id',),
        'product': ('product_name', 'brand'),
        'publication': ('publication_id', 'publisher_publication_id'),
    }

    overwritten_fields = {
        ('buildsite_public_notes', 'buildsite_private_notes'): forms.Textarea,
        ('auto_ctime', 'auto_mtime'): DateTimeLabel,
        (
            'derived_filesize',
            'derived_format',
            'derived_how',
            'derived_pagecount',
            'derived_params',
            'derived_path',
            'source_checksum',
            'source_filesize',
            'source_mtime',
            'source_path',
            'source_url',
            'suppress_reason_code',
            'document_id',): Label,
        ('other_doc_types', 'check_flags'): MultiSelect,
        ('image_path',): WideTextInput,
    }

    custom_links = [
        ('Replaced documents', '../?replaced_by_document={{ object_id }}'),
        ('Documents with the same doc_type and product', '../?doc_type={{ self.doc_type }}&product={{ self.product.pk }}'),
    ]

class DocTypeInfoAdmin(WidgetsOverwriteMixin, admin.ModelAdmin):
    list_per_page = 50
    fields = ['dt_abbrev', 'dt_label', 'dt_help']
    overwritten_fields = {('dt_help', ): forms.Textarea }

#class AccountAdmin(admin.ModelAdmin):
#    fields = ['customer_id', 'account_type',
#        'allow_self_registration', 'block_access', 'block_reason',
#        'signed_final_date', 'signed_trial_date', 'expiration_date', 'sponsor_id'
#    ]
#
#class CustomerAccountAdmin(WidgetsOverwriteMixin, admin.ModelAdmin):
#    overwritten_fields = { ('auto_ctime', 'auto_mtime'): DateTimeLabel}
#    list_display = ['account_name', 'company_link', 'account_type', 'account_purpose']
#    company_link = obj_link('company')
#
#class CustomerUserAdmin(WidgetsOverwriteMixin, admin.ModelAdmin):
#    overwritten_fields = { ('auto_ctime', 'auto_mtime'): DateTimeLabel, ('last_login', ): Label }
#    list_display = ['login_id', 'customer_account_link', 'fullname', 'email', 'user_role']
#    customer_account_link = obj_link('customer_account')
#
class SettingAdmin(WidgetsOverwriteMixin, admin.ModelAdmin):
    list_per_page = 50
    overwritten_fields = {
        ('auto_ctime', 'auto_mtime'): DateTimeLabel,
        ('att_val',): forms.Textarea,
    }
    list_display = ['att_name', 'att_val']

class PublicationDocsetInline(LinkedInline):
    model = Docset

class PublicationAdmin(CustomLinksMixin, WidgetsOverwriteMixin, admin.ModelAdmin):
    list_per_page = 50
    fields = [
        'publisher_publication_id',
        'buildsite_publication_title',
        'publication_type',
        'auto_ctime',
        'auto_mtime',
    ]
    list_display = [
        'publication_id',
        'publisher_publication_id',
        'auto_ctime',
        'auto_mtime',
    ]
    search_fields = ['publication_id']
    list_editable = ['publisher_publication_id']

    overwritten_fields = {('auto_ctime', 'auto_mtime'): DateTimeLabel }
    custom_links = [
        ('Related product documents', '../../productdocument/?publication={{ object_id }}&document_type__exact=product'),
        ('Related category documents', '../../categorydocument/?publication={{ object_id }}&document_type__exact=category'),
        ('Related company documents', '../../companydocument/?publication={{ object_id }}&document_type__exact=company'),
#        ('Product documents', '../../productdocument/?product__manufacturer={{ object_id }}'),
    ]
    inlines = [PublicationDocsetInline]

class DocsetAdmin(WidgetsOverwriteMixin, FkAutocompleteAdmin):
    list_per_page = 50
    fields = [
        'docset_id',
        'publication',
        'docset_type',
        'docset_status',
        'media_type',
        'received_date',
        'auto_ctime',
        'auto_mtime',
    ]

    overwritten_fields = {
        ('docset_id', 'auto_ctime', 'auto_mtime'): Label, # CharFields
        ('received_date',): admin.widgets.AdminDateWidget,
    }
    related_search_fields = {
        'publication': ('publication_id', 'publisher_publication_id'),
    }
    list_display = [
        'docset_id',
        'publication_link',
        'docset_type',
        'docset_status',
        'media_type',
        'received_date',
        'auto_ctime',
    ]
    list_editable = [
        'docset_type',
        'docset_status',
        'media_type',
        'received_date',
    ]
    publication_link = obj_link('publication')

class MessageAdmin(admin.ModelAdmin):
    list_per_page = 50

class CompanyDocumentAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super(CompanyDocumentAdminForm, self).__init__(*args, **kwargs)
        self.fields['document_type'].initial = 'company'
        self.fields['document_type'].widget = Label()

class CompanyDocumentAdmin(DocumentAdmin):
    form = CompanyDocumentAdminForm
    list_filter = ()
    list_display = [
        'document_id',
        'publication_link',
        'document_type',
        'check_flags',
        'doc_type',
        'publisher_document_title',
        'suppress_reason_code',
        'image_path',
        'replaced_by_document_link',
        'auto_ctime',
        'auto_mtime',
    ]
    list_editable = [
        'document_type',
        'suppress_reason_code',
        'image_path',
        'check_flags',
        'doc_type',
        'publisher_document_title',
    ]
    publication_link          = obj_link('publication')
    replaced_by_document_link = obj_link('replaced_by_document')

    fieldsets = [
        (None, {
            'fields': [
                'document_id',
                'publication',
                'document_type',
                'doc_type',
                'replaced_by_document',
                'image_path',
                'file_format_type',
                'publisher_document_title',
                'publisher_doc_date',
                'check_flags',
                'buildsite_private_notes',
                'buildsite_public_notes',
                'auto_ctime',
                'auto_mtime',
                'suppress_reason_code',
                'document_role', ]},
        ),
        ('Derived Info', {
            'fields': [
                'derived_path',
                'derived_format',
                'derived_how',
                'derived_params',
                'derived_pagecount',
                'derived_filesize',],
            'classes': ['collapse']}
        ),
    ]

    search_fields = ['document_id', 'publisher_document_title', 'document_type' ]
    related_search_fields = {
        'replaced_by_document': ('publisher_document_title', 'source_url'),
        'original_publisher': ('legal_name', 'company_nickname'),
        'about_company': ('legal_name', 'company_nickname'),
        'publication': ('publication_id', 'publisher_publication_id'),
    }

class ProductDocumentAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super(ProductDocumentAdminForm, self).__init__(*args, **kwargs)
        self.fields['document_type'].initial = 'product'
        self.fields['document_type'].widget = Label()
        self.fields['product'].required = True

class ProductDocumentAdmin(RememberLastValueAdmin, DocumentAdmin):
    form = ProductDocumentAdminForm
    remembered_fields = ('publication',)
    list_filter = ()
    list_display = [
        'document_id',
        'product_link',
        'publication_link',
        'document_type',
        'check_flags',
        'doc_type',
        'publisher_document_title',
        'suppress_reason_code',
        'image_path',
        'replaced_by_document_link',
        'auto_ctime',
        'auto_mtime',
    ]
    list_editable = [
        'document_type',
        'suppress_reason_code',
        'image_path',
        'check_flags',
        'doc_type',
        'publisher_document_title',
    ]

    publication_link          = obj_link('publication')
    replaced_by_document_link = obj_link('replaced_by_document')
    product_link              = obj_link('product')

    fieldsets = [
        (None, {
            'fields': [
                'document_id',
                'publication',
                'document_type',
                'product',
                'doc_type',
                'replaced_by_document',
                'image_path',
                'file_format_type',
                'publisher_document_title',
                'publisher_doc_date',
                'check_flags',
                'buildsite_private_notes',
                'buildsite_public_notes',
                'auto_ctime',
                'auto_mtime',
                'suppress_reason_code',
                'document_role', ]},
        ),
        ('Derived Info', {
            'fields': [
                'derived_path',
                'derived_format',
                'derived_how',
                'derived_params',
                'derived_pagecount',
                'derived_filesize',],
            'classes': ['collapse']}
        ),
    ]

    search_fields = ['document_id', '=product__product_id', 'publisher_document_title', 'document_type', 'product__product_name', ]
    related_search_fields = {
        'replaced_by_document': ('publisher_document_title', 'source_url'),
        'original_publisher': ('legal_name', 'company_nickname'),
        'about_company': ('legal_name', 'company_nickname'),
        'product': ('product_name', 'brand'),
        'publication': ('publication_id', 'publisher_publication_id'),
    }
    class Media:
        js = ('js/autocomplete_extras.js',)

class CategoryDocumentAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super(CategoryDocumentAdminForm, self).__init__(*args, **kwargs)
        self.fields['document_type'].initial = 'category'
        self.fields['document_type'].widget = Label()
        self.fields['category'].required = True

class CategoryDocumentAdmin(DocumentAdmin):
    form = CategoryDocumentAdminForm
    list_filter = ()
    list_display = [
        'document_id',
        'category_link',
        'publication_link',
        'document_type',
        'check_flags',
        'doc_type',
        'publisher_document_title',
        'suppress_reason_code',
        'image_path',
        'replaced_by_document_link',
        'auto_ctime',
        'auto_mtime',
    ]
    list_editable = [
        'document_type',
        'suppress_reason_code',
        'image_path',
        'check_flags',
        'doc_type',
        'publisher_document_title',
    ]

    publication_link          = obj_link('publication')
    replaced_by_document_link = obj_link('replaced_by_document')
    category_link             = obj_link('category')

    fieldsets = [
        (None, {
            'fields': [
                'document_id',
                'publication',
                'document_type',
                'category',
                'doc_type',
                'replaced_by_document',
                'image_path',
                'file_format_type',
                'publisher_document_title',
                'publisher_doc_date',
                'check_flags',
                'buildsite_private_notes',
                'buildsite_public_notes',
                'auto_ctime',
                'auto_mtime',
                'suppress_reason_code',
                'document_role', ]},
        ),
        ('Derived Info', {
            'fields': [
                'derived_path',
                'derived_format',
                'derived_how',
                'derived_params',
                'derived_pagecount',
                'derived_filesize',],
            'classes': ['collapse']}
        ),
    ]

    search_fields = ['document_id', 'publisher_document_title', 'document_type' ]
    related_search_fields = {
        'replaced_by_document': ('publisher_document_title', 'source_url'),
        'original_publisher': ('legal_name', 'company_nickname'),
        'about_company': ('legal_name', 'company_nickname'),
        'category': ('category_id',),
        'publication': ('publication_id', 'publisher_publication_id'),
    }

admin.site.register(Attribute, AttributeAdmin)
admin.site.register(Category, CategoryAdmin)
admin.site.register(Company, CompanyAdmin)
admin.site.register(DocTypeInfo, DocTypeInfoAdmin)
admin.site.register(Docset, DocsetAdmin)
#admin.site.register(Document, DocumentAdmin)
admin.site.register(Grouping, GroupingAdmin)
admin.site.register(LeedArea, LeedAreaAdmin)
admin.site.register(LeedCredit, LeedCreditAdmin)
admin.site.register(Message, MessageAdmin)
admin.site.register(Product, ProductAdmin)
admin.site.register(Standard, StandardAdmin)
admin.site.register(Publication, PublicationAdmin)
admin.site.register(Setting, SettingAdmin)

admin.site.register(CompanyDocument, CompanyDocumentAdmin)
admin.site.register(ProductDocument, ProductDocumentAdmin)
admin.site.register(CategoryDocument, CategoryDocumentAdmin)
