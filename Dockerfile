ARG BASE_IMAGE=savantly/wordpress
ARG BASE_TAG=6.6-php8.1-fpm
FROM ${BASE_IMAGE}:${BASE_TAG}

WORKDIR /usr/src/wordpress


COPY --chown=www-data:www-data plugins/ ./wp-content/plugins/
COPY --chown=www-data:www-data themes/ ./wp-content/themes/
COPY --chown=www-data:www-data config/.user.ini /usr/src/wordpress/.user.ini