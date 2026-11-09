FROM nginx:1.30.6-alpine

# Picks up Alpine security fixes published after the nginx image was built. Image tags
# are immutable and come from the last commit in this folder, so picking up new fixes
# needs a commit here.
RUN apk upgrade --no-cache

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/archivematica.conf /etc/nginx/conf.d/archivematica.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

COPY run.sh /
CMD ["/run.sh"]
