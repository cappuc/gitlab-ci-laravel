FROM php:8.1-rc-cli

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

# Node repository
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

# Yarn repostitory
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update \
    && apt-get upgrade -y

RUN apt-get install -y \
        chromium \
        git \
        nodejs \
        yarn \
        sudo \
        unzip

RUN chmod uga+x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        bcmath \
        exif \
    	  gd \
    	  gettext \
    	  gmp \
        grpc \
        protobuf \
        imagick \
    	  imap \
    	  intl \
    	  mysqli \
    	  opcache \
    	  pcntl \
    	  pdo_mysql \
        redis \
    	  soap \
    	  xdebug \
    	  pcov \
    	  zip

# Disable xdebug & pcov
RUN rm -rf /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install PHP Code sniffer
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod 755 phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs \
    && curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod 755 phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf

# Install puppeteer
RUN npm install --global --unsafe-perm puppeteer

# Clean
RUN apt-get autoremove

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