# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('locations', '0026_wellcome'),
    ]

    operations = [
        migrations.AddField(
            model_name='wellcomestorageservice',
            name='callback_api_key',
            field=models.CharField(max_length=256, blank=True),
        ),
        migrations.AddField(
            model_name='wellcomestorageservice',
            name='callback_host',
            field=models.URLField(help_text='Publicly accessible URL of the Archivematica storage service accessible to Wellcome storage service for callback', max_length=256, blank=True),
        ),
        migrations.AddField(
            model_name='wellcomestorageservice',
            name='callback_username',
            field=models.CharField(max_length=150, blank=True),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='aws_access_key_id',
            field=models.CharField(max_length=64, verbose_name='AWS Access Key ID to authenticate'),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='aws_secret_access_key',
            field=models.CharField(max_length=256, verbose_name='AWS Secret Access Key to authenticate with'),
        ),
    ]
