# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=bookworm
ARG NODE_VERSION=20


FROM debian:${DEBIAN_VERSION}-slim as base
ARG TARGETPLATFORM
WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_INI_DIR /etc/php/8.1/cli

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
      php8.1-dev \
      php8.1-xml \
      php-pear

#RUN pecl install <extension>
#
#RUN mkdir -p /out \
#    && cp $(php-config --extension-dir)/<extension>.so /out/<extension>.so


FROM base

# Install packages
RUN apt-get update && apt-get install -y \
      chromium \
      chromium-driver \
      git \
      nodejs \
      software-properties-common \
      sudo \
      tzdata \
      unzip \
      wget

# Install php & extensions
RUN apt-get update && apt-get install -y \
      php8.1-bcmath \
      php8.1-cli \
      php8.1-curl \
      php8.1-exif \
      php8.1-gd \
      php8.1-gettext \
      php8.1-gmp \
      php8.1-grpc \
      php8.1-imagick \
      php8.1-imap \
      php8.1-intl \
      php8.1-mbstring \
      php8.1-mysqli \
      php8.1-opcache \
      php8.1-pcov \
      php8.1-mysql \
      php8.1-protobuf \
      php8.1-redis \
      php8.1-soap \
      php8.1-sockets \
      php8.1-sqlite3 \
      php8.1-xdebug \
      php8.1-xml \
      php8.1-yaml \
      php8.1-zip \
  && phpdismod pcov \
  && phpdismod xdebug

RUN ln -s $(php -r 'echo ini_get("extension_dir");') /usr/lib/extensions

#COPY --from=php-extensions /out/*.so /usr/lib/extensions
#RUN echo "extension=<extension>.so" > /etc/php/8.3/mods-available/<extension>.ini && phpenmod <extension>

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
