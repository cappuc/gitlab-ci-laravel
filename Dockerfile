FROM php:7.1

ENV XDEBUG_VERSION 2.5.5

RUN apt-get update

RUN apt-get install -y \
    # gd
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libpng12-dev \
    libxpm-dev \
    # imap
    libc-client-dev \
    libkrb5-dev \
    # ldap
    # libldap2-dev \
    # libsasl2-dev \
    # php-ext-bz2
    # libbz2-dev \
    # php-ext-enchant
    # libenchant-dev \
    # php-ext-gmp
    # libgmp3-dev \
    # php-ext-mcrypt
    libmcrypt-dev \
    # php-ext-tidy
    # libtidy-dev
    # php-ext-intl
    libicu-dev \
    # php-ext-xmlrpx
    libxml2-dev 
# freetds-dev \
# libpq-dev \
# libpspell-dev \
# librabbitmq-dev \
# libsnmp-dev \
# libssl-dev \
# libxslt1-dev \
# zlib1g-dev

# Fix ldap
# RUN  ln -s /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap.so \
#     && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.a /usr/lib/libldap_r.a 

# Configure gd, impa, ldap
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl
# && docker-php-ext-configure ldap --with-ldap-sasl

# Install xdebug
RUN pecl install xdebug mongodb redis

# Install php extensions
RUN docker-php-ext-install mbstring gd gettext imap intl mcrypt mysqli opcache pcntl pdo_mysql xmlrpc zip

# RUN docker-php-ext-install bcmath bz2 calendar dba enchant exif ftp gd gettext gmp imap \
#     intl ldap mbstring mcrypt mysqli opcache pcntl pdo pdo_dblib pdo_mysql pdo_pgsql pgsql \
#     pspell shmop snmp soap sockets sysvmsg sysvsem sysvshm tidy wddx xmlrpc xsl zip

# RUN docker-php-ext-enable xdebug

# # Install php extensions
# RUN buildDeps=" \
#         freetds-dev \
#         libbz2-dev \
#         libc-client-dev \
#         libenchant-dev \
#         libfreetype6-dev \
#         libgmp3-dev \
#         libicu-dev \
#         libjpeg62-turbo-dev \
#         libkrb5-dev \
#         libldap2-dev \
#         libmcrypt-dev \
#         libpng12-dev \
#         libpq-dev \
#         libpspell-dev \
#         librabbitmq-dev \
#         libsasl2-dev \
#         libsnmp-dev \
#         libssl-dev \
#         libtidy-dev \
#         libxml2-dev \
#         libxpm-dev \
#         libxslt1-dev \
#         zlib1g-dev \
#     " \
#     && phpModules=" \
#         bcmath bz2 calendar dba enchant exif ftp gd gettext gmp imap intl ldap mbstring mcrypt mysqli opcache pcntl pdo pdo_dblib pdo_mysql pdo_pgsql pgsql pspell shmop snmp soap sockets sysvmsg sysvsem sysvshm tidy wddx xmlrpc xsl zip xdebug \
#     " \
#     && echo "deb http://httpredir.debian.org/debian jessie contrib non-free" > /etc/apt/sources.list.d/additional.list \
#     && apt-get update && apt-get install -y libc-client2007e libenchant1c2a libfreetype6 libicu52 libjpeg62-turbo libmcrypt4 libpng12-0 libpq5 libsybdb5 libtidy-0.99-0 libx11-6 libxpm4 libxslt1.1 snmp --no-install-recommends \
#     && apt-get install -y $buildDeps --no-install-recommends \
#     && docker-php-source extract \
#     && cd /usr/src/php/ext/ \
#     && curl -L http://xdebug.org/files/xdebug-$XDEBUG_VERSION.tgz | tar -zxf - \
#     && mv xdebug-$XDEBUG_VERSION xdebug \
#     && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
#     && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap.so \
#     && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.a /usr/lib/libldap_r.a \
#     && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a \
#     && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so \
#     && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
#     && docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl \
#     && docker-php-ext-configure ldap --with-ldap-sasl \
#     && docker-php-ext-install $phpModules \
#     && printf "\n" | pecl install amqp \
#     && pecl install igbinary \
# #    && printf "\n" | pecl install memcache \
#     && pecl install mongodb \
#     && pecl install redis \
#     && for ext in $phpModules; do \
#            rm -f /usr/local/etc/php/conf.d/docker-php-ext-$ext.ini; \
#        done \
#     && docker-php-source delete \
#     && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
#     && docker-php-ext-enable xdebug

# # Install additional packages
# RUN apt-get update && apt-get install -y git msmtp-mta openssh-client --no-install-recommends && rm -r /var/lib/apt/lists/*

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

# RUN apt-get install -y rsync

# Clean 
RUN apt-get autoremove

# RUN rm -r /var/lib/apt/lists/*

# # COPY msmtprc /etc/
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "-a"]