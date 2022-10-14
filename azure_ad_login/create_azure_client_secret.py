#!/usr/bin/env python
"""
Create a new Azure AD client secret for Archivematica.

The secret is added to Azure AD and Secrets Manager, and the relevant ECS tasks
are restarted so they pick up a new copy of the secrets.
"""

import datetime as dt
import functools
import json
import secrets
import subprocess
import sys
import time

import boto3
from botocore.exceptions import ClientError


WORKFLOW_DEV_ROLE_ARN = "arn:aws:iam::299497370133:role/workflow-developer"


def az(*args):
    return subprocess.check_output(["az"] + list(args)).decode("utf8")


def login():
    """
    Logs in the current user using the Azure CLI.
    """
    az("login")


def get_az_ad_app(display_name):
    """
    Finds the Azure AD application with the given display name.
    """
    cli_output = az("ad", "app", "list", "--display-name", display_name)
    resp = json.loads(cli_output)

    if len(resp) != 1:
        print(cli_output, file=sys.stderr)
        raise RuntimeError(f"Could not find unique application named {display_name}!")

    return resp[0]


def create_password():
    """
    Returns a cryptographically secure new password.
    """
    return secrets.token_hex(32)


def store_az_client_secret(*, app_id, env, password):
    """
    Stores a new client secret with an Azure application.
    """
    az(
        "ad",
        "app",
        "credential",
        "reset",
        # --append = append a new credential rather than overwriting the
        # existing credentials.
        "--append",
        # application ID
        "--id",
        app_id,
        # Expires one year after it's created
        "--end-date",
        (dt.date.today() + dt.timedelta(days=365)).isoformat(),
        # Unfortunately, this description can only be a handful of characters
        # long, and the error message is quite confusing.
        # See https://github.com/Azure/azure-cli/issues/10720
        "--credential-description",
        f"weco/{env}",
        # The password
        "--password",
        password,
    )


@functools.lru_cache()
def get_aws_client(resource, *, role_arn):
    sts_client = boto3.client("sts")
    assumed_role_object = sts_client.assume_role(
        RoleArn=role_arn, RoleSessionName="AssumeRoleSession1"
    )
    credentials = assumed_role_object["Credentials"]
    return boto3.client(
        resource,
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


def store_secrets_manager_secret(*, secret_id, secret_value, role_arn):
    """
    Stores a new client secret in Secrets Manager.
    """
    secrets_client = get_aws_client("secretsmanager", role_arn=role_arn)

    try:
        resp = secrets_client.create_secret(Name=secret_id, SecretString=secret_value)
    except ClientError as err:
        if err.response["Error"]["Code"] == "ResourceExistsException":
            resp = secrets_client.put_secret_value(
                SecretId=secret_id, SecretString=secret_value
            )

            if resp["ResponseMetadata"]["HTTPStatusCode"] != 200:
                raise RuntimeError(f"Unexpected error from PutSecretValue: {resp}")
        else:
            raise
    else:
        if resp["ResponseMetadata"]["HTTPStatusCode"] != 200:
            raise RuntimeError(f"Unexpected error from CreateSecret: {resp}")


def force_ecs_task_redeployment(*, cluster_name, service_name):
    """
    Force an ECS task to restart, so it picks up a fresh copy of secrets in
    Secrets Manager.
    """
    ecs_client = get_aws_client("ecs", role_arn=WORKFLOW_DEV_ROLE_ARN)

    resp = ecs_client.update_service(
        cluster=cluster_name, service=service_name, forceNewDeployment=True
    )


if __name__ == "__main__":
    if "--skip-login" not in sys.argv:
        login()

    app = get_az_ad_app("Wellcome Collection Archivematica")
    app_id = app["appId"]

    for env in ("staging", "prod"):
        new_password = create_password()
        print(f"[{env}] Generated new client secret")

        store_az_client_secret(app_id=app_id, env=env, password=new_password)
        print(f"[{env}] Stored new client secret in Azure")

        secret_id = f"archivematica/{env}/oidc_rp_client_secret"
        store_secrets_manager_secret(
            secret_id=secret_id,
            secret_value=new_password,
            role_arn=WORKFLOW_DEV_ROLE_ARN,
        )
        print(f"[{env}] Stored client secret in Secrets Manager as {secret_id}")

        cluster_name = f"archivematica-{env}"

        for service in ("dashboard", "storage-service"):
            force_ecs_task_redeployment(
                cluster_name=cluster_name, service_name=f"am-{env}-{service}"
            )
            print(f"[{env}] Restarting ECS service am-{env}-{service}")
