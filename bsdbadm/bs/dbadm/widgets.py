import re
from django import forms
from django.forms.models import inlineformset_factory, BaseInlineFormSet
from django.forms.formsets import formset_factory

from django.contrib import admin
from django.utils.safestring import mark_safe
from django.core.urlresolvers import reverse, NoReverseMatch

from django.utils.encoding import force_unicode
from django.contrib.admin.util import quote, unquote
from itertools import chain
from django.utils.html import escape, conditional_escape
from htmlentitydefs import name2codepoint
from django.conf import settings


def obj_link(field):
    def f(self, obj):
        ro = getattr(obj, field)
        try:
            return '<a href="%s" target="_blank">%s</a>' % (
                reverse(
                    'admin:dbadm_%s_change' % ro.__class__.__name__.lower(),
                    args=(quote(ro.pk),)),
                unicode(ro))
        except NoReverseMatch:
           return '<span>%s</span>' % unicode(ro)
    f.short_description = re.sub('_+', ' ', field)
    f.allow_tags = True
    f.admin_order_field = field
    return f

class WidgetsOverwriteMixin(object):
    def formfield_for_dbfield(self, db_field, **kwargs):
        for k, v in self.overwritten_fields.items():
            if db_field.name in k:
                kwargs['widget'] = v
                break
        return super(WidgetsOverwriteMixin, self).formfield_for_dbfield(db_field,**kwargs)

class OrderInlinesFormset(BaseInlineFormSet):
    """A formset for child objects related to a parent."""
    def __init__(self, data=None, files=None, instance=None,
                 save_as_new=False, prefix=None):
        from django.db.models.fields.related import RelatedObject
        if instance is None:
            self.instance = self.model()
        else:
            self.instance = instance
        self.save_as_new = save_as_new
        # is there a better way to get the object descriptor?
        self.rel_name = RelatedObject(self.fk.rel.to, self.model, self.fk).get_accessor_name()
        if self.fk.rel.field_name == self.fk.rel.to._meta.pk.name:
            backlink_value = self.instance
        else:
            backlink_value = getattr(self.instance, self.fk.rel.field_name)
        qs = self.model._default_manager.filter(**{self.fk.name: backlink_value})
        qs = qs.order_by(*self.ordering)

        super(BaseInlineFormSet, self).__init__(data, files, prefix=prefix, queryset=qs)

class OrderInlinesMixin(object):
    def get_formset(self, request, obj=None, **kwargs):
        self.formset = OrderInlinesFormset
        FormSet = super(OrderInlinesMixin, self).get_formset(request, obj, **kwargs)
        FormSet.ordering = self.ordering
        return FormSet

class CustomLinksMixin(object):
    def change_view(self, request, object_id, extra_context=None):

        def interpolate(var):
            var = var.split('.')
            if var[0] == 'self':
                o = self.model.objects.get(pk = unquote(object_id))
            else:
                o = unquote(eval(var[0]))

            for v in var[1:]:
                o = getattr(o, v)
            return str(o)

        if extra_context:
            extra_context = extra_context.copy()
        else:
            extra_context = {}
        pattern = re.compile(r"({{\s*([^\s]+)\s*}})")
        cl = []

        for t, l in self.custom_links:
            try:
                while (True):
                    mo = pattern.search(l)
                    if mo is None:
                        break
                    l = l.replace(mo.group(1), interpolate(mo.group(2)))
                cl.append((t, l))
            except AttributeError:
                pass
        extra_context.update({
            'custom_links': cl,
        })
        return super(CustomLinksMixin, self).change_view(request, object_id, extra_context)

class LinkedInlineFormset(forms.models.BaseInlineFormSet):
    def __init__(self, *args, **kwargs):
        super(LinkedInlineFormset, self).__init__(*args, **kwargs)
        self.can_delete = False

class LinkedInline(WidgetsOverwriteMixin, admin.options.InlineModelAdmin):
    template = "admin/edit_inline/linked.html"
    admin_model_name = None
    extra = 0
#    formset = LinkedInlineFormset

    def __init__(self, *args):
        super(LinkedInline, self).__init__(*args)
        if self.admin_model_name is None:
            self.admin_model_name = self.model.__name__.lower()
        pk_name = self.model._meta.pk.attname
        if not hasattr(self, 'overwritten_fields'):
            self.overwritten_fields = {}
        self.overwritten_fields.update({(pk_name, ): forms.HiddenInput})
        self.fields = [pk_name]

    def get_formset(self, request, obj=None, **kwargs):
        FormSet = super(LinkedInline, self).get_formset(request, obj, **kwargs)
        FormSet.can_delete = False
        return FormSet

# Options for multi-select
select_options = {
    'check_flags': (
        "bad_html_image_file",
        "bad_pdf_image_file",
        "disc_doc",
        "disc_prod",
        "disc_waiting",
        "html_ok",
        "issue",
        "jobsite",
        "manydocs",
        "msds_not_needed",
        "msds_waiting",
        "multiple_product_ok",
        "no_title",
        "noelectronic",
        "nomsds",
        "nopd",
        "notpublic",
        "pdfknownbad",
        "pdfok",
        "suppress",
    ),
    'other_doc_types': (
        "color_chart",
        "comparison_chart",
        "detail_drawing",
        "engineering_data",
        "estimating_notes",
        "installation_instructions",
        "storage_and_handling",
        "submittal_sheet",
        "technical_notes",
        "test_report",
        "three_part_csi_spec",
        "unformatted_spec",
        "warranty",
    ),
    'mfg_flags': (
       ("A", "Caltrans Approved"),
       ("C", "CRI (Carpet and Rug Institute Green Label)"),
       ("D", "DOT Approvals"),
       ("E", "Energy Star"),
       ("F", "FM Approved"),
       ("G", "Green Seal"),
       ("I", "ICBO"),
       ("L", "NSF Certified/Listed"),
       ("M", "Miami-Dade County Approval"),
       ("N", "New"),
       ("Q", "GreenGuard Certified"),
       ("R", "Recycled"),
       ("S", "FSC (Forest Stewardship Council Rated)"),
       ("T", "Made in the USA"),
       ("U", "UL"),
       ("V", "Low VOC"),
       ("W", "ADA Compliant"),
       ("Y", "Regionally Manufactured"),
       ("Z", "Zero VOC"),
    ),
}

class MultiSelect(forms.CheckboxSelectMultiple):
    def render(self, name, value, attrs=None):
        if re.match('form\-\d+\-', name) is not None: # text input for list_display
            return forms.TextInput.render(forms.TextInput(), name, value, attrs)

        choices = []
        for opt in select_options[name]:
            if getattr(opt, '__iter__', False):
                choices.append(opt)
            else:
                choices.append((opt,opt));

        if value:
            value = value.split(';')
        else:
            value = []

        has_id = attrs and 'id' in attrs
        final_attrs = self.build_attrs(attrs, name=name)
        output = [
            u'<div style="width:350px;height:200px;overflow:auto;line-height:0;">' +
            u'<ul style="margin-left:0;padding-left:0;">'
        ]
        # Normalize to strings
        str_values = set([force_unicode(v) for v in value])
        for i, (option_value, option_label) in enumerate(chain(self.choices, choices)):
            # If an ID attribute was given, add a numeric index as a suffix,
            # so that the checkboxes don't all have the same ID attribute.
            if has_id:
                final_attrs = dict(final_attrs, id='%s_%s' % (attrs['id'], i))
                label_for = u' for="%s"' % final_attrs['id']
            else:
                label_for = ''

            cb = forms.widgets.CheckboxInput(final_attrs, check_test=lambda value: value in str_values)
            option_value = force_unicode(option_value)
            rendered_cb = cb.render(name, option_value)
            option_label = conditional_escape(force_unicode(option_label))
            output.append(
                u'<li style="white-space:nowrap;list-style-type:none;font-size:10px;line-height:10px;"><label style="float:none;"%s>%s %s</label></li>'
                    % (label_for, rendered_cb, option_label)
             )
        output.append(u'</ul></div>')
        return mark_safe(u'\n'.join(output))

    def value_from_datadict(self, data, files, name):
        value = data.getlist(name)
        if value is not None:
            if getattr(value, '__iter__', False):
                value = ';'.join(value)
        return value

class Label(forms.HiddenInput):
    def render(self, name, value, attrs=None):
        hi = super(Label, self).render(name, value, attrs)
        return mark_safe(u'%s<span>%s</span>' % (hi, value))#

    def _has_changed(self, initial, data):
        return False

class DateTimeLabel(forms.fields.SplitHiddenDateTimeWidget):
    def render(self, name, value, attrs=None):
        hi = super(DateTimeLabel, self).render(name, value, attrs)
        if value is not None:
            if getattr(value, '__iter__', False):
                value = ' '.join(value)
        else:
            value = '---'
        return mark_safe(u'%s<span>%s</span>' % (hi, value))

    def _has_changed(self, initial, data):
        return False

class SeparatedList(forms.Textarea):
    def render(self, name, value, attrs=None):
        if value:
            value = '\n'.join(re.split('\s*;\s*', value))
        return super(SeparatedList, self).render(name, value, attrs)

    def value_from_datadict(self, data, files, name):
        value = data.get(name, None)
        if value:
            value = ';'.join(re.split('[\r\n]+', value))
        return value

class MixedSeparatedList(forms.Textarea):
    def render(self, name, value, attrs=None):
        if value:
            if value.find('seedoc') != -1:
                pass
            elif value.find('mfg_product_ids:') == 0:
                value = '\n'.join(re.split('\s+', value))
            else:
                value = '\n'.join(re.split('\s*;\s*', value))
        return super(MixedSeparatedList, self).render(name, value, attrs)

    def value_from_datadict(self, data, files, name):
        value = data.get(name, None)
        if value:
            words = re.split('[\r\n]+', value)
            if len(words) > 1:
                if words[0] == 'mfg_product_ids:':
                    value = ' '.join(words)
                else:
                    value = ';'.join(words)
        return value

class WideTextInput(forms.TextInput):
    def __init__(self, attrs=None):
        if attrs is None:
             attrs = {}
        if 'style' not in attrs:
             attrs['style'] = 'width: 500px;'
        else:
            attrs['style'] += ' width: 500px;'
        super(WideTextInput, self).__init__(attrs)

def encode_entities(s):
    html_entities = {
        "&": "&amp;",
        '"': "&quot;",
        "'": "&#39;",
        ">": "&gt;",
        "<": "&lt;",
    }
    return "".join( html_entities.get(c,c) for c in s)

def decode_entities(s):
    def fixup(m):
        str = m.group(0)
        if str[:2] == "&#": # character reference
            try:
                if str[:3] == "&#x":
                    return unichr(int(str[3:-1], 16))
                else:
                    return unichr(int(str[2:-1]))
            except ValueError:
                pass
        else: # named entity
            try:
                str = unichr(name2codepoint[str[1:-1]])
            except KeyError:
                pass
        return str # leave as is
    return re.sub("&#?\w+;", fixup, s)

class HtmlEscapedWidget(object):
    def render(self, name, value, attrs=None):
        if value:
            value = decode_entities(value)
        return super(HtmlEscapedWidget, self).render(name, value, attrs)

    def value_from_datadict(self, data, files, name):
        value = data.get(name, None)
        if value:
            value = encode_entities(value)
        return value

class MultilineHtmlInput(HtmlEscapedWidget, forms.Textarea):
    def render(self, name, value, attrs=None):
        if re.match('form\-\d+\-', name) is not None: # smaller textareas for list_display
            return super(MultilineHtmlInput, self).render(name, value, attrs={'cols': '32', 'rows': '4'})
        return super(MultilineHtmlInput, self).render(name, value, attrs)

class HtmlInput(HtmlEscapedWidget, WideTextInput):
    pass

class CreateOnlyInput(forms.Widget):
    def render(self, name, value, attrs=None):
        if value:
            return mark_safe(u'%s<span>%s</span>' % (forms.HiddenInput.render(forms.HiddenInput(), name, value, attrs), value))
        else:
            return WideTextInput.render(WideTextInput(), name, value, attrs)


class TinyMCEEditor(forms.Textarea):
    class Media:
        js = (
            'js/jquery.js',
            'js/tiny_mce/jquery.tinymce.js',
        )

    def render(self, name, value, attrs=None):
        if re.match('form\-\d+\-', name) is not None: # ordinal textarea for list_display
            return forms.Textarea.render(forms.Textarea(), name, value, attrs)

        rendered = super(TinyMCEEditor, self).render(name, value, attrs)
        return rendered + mark_safe(u'''<script type="text/javascript">
    jQuery('#id_%s').tinymce({
        script_url : '%sjs/tiny_mce/tiny_mce.js',
        mode : "textareas",
        theme : "simple",
        width: 400,
    });
</script>''' % (name, settings.MEDIA_URL))

