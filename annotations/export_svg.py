import sys
import tempfile
import os
import settings

from django.core.management import setup_environ
setup_environ(settings)

from annotations.models import *

file_id = sys.argv[1]
file = File.objects.get(pk=file_id)
dir = tempfile.mkdtemp()
active = open(os.path.join(dir, 'active'), 'w')
for i in xrange(1, file.num_pages+1):
    try:
        fm = FileMarkup.objects.get(file=file, page=i)
        active.write(str(int(fm.is_active)))
        if fm.is_active:
            f = open(os.path.join(dir, '%s.svg' % i), 'w')
            f.write(fm.svg_markup.encode('utf-8'))
            f.close()
    except FileMarkup.DoesNotExist:
        active.write('1')
active.close()

print dir
