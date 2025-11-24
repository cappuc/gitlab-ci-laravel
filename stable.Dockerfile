# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=trixie
ARG NODE_VERSION=24
ARG PHP_VERSION=8.4


FROM debian:${DEBIAN_VERSION}-slim AS base
ARG TARGETPLATFORM
WORKDIR /

ARG PHP_VERSION
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_INI_DIR /etc/php/${PHP_VERSION}/cli

# Install dependencies for repository management
RUN apt-get update \
    && apt-get install -y lsb-release ca-certificates curl gnupg

# Node repository
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -

# PHP repository
ARG DEBIAN_VERSION
RUN curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ ${DEBIAN_VERSION} main" > /etc/apt/sources.list.d/php.list

# Cleanup
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get autoremove


# FROM base AS php-extensions
# ARG TARGETPLATFORM

# RUN apt-get install -y \
#     libyaml-dev \
#     libz-dev \
#     php${PHP_VERSION}-dev \
#     php${PHP_VERSION}-xml \
#     php-pear


# RUN pecl install grpc \
#     && pecl install protobuf

# RUN mkdir -p /out \
#     && cp $(php-config --extension-dir)/grpc.so /out/grpc.so \
#     && cp $(php-config --extension-dir)/protobuf.so /out/protobuf.so


FROM base

# Install packages
RUN apt-get update && apt-get install -y \
    git \
    nodejs \
    sudo \
    tzdata \
    unzip \
    wget

# Install php & extensions
ARG PHP_VERSION
RUN apt-get update && apt-get install -y \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-gettext \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-grpc \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-pcov \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-protobuf \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-sockets \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-yaml \
    php${PHP_VERSION}-zip \
    && phpdismod pcov \
    && phpdismod xdebug

RUN ln -s $(php -r 'echo ini_get("extension_dir");') /usr/lib/extensions

# COPY --from=php-extensions /out/*.so /usr/lib/extensions
# RUN echo "extension=grpc.so" > /etc/php/${PHP_VERSION}/mods-available/grpc.ini && phpenmod grpc \
#     && echo "extension=protobuf.so" > /etc/php/${PHP_VERSION}/mods-available/protobuf.ini && phpenmod protobuf

# Install yarn & pnpm
RUN corepack enable

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install bun
RUN curl -fsSL https://bun.sh/install | bash \
    && mv /root/.bun/bin/bun /usr/local/bin/bun \
    && rm -rf /root/.bun \
    && chmod a+x /usr/local/bin/bun

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
