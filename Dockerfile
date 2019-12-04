FROM php:7.4-cli

RUN apt-get update \
    && apt-get upgrade -y

# Node repository
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# Yarn repostitory
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get install -y apt-transport-https gnupg build-essential

RUN apt-get install -y \
        git \
        nodejs \
        yarn \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libpng-dev \
        libxpm-dev \
        libc-client-dev \
        libkrb5-dev \
        libmcrypt-dev \
        libicu-dev \
        libxml2-dev \
        libgmp-dev \
        libzip-dev \
        libssl-dev \
        libonig-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        unzip

# Configure gd, imap
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-xpm
RUN PHP_OPENSSL=yes docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl

# Install php extensions
RUN docker-php-ext-install -j$(nproc) mbstring gd gettext imap intl mysqli opcache pcntl pdo_mysql xmlrpc zip gmp bcmath exif soap

# Install pecl extensions
RUN pecl install mongodb redis imagick xdebug pcov
RUN docker-php-ext-enable mongodb redis imagick

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