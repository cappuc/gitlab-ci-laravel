# syntax=docker/dockerfile:1.4

FROM php:8.0-cli as php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions


FROM php-extension-installer as php-grpc
ENV PHP_GRPC_VERSION=1.49.0
RUN install-php-extensions grpc-${PHP_GRPC_VERSION} \
    && mkdir -p /out \
    && cp $(php-config --extension-dir)/grpc.so /out/grpc.so


FROM php-extension-installer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium

# Node repository
ENV NODE_MAJOR 20
RUN apt-get update \
    && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install packages
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    chromium \
    chromium-driver \
    git \
    nodejs=20.5.1* \
    sudo \
    unzip \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install yarn & pnpm
RUN corepack enable \
    && corepack prepare pnpm@latest --activate \
    && corepack prepare yarn@1.22.11 --activate

RUN curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
    bcmath \
    exif \
    gd \
    gettext \
    gmp \
    imagick \
    imap \
    intl \
    mysqli \
    opcache \
    pcntl \
    pcov \
    pdo_mysql \
    protobuf \
    redis \
    soap \
    sockets \
    xdebug \
    yaml \
    zip \
    # Disable xdebug & pcov
    && rm -rf /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

COPY --from=php-grpc /out/grpc.so /tmp/extensions/grpc.so
RUN mv /tmp/extensions/*.so $(php-config --extension-dir)/ \
    && docker-php-ext-enable grpc

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install puppeteer
RUN npm install --global --unsafe-perm puppeteer@21.1.0

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
CMD ["php", "-a"]
