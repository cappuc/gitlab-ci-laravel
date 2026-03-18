#!/bin/bash
set -e

# With env variable WITH_XDEBUG=1 xdebug extension will be enabled
[ ! -z "$WITH_XDEBUG" ] && sudo -E docker-php-ext-enable xdebug

# With env variable WITH_PCOV=1 pcov extension will be enabled
[ ! -z "$WITH_PCOV" ] && sudo -E docker-php-ext-enable pcov

# Provide github token if you are using composer a lot in non-interactive mode
# Otherwise one day it will get stuck with request for authorization
if [[ ! -z "$COMPOSER_GITHUB" ]]; then
  composer config --global github-oauth.github.com "$COMPOSER_GITHUB"
fi

if [[ ! -z "$COMPOSER_GITLAB" ]]; then
  composer config --global gitlab-token.gitlab.com "$COMPOSER_GITLAB"
fi

if [[ ! -z "$COMPOSER_KEEPSUIT" ]]; then
  composer config --global --auth http-basic.composer.keepsuit.com token "$COMPOSER_KEEPSUIT"
fi

exec "$@"
