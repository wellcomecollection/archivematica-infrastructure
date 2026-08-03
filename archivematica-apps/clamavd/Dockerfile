FROM clamav/clamav:1.5.3-debian

RUN sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/clamd.conf && \
    sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/freshclam.conf
