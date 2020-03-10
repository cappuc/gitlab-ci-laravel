FROM php:7.4-cli

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

# Node repository
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

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
        unzip \
    && npm install --global --unsafe-perm puppeteer@2.0.0

RUN chmod uga+x /usr/local/bin/install-php-extensions \
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
    	pdo_mysql \
        redis \
    	soap \
    	xdebug \
    	pcov \
    	xmlrpc \
    	zip

# Disable xdebug & pcov
RUN rm -rf /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

# Install composer and put binary into $PATH
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install phpunit and put binary into $PATH
RUN curl -sSLo phpunit.phar https://phar.phpunit.de/phpunit.phar \
    && chmod 755 phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit

# Install PHP Code sniffer
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod 755 phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs \
    && curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod 755 phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf

# Clean
RUN apt-get autoremove

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "-a"]