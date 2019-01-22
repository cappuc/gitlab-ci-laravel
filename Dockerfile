FROM php:7.2

ENV XDEBUG_VERSION 2.5.5

RUN apt-get update && \
    apt-get install -y \
    git \
    gnupg \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libpng-dev \
    libxpm-dev \
    libc-client-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev 

# Configure gd, imap
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl

# Install xdebug
RUN pecl install xdebug mongodb redis

# Install php extensions
RUN docker-php-ext-install mbstring gd gettext imap intl mysqli opcache pcntl pdo_mysql xmlrpc zip gmp bcmath

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

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -y nodejs build-essential

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn

# Clean 
RUN apt-get autoremove

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "-a"]