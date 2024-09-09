FROM webdevops/php-nginx:8.1

COPY conf/ /opt/docker/
ADD https://1crm-system.de/downloads/1CRM_DE_8.7.7-318_main.zip /download.zip

RUN set -x \
    # Enable php development services
    && docker-service enable syslog \
#    && docker-service enable postfix \
#    && docker-service enable ssh \
    && docker-run-bootstrap \
    && docker-image-cleanup
