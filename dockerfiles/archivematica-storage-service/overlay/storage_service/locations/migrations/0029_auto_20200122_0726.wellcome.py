# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('locations', '0028_wellcome_blank_aws_auth'),
    ]

    operations = [
        migrations.RenameField(
            model_name='s3',
            old_name='access_key_id',
            new_name='aws_access_key_id',
        ),
        migrations.RenameField(
            model_name='s3',
            old_name='secret_access_key',
            new_name='aws_secret_access_key',
        ),
        migrations.RenameField(
            model_name='s3',
            old_name='bucket',
            new_name='s3_bucket',
        ),
        migrations.RenameField(
            model_name='s3',
            old_name='endpoint_url',
            new_name='s3_endpoint_url',
        ),
        migrations.RenameField(
            model_name='s3',
            old_name='region',
            new_name='s3_region',
        ),
        migrations.AddField(
            model_name='s3',
            name='aws_assumed_role',
            field=models.CharField(max_length=256, verbose_name='Assumed AWS IAM Role', blank=True),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='api_root_url',
            field=models.URLField(help_text='Root URL of the storage service API, e.g. https://api.wellcomecollection.org/storage/v1', max_length=256),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='aws_access_key_id',
            field=models.CharField(max_length=64, verbose_name='Access Key ID to authenticate', blank=True),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='aws_secret_access_key',
            field=models.CharField(max_length=256, verbose_name='Secret Access Key to authenticate with', blank=True),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='s3_bucket',
            field=models.CharField(help_text='S3 Bucket Name', max_length=64, verbose_name='S3 Bucket', blank=True),
        ),
        migrations.AlterField(
            model_name='wellcomestorageservice',
            name='s3_region',
            field=models.CharField(help_text='Region in S3. Eg. us-east-2', max_length=64, verbose_name='Region'),
        ),
    ]