# FROM archivematica_storage_service


# This is where the nginx image starts.
FROM nginx:stable-alpine

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/archivematica.conf /etc/nginx/conf.d/archivematica.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Here we're copying the static assets from the storage service image
# directly into the nginx image.
#
# This lets us serve those assets directly with nginx, which is:
#  1) Better for performance
#  2) Lets us solve the path problems in nginx config, and not have to serve
#     them through Django
#
# COPY --from=0 /usr/share/archivematica/virtualenvs/archivematica-storage-service/lib/python2.7/site-packages/storage_service/static /usr/share/nginx/html/storage_service/static/

EXPOSE 80

COPY run.sh /
CMD ["/run.sh"]
