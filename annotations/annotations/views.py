from subprocess import Popen, PIPE

from django.http import HttpResponseRedirect
from django.http import HttpResponse, HttpResponseRedirect
from django.core.urlresolvers import reverse
from django.shortcuts import render_to_response, get_object_or_404

from models import *

def annotate_file(request, file_id, package_id=None):
    file = get_object_or_404(File, pk=file_id)
    pages = []
    for x in xrange(1, file.num_pages+1):
        try:
            a = FileMarkup.objects.get(file=file_id, package=package_id, page=x).is_active
        except FileMarkup.DoesNotExist:
            a = True
        pages.append((x, a))
       
    return render_to_response('file_annotate.html',
        {'file': file, 'pages': pages})

def download_file(request, file_id, package_id=None):
    file = get_object_or_404(File, pk=file_id)
    Popen(('bin/pdf_resurrector.sh', file_id),
        stdout=PIPE, stderr=PIPE).wait()
    return HttpResponse('/pdf_annotated/%s.pdf' % (file_id, ), mimetype="text/plain")


def file_annotations(request, file_id, page, package_id=None):
    if not request.is_ajax():
        return HttpResponseRedirect('/')

    if request.method == 'GET':
        try:
            return HttpResponse(
                FileMarkup.objects.get(file=file_id, package=package_id, page=page).json_markup,
                mimetype='application/json')
        except FileMarkup.DoesNotExist:
            return HttpResponse('[]', mimetype='application/json')
    else:
        file = get_object_or_404(File, pk=file_id)
        try:
            fm = FileMarkup.objects.get(file=file, package=package_id, page=page)
        except FileMarkup.DoesNotExist:
            fm = FileMarkup.objects.create(file=file, package=package_id, page=page, is_active=1)
        if 'is_active' in request.POST:
            fm.is_active = request.POST['is_active'] == 'true'
        if 'json_markup' in request.POST:
            fm.svg_markup = request.POST['svg_markup']
            fm.json_markup = request.POST['json_markup']
        fm.save()
        return HttpResponse('')

