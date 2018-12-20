FROM nginx:stable-alpine

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/archivematica.conf /etc/nginx/conf.d/archivematica.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 8000

COPY run.sh /
CMD ["/run.sh"]
