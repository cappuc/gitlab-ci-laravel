FROM cappuc/gitlab-ci-laravel:${IMAGE_TAG}

# Install packages
RUN sudo apt-get update && sudo apt-get install -y \
    chromium \
    chromium-driver

# Install puppeteer
ENV PUPPETEER_SKIP_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium
RUN sudo -E npm install --global --unsafe-perm puppeteer

# Install playwright dependencies
RUN sudo npx playwright install-deps
