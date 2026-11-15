# http://morethansevennet/2009/02/11/django-settings-tip-setting-relative-paths/
import os
import django
DJANGO_ROOT = os.path.dirname(os.path.realpath(django.__file__))
SITE_ROOT = os.path.dirname(os.path.realpath(__file__))
HOST = os.uname()[1]

DEBUG = 'crunch' in HOST
TEMPLATE_DEBUG = DEBUG


ADMINS = (
    ('Eugene Mirotin', 'emirotin@gmail.com'),
)

MANAGERS = ADMINS

if 'crunch' in HOST:
    DATABASE_ENGINE = 'postgresql_psycopg2'           # 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
    DATABASE_NAME = 'bsdata_v3'             # Or path to database file if using sqlite3.
    DATABASE_USER = 'bsadmin'             # Not used with sqlite3.
    DATABASE_PASSWORD = os.environ.get('DATABASE_PASSWORD', '')
    DATABASE_HOST = ''             # Set to empty string for localhost. Not used with sqlite3.
    DATABASE_PORT = ''             # Set to empty string for default. Not used with sqlite3.
elif 'ubuntu' in HOST: # alex's local system
    DATABASE_ENGINE = 'postgresql_psycopg2'           # 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
    DATABASE_NAME = 'bsdata'             # Or path to database file if using sqlite3.
    DATABASE_USER = 'bsadmin'             # Not used with sqlite3.
    DATABASE_PASSWORD = os.environ.get('DATABASE_PASSWORD', '')
    DATABASE_HOST = ''             # Set to empty string for localhost. Not used with sqlite3.
    DATABASE_PORT = ''             # Set to empty string for default. Not used with sqlite3.
else:
    DATABASE_ENGINE = 'postgresql_psycopg2'           # 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
    DATABASE_NAME = 'bsdata_v3'             # Or path to database file if using sqlite3.
    DATABASE_USER = 'bsadmin'             # Not used with sqlite3.
    DATABASE_PASSWORD = os.environ.get('DATABASE_PASSWORD', '')
    DATABASE_HOST = 'pg.buildsite.com'             # Set to empty string for localhost. Not used with sqlite3.
    DATABASE_PORT = ''             # Set to empty string for default. Not used with sqlite3.



# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# If running in a Windows environment this must be set to the same as your
# system time zone.

#TIME_ZONE = 'America/Chicago'
TIME_ZONE = 'America/Los_Angeles'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

SITE_ID = 1

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = False

# Absolute path to the directory that holds media.
# Example: "/home/media/media.lawrence.com/"
#MEDIA_ROOT = '/var/www/django-media'
MEDIA_ROOT = '/usr/lib/python2.5/site-packages/Django-1.1.1-py2.5.egg/django/contrib/admin/media'


# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash if there is a path component (optional in other cases).
# Examples: "http://media.lawrence.com", "http://example.com/media/"
MEDIA_URL = 'http://%s/django-media/' % HOST

# URL prefix for admin media -- CSS, JavaScript and images. Make sure to use a
# trailing slash.
# Examples: "http://foo.com/media/", "/media/".
ADMIN_MEDIA_PREFIX = 'http://%s/django-admin-media/' % HOST

# Make this unique, and don't share it with anybody.
# Loaded from the environment; never hardcode it in the repository.
SECRET_KEY = os.environ.get('SECRET_KEY')
assert SECRET_KEY, 'SECRET_KEY must be set in the environment'

# Logging
INTERNAL_IPS = ('127.0.0.1',)
LOGGING_OUTPUT_ENABLED = False
LOGGING_LOG_SQL = True


# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.load_template_source',
    'django.template.loaders.app_directories.load_template_source',
#     'django.template.loaders.eggs.load_template_source',
)

MIDDLEWARE_CLASSES = (
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'djangologging.middleware.LoggingMiddleware',
)

ROOT_URLCONF = 'bs.urls'

TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    SITE_ROOT + '/dbadm/templates',
)

AUTHENTICATION_BACKENDS = (
    'dbadm.backends.BSBackend',
    #'django.contrib.auth.backends.ModelBackend',
)

INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.admindocs',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'dbadm'
)
