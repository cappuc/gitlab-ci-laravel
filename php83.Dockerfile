# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=bookworm
ARG NODE_VERSION=20


FROM debian:${DEBIAN_VERSION}-slim as base
ARG TARGETPLATFORM
WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_INI_DIR /etc/php/8.3/cli

# Install dependencies for repository management
RUN apt-get update \
    && apt-get install -y ca-certificates curl gnupg

# Node repository
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# PHP repository
ARG DEBIAN_VERSION
RUN curl -fsSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ ${DEBIAN_VERSION} main" | tee /etc/apt/sources.list.d/php.list

# Cleanup
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get autoremove


FROM base as php-extensions
ARG TARGETPLATFORM

RUN apt-get install -y \
      libyaml-dev \
      libz-dev \
      php8.3-dev \
      php8.3-xml \
      php-pear

RUN pecl install grpc \
    && pecl install pcov \
    && pecl install protobuf \
    && pecl install redis \
    && pecl install yaml

RUN mkdir -p /out \
    && cp $(php-config --extension-dir)/grpc.so /out/grpc.so \
    && cp $(php-config --extension-dir)/pcov.so /out/pcov.so \
    && cp $(php-config --extension-dir)/protobuf.so /out/protobuf.so \
    && cp $(php-config --extension-dir)/redis.so /out/redis.so \
    && cp $(php-config --extension-dir)/yaml.so /out/yaml.so


FROM base

# Install packages
RUN apt-get install -y \
      chromium \
      chromium-driver \
      git \
      gnupg \
      libyaml-0-2 \
      nodejs \
      software-properties-common \
      sudo \
      tzdata \
      unzip \
      wget

# Install php & extensions
RUN apt-get install -y \
      php8.3 \
      php8.3-bcmath \
      php8.3-exif \
      php8.3-gd \
      php8.3-gettext \
      php8.3-gmp \
#      php8.3-grpc \
#      php8.3-imagick \
      php8.3-imap \
      php8.3-intl \
      php8.3-mysqli \
      php8.3-opcache \
#      php8.3-pcov \
      php8.3-mysql \
#      php8.3-protobuf \
#      php8.3-redis \
      php8.3-soap \
      php8.3-sockets \
#      php8.3-xdebug \
      php8.3-xml \
#      php8.3-yaml \
      php8.3-zip

COPY --from=php-extensions /out/*.so /tmp/php-extensions/
RUN mv /tmp/php-extensions/*.so $(php -r 'echo ini_get("extension_dir");')/ \
    && rm -rf /tmp/php-extensions \
    && echo "extension=grpc.so" > /etc/php/8.3/mods-available/grpc.ini && phpenmod grpc \
    && echo "extension=pcov.so" > /etc/php/8.3/mods-available/pcov.ini \
    && echo "extension=protobuf.so" > /etc/php/8.3/mods-available/protobuf.ini && phpenmod protobuf \
    && echo "extension=redis.so" > /etc/php/8.3/mods-available/redis.ini && phpenmod redis \
    && echo "extension=yaml.so" > /etc/php/8.3/mods-available/yaml.ini && phpenmod yaml

# Install yarn & pnpm
RUN corepack enable \
    && corepack prepare pnpm@latest --activate \
    && corepack prepare yarn@1.22.11 --activate

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install puppeteer
RUN npm install --global --unsafe-perm puppeteer

# Install bun
RUN curl -fsSL https://bun.sh/install | bash

COPY php $PHP_INI_DIR/conf.d

# Add non-privileged user
RUN groupadd -r user \
    && useradd -r -g user -G audio,video,sudo user \
    && mkdir -p /home/user \
    && mkdir -p /builds \
    && chown -R user:user /home/user \
    && chown -R user:user /builds \
    && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Run everything after as non-privileged user.
USER user
WORKDIR /home/user

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
