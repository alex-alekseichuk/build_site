import os
from django.conf.urls.defaults import *
from django.http import HttpResponseRedirect

import settings

from django.contrib import admin
admin.autodiscover()

PREFIX = 'dbadm/' if 'crunch' in os.uname()[1] else ''


urlpatterns = patterns('',
    (r'^%s$' % PREFIX, lambda r : HttpResponseRedirect('admin/')),

    # Uncomment the admin/doc line below and add 'django.contrib.admindocs' 
    # to INSTALLED_APPS to enable admin documentation:
    (r'^%sadmin/doc/' % PREFIX, include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    (r'^%sadmin/' % PREFIX, include(admin.site.urls)),
)

urlpatterns += patterns("django.views",
    url(r"dbadm/%s(?P<path>.*)$" % settings.MEDIA_URL[1:], "static.serve", {
        "document_root": settings.MEDIA_ROOT,
    })
)
urlpatterns += patterns('',
         (r'^django-media/(?P<path>.*)$', 'django.views.static.serve', {'document_root': '/var/www/django-media'}),
)
