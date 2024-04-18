# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=bookworm
ARG NODE_VERSION=20


FROM debian:${DEBIAN_VERSION}-slim as base
ARG TARGETPLATFORM
WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_INI_DIR /etc/php/8.2/cli

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
    php8.2-dev \
    php8.2-xml \
    php-pear

#RUN pecl install <extension>
#
#RUN mkdir -p /out \
#    && cp $(php-config --extension-dir)/<extension>.so /out/<extension>.so


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
    php8.2-bcmath \
    php8.2-cli \
    php8.2-curl \
    php8.2-exif \
    php8.2-gd \
    php8.2-gettext \
    php8.2-gmp \
    php8.2-grpc \
    php8.2-imagick \
    php8.2-imap \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-mysqli \
    php8.2-opcache \
    php8.2-pcov \
    php8.2-mysql \
    php8.2-protobuf \
    php8.2-redis \
    php8.2-soap \
    php8.2-sockets \
    php8.2-sqlite3 \
    php8.2-xdebug \
    php8.2-xml \
    php8.2-yaml \
    php8.2-zip \
    && phpdismod pcov \
    && phpdismod xdebug

RUN ln -s $(php -r 'echo ini_get("extension_dir");') /usr/lib/extensions

#COPY --from=php-extensions /out/*.so /usr/lib/extensions
#RUN echo "extension=<extension>.so" > /etc/php/8.3/mods-available/<extension>.ini && phpenmod <extension>

# Install yarn & pnpm
RUN corepack enable \
    && corepack install -g pnpm@latest \
    && corepack install -g yarn@1.22.11

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
