ARG PHP_VERSION
ARG ALPINE_VERSION

FROM busybox:latest AS validator
ARG ALPINE_VERSION
RUN : "${ALPINE_VERSION:?ALPINE_VERSION build argument is required}" && touch /validated

FROM php:${PHP_VERSION}-alpine${ALPINE_VERSION} AS standards-runtime
COPY --from=validator /validated /tmp/.validated

# Install system dependencies
RUN apk update && apk add --no-cache \
    unzip \
    libpng-dev \
    icu-dev \
    libxslt-dev \
    jq \
    git \
    libzip-dev \
    wget \
    python3 \
    py3-pip \
    python3-dev \
    # Additional dependencies for PHP extensions
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    oniguruma-dev \
    libxml2-dev \
    # Build dependencies
    autoconf \
    g++ \
    make \
    linux-headers \
    # Upgrade all packages to pick up security fixes not yet in base image
    && apk upgrade --no-cache

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd bcmath zip intl xsl pdo_mysql soap sockets

RUN mkdir /composer
COPY composer.json /composer
RUN cd /composer && \
    composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true && \
    composer install

# Remove unused npm package files from magento-coding-standard.
# These are for JavaScript linting (eslint) which this pipe doesn't use.
# Leaving them triggers false positive security alerts (e.g. GHSA-673x-qfjx-j475)
# since the package-lock.json references vulnerable npm packages that are never installed.
RUN rm -f /composer/vendor/magento/magento-coding-standard/package*.json

FROM standards-runtime

ENV PYTHONUNBUFFERED=1

# Create Python virtual environment and install dependencies
COPY pipe /
RUN chmod a+x /pipe.py
COPY requirements.txt /
RUN python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install --no-cache-dir -r /requirements.txt

# Allow git access to mounted build directories
RUN git config --global --add safe.directory /build
RUN mkdir -p /opt/atlassian/pipelines/agent/build
RUN git config --global --add safe.directory /opt/atlassian/pipelines/agent/build
RUN mkdir -p /github/workspace
RUN git config --global --add safe.directory /github/workspace

ENTRYPOINT ["/pipe.py"]
