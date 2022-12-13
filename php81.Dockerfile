FROM php:8.1-cli as php-extension-installer
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

RUN \
    # Node repository
    curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    # Yarn repostitory
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    # Install packages
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    chromium \
    git \
    nodejs \
    yarn \
    sudo \
    unzip \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

# Install php extensions
RUN install-php-extensions \
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
    protobuf-3.21.11 \
    redis \
    soap \
    sockets \
    xdebug \
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
RUN npm install --global --unsafe-perm puppeteer@19.2.2

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