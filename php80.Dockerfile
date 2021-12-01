FROM php:8.0-cli

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN \
    # Node repository
    curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    # Yarn repostitory
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    # Install packages
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        chromium=90.* \
        git \
        nodejs \
        yarn \
        sudo \
        unzip \
    && apt-get autoremove \
   && rm -rf /var/lib/apt/lists/*

RUN curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        bcmath \
        exif \
    	  gd \
    	  gettext \
    	  gmp \
        grpc \
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
    	  xdebug \
    	  zip \
    # Strip debug symbols
    && strip --strip-all /usr/local/lib/php/extensions/*/*.so \
    # Disable xdebug & pcov
    && rm -rf /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install PHP cs fixer
RUN curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o /usr/local/bin/php-cs-fixer \
    && chmod +x /usr/local/bin/php-cs-fixer

# Install puppeteer
RUN npm install --global --unsafe-perm puppeteer@8.0.0

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