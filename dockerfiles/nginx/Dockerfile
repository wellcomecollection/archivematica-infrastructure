FROM archivematica_dashboard


# This is where the nginx image starts.
FROM nginx:stable-alpine

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/archivematica.conf /etc/nginx/conf.d/archivematica.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# What's this?  We're copying the static assets from the dashboard container
# directly into the nginx container.
#
# This lets us serve those assets directly with nginx, which is:
#  1) Better for performance
#  2) Lets us solve the path problems in nginx config, and not have to serve
#     them through Django
#
# The grep/sed's then update various paths
#
COPY --from=0 /usr/share/archivematica/dashboard/media /usr/share/nginx/html/dashboard/media/

# css: replace `url(/media/` with `url(/archivematica/dashboard/media`
RUN grep -rl /media/ /usr/share/nginx/html/dashboard/media/css | xargs sed -i 's/url(\/media\//url(\/archivematica\/dashboard\/media\//g'

# js: replace `/media/images` with `/archivematica/dashboard/media/images`
RUN grep -rl /media/ /usr/share/nginx/html/dashboard/media/js | xargs sed -i 's/\/media\/images/\/archivematica\/dashboard\/media\/images/g'

# js: replace `/ingest/status`, `/transfer/status`, `/status`, `/transfer/locations`
# with prefixed versions
RUN grep -rl /status /usr/share/nginx/html/dashboard/media/js | xargs sed -i 's/\/status/\/archivematica\/dashboard\/status/g'
RUN grep -rl /status /usr/share/nginx/html/dashboard/media/js | xargs sed -i 's/\/ingest\/status/\/archivematica\/dashboard\/ingest\/status/g'
RUN grep -rl /status /usr/share/nginx/html/dashboard/media/js | xargs sed -i 's/\/transfer\/status/\/archivematica\/dashboard\/transfer\/status/g'
RUN grep -rl /transfer/locations/ /usr/share/nginx/html/dashboard/media/js | xargs sed -i 's/\/transfer\/locations/\/archivematica\/dashboard\/transfer\/locations/g'

EXPOSE 8000

COPY run.sh /
CMD ["/run.sh"]
