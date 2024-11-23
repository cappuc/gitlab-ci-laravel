# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=bookworm
ARG NODE_VERSION=22


FROM debian:${DEBIAN_VERSION}-slim as base
ARG TARGETPLATFORM
WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_INI_DIR /etc/php/8.4/cli

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
    php8.4-dev \
    php8.4-xml \
    php-pear


RUN pecl install grpc \
    && pecl install protobuf \
    && pecl install redis \
    && pecl install yaml

RUN mkdir -p /out \
    && cp $(php-config --extension-dir)/grpc.so /out/grpc.so \
    && cp $(php-config --extension-dir)/protobuf.so /out/protobuf.so \
    && cp $(php-config --extension-dir)/redis.so /out/redis.so \
    && cp $(php-config --extension-dir)/yaml.so /out/yaml.so


FROM base as slim

# Install packages
RUN apt-get update && apt-get install -y \
    git \
    nodejs \
    software-properties-common \
    sudo \
    tzdata \
    unzip \
    wget

# Install php & extensions
RUN apt-get update && apt-get install -y \
    php8.4-bcmath \
    php8.4-cli \
    php8.4-curl \
    php8.4-exif \
    php8.4-gd \
    php8.4-gettext \
    php8.4-gmp \
    # php8.4-grpc \
    # php8.4-imagick \
    # php8.4-imap \
    php8.4-intl \
    php8.4-mbstring \
    php8.4-mysqli \
    php8.4-opcache \
    # php8.4-pcov \
    php8.4-mysql \
    # php8.4-protobuf \
    # php8.4-redis \
    php8.4-soap \
    php8.4-sockets \
    php8.4-sqlite3 \
    # php8.4-xdebug \
    php8.4-xml \
    # php8.4-yaml \
    php8.4-zip
# && phpdismod pcov \
# && phpdismod xdebug

RUN ln -s $(php -r 'echo ini_get("extension_dir");') /usr/lib/extensions

COPY --from=php-extensions /out/*.so /usr/lib/extensions
RUN echo "extension=grpc.so" > /etc/php/8.4/mods-available/grpc.ini && phpenmod grpc \
    && echo "extension=protobuf.so" > /etc/php/8.4/mods-available/protobuf.ini && phpenmod protobuf \
    && echo "extension=redis.so" > /etc/php/8.4/mods-available/redis.ini && phpenmod redis \
    && apt-get install -y libyaml-0-2 && echo "extension=yaml.so" > /etc/php/8.4/mods-available/yaml.ini && phpenmod yaml

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


FROM slim as browsers

# Install packages
RUN sudo apt-get update && sudo apt-get install -y \
    chromium \
    chromium-driver

# Install puppeteer
ENV PUPPETEER_SKIP_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium
RUN sudo -E npm install --global --unsafe-perm puppeteer

# Install playwright dependencies
RUN sudo npx playwright install-deps
