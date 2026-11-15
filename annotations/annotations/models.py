from django.db import models

class File(models.Model):
    file_id = models.CharField(max_length=250, primary_key=True)
    num_pages = models.PositiveIntegerField()

class FileMarkup(models.Model):
    id = models.AutoField(primary_key=True)
    file = models.ForeignKey('File', null=True)
    document_id = models.CharField(max_length=250, null=True) # not used
    package = models.CharField(max_length=250, null=True)
    page = models.PositiveIntegerField()
    is_active = models.BooleanField()
    json_markup = models.CharField(max_length=5000, null=True)
    svg_markup = models.CharField(max_length=5000, null=True)
