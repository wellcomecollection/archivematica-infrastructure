FROM clamav/clamav:1.5.4-debian@sha256:c21aa18cc0a358678255a3dfb343a4555b58f71b97d7b869df8fdf7ea0a5b4b1

RUN sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/clamd.conf && \
    sed -i 's/^#Foreground .*$/Foreground yes/g' /etc/clamav/freshclam.conf
