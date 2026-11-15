from django import template
from django.template.defaultfilters import stringfilter
from django.contrib.admin.util import quote

register = template.Library()

@register.filter(name='cut')
@stringfilter
def cut(value, arg):
    return value.replace(arg, '')

@register.filter(name='quote_value')
@stringfilter
def quote_value(value):
    return quote(value)

