# Bootstrapping the Archivematica database

If you've created a brand new Archivematica stack, the RDS instances won't have the right database tables (and the Archivematica apps won't create them).

To fix this:

1.  SSH into one of the EC2 container hosts.

2.  Start a Docker container and install MySQL:

    ```console
    $ docker run -it alpine sh
    # apk add --update mariadb-client
    ```

3.  Open a MySQL connection to the RDS instance, using the outputs from the critical stack:

    ```
    mysql \
      --host=$HOSTNAME \
      --user=archivematica \
      --password=$PASSWORD
    ```

    Run the following MySQL command:

    ```mysql
    CREATE DATABASE SS;
    CREATE DATABASE MCP;
    ```

4.  Exec into a running dashboard container, and run:

    ```
    python /src/dashboard/src/manage.py migrate

    python /src/dashboard/src/manage.py install \
        --username="admin" \
        --password="PASSWORD" \
        --email="wellcomedigitalworkflow@wellcome.ac.uk" \
        --org-name="wellcome" \
        --org-id="wellcome" \
        --api-key="API_KEY" \
        --ss-url="https://archivematica-storage-service-stage.wellcomecollection.org" \
        --ss-user="admin" \
        --ss-api-key="SS_API_KEY" \
        --site-url="https://archivematica-stage.wellcomecollection.org"
    ```

5.  Exec into a running storage-service container, and run:

    ```
    python /src/storage_service/manage.py migrate

    python /src/storage_service/manage.py \
        create_user \
        --username="admin" \
        --password="PASSWORD" \
        --email="wellcomedigitalworkflow@wellcome.ac.uk" \
        --api-key="SS_API_KEY" \
        --superuser
    ```
