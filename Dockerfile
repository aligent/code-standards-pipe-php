ARG PHP_VERSION
FROM php:${PHP_VERSION}-alpine3.21 as standards-runtime

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
    linux-headers

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
