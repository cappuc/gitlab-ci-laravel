#!/bin/bash
set -e

# With env variable WITH_XDEBUG=1 xdebug extension will be enabled
[ ! -z "$WITH_XDEBUG" ] && sudo -E docker-php-ext-enable xdebug

# With env variable WITH_PCOV=1 pcov extension will be enabled
[ ! -z "$WITH_PCOV" ] && sudo -E docker-php-ext-enable pcov

# Provide github token if you are using composer a lot in non-interactive mode
# Otherwise one day it will get stuck with request for authorization
# https://github.com/settings/tokens
if [[ ! -z "$COMPOSER_GITHUB" ]]; then
  composer config --global github-oauth.github.com "$COMPOSER_GITHUB"
fi

if [[ ! -z "$COMPOSER_GITLAB" ]]; then
  composer config --global gitlab-token.gitlab.com "$COMPOSER_GITLAB"
fi

#
# If $TIMEZONE variable is passed to the image - it will set system timezone 
# and php.ini date.timezone value as well
# Overwise the default system Etc/UTC timezone will be used
#
# Also you can set the php timezone with direct setting it in php.ini 
# within your .gitlab-ci.yml like
# before_script:
# - echo "America/New_York" > /usr/local/etc/php/conf.d/timezone.ini

if [[ ! -z "$TIMEZONE" ]]; then
  sudo echo "$TIMEZONE" > /etc/timezone
  sudo dpkg-reconfigure -f noninteractive tzdata
fi
echo "date.timezone=$(cat /etc/timezone)" | sudo tee ${PHP_INI_DIR}/conf.d/timezone.ini > /dev/null

exec "$@"