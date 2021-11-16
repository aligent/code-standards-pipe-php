ARG PHP_VERSION
FROM php:${PHP_VERSION}

COPY pipe /
RUN apt-get update
RUN apt-get install -y unzip libpng-dev libicu-dev libxslt-dev jq git libzip-dev wget

RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install gd bcmath zip intl xsl pdo_mysql soap sockets

RUN chmod a+x /*.sh

RUN mkdir /composer
COPY composer.json /composer
RUN cd /composer && composer install

ENTRYPOINT ["/pipe.sh"]
