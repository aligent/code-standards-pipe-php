ARG PHP_VERSION
FROM php:8.1 as standards-runtime

RUN apt-get update
RUN apt-get install -y unzip libpng-dev libicu-dev libxslt-dev jq git libzip-dev wget
RUN apt-get clean

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install gd bcmath zip intl xsl pdo_mysql soap sockets

RUN mkdir /composer
COPY composer.json /composer
RUN cd /composer && composer install
RUN /composer/vendor/bin/phpcs --config-set installed_paths /composer/vendor/magento/magento-coding-standard/,/composer/vendor/pheromone/phpcs-security-audit/,/composer/vendor/phpcompatibility/php-compatibility

FROM standards-runtime

ENV PYTHONUNBUFFERED=1
RUN apt-get install -y python3-dev python3-pip
RUN apt-get clean

COPY pipe /
RUN chmod a+x /pipe.py
COPY requirements.txt /
RUN python3 -m pip install --no-cache-dir -r /requirements.txt

ENTRYPOINT ["/pipe.py"]
