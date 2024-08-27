ARG BASE_IMAGE=savantly/wordpress
ARG BASE_TAG=6.6.1-apache
FROM ${BASE_IMAGE}:${BASE_TAG}

WORKDIR /usr/src/wordpress
RUN set -eux; \
    find /etc/apache2 -name '*.conf' -type f -exec sed -ri -e "s!/var/www/html!$PWD!g" -e "s!Directory /var/www/!Directory $PWD!g" '{}' +; \
    cp -s wp-config-docker.php wp-config.php


COPY plugins/ ./wp-content/plugins/
COPY themes/ ./wp-content/themes/