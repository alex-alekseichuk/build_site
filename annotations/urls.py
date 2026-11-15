import os
from django.conf import settings
from django.conf.urls.defaults import *
from django.http import HttpResponseRedirect

PREFIX=''

urlpatterns = patterns('annotations.views',
    
    (r'^%s$' % PREFIX, lambda r:
        HttpResponseRedirect('crunch/file/file_123456/annotate/')),

    (r'^crunch/file/(?P<file_id>[0-9a-zA-Z_-]+)/annotate/$', 'annotate_file'),
    (r'^crunch/file/(?P<file_id>[0-9a-zA-Z_-]+)/download/$', 'download_file'),
    (r'^crunch/file/(?P<file_id>[0-9a-zA-Z_-]+)/annotations/(?P<page>[0-9]+)/$',
        'file_annotations'),
)

if settings.DEBUG:
    urlpatterns += patterns('',
        (r'^static/(?P<path>.*)$', 'django.views.static.serve',
            {'document_root': os.path.join(settings.PROJ_DIR, 'media')}),
        (r'^pdf_images/(?P<path>.*)$', 'django.views.static.serve',
            {'document_root': os.path.join(settings.PROJ_DIR, 'pdf_images')}),
        (r'^pdf_annotated/(?P<path>.*)$', 'django.views.static.serve',
            {'document_root': os.path.join(settings.PROJ_DIR, 'pdf_annotated')}),
    )
