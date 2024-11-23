# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=12
ARG NODE_VERSION=22


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

#RUN pecl install redis
#
#RUN mkdir -p /out \
#    && cp $(php-config --extension-dir)/redis.so /out/redis.so


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
    php8.3-bcmath \
    php8.3-cli \
    php8.3-curl \
    php8.3-exif \
    php8.3-gd \
    php8.3-gettext \
    php8.3-gmp \
    php8.3-grpc \
    php8.3-imagick \
    php8.3-imap \
    php8.3-intl \
    php8.3-mbstring \
    php8.3-mysqli \
    php8.3-opcache \
    php8.3-pcov \
    php8.3-mysql \
    php8.3-protobuf \
    php8.3-redis \
    php8.3-soap \
    php8.3-sockets \
    php8.3-sqlite3 \
    php8.3-xdebug \
    php8.3-xml \
    php8.3-yaml \
    php8.3-zip \
    && phpdismod pcov \
    && phpdismod xdebug

RUN ln -s $(php -r 'echo ini_get("extension_dir");') /usr/lib/extensions

#COPY --from=php-extensions /out/*.so /usr/lib/extensions
#RUN echo "extension=redis.so" > /etc/php/8.3/mods-available/redis.ini && phpenmod redis

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
