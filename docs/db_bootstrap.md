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

Something, something Django migrations