FROM webdevops/php-nginx:7.4

COPY conf/ /opt/docker/

RUN set -x \
    # Enable php development services
    && docker-service enable syslog \
#    && docker-service enable postfix \
#    && docker-service enable ssh \
    && docker-run-bootstrap \
    && docker-image-cleanup
