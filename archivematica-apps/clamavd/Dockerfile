FROM clamav/clamav:1.2

RUN sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/clamd.conf && \
    sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/freshclam.conf
