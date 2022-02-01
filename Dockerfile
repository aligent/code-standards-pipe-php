ARG PHP_VERSION
FROM php:${PHP_VERSION}

ENV PYTHONUNBUFFERED=1
RUN apt-get update
RUN apt-get install -y unzip libpng-dev libicu-dev libxslt-dev jq git libzip-dev wget python3-dev python3-pip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install gd bcmath zip intl xsl pdo_mysql soap sockets

RUN mkdir /composer
COPY composer.json /composer
RUN cd /composer && composer install

COPY pipe /
RUN chmod a+x /pipe.py
COPY requirements.txt /
RUN python3 -m pip install --no-cache-dir -r /requirements.txt

ENTRYPOINT ["/pipe.py"]
