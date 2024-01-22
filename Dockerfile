ARG PHP_VERSION
FROM php:${PHP_VERSION} as standards-runtime

RUN apt-get update
RUN apt-get install -y unzip libpng-dev libicu-dev libxslt-dev jq git libzip-dev wget python3-venv
RUN apt-get clean

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN docker-php-ext-install gd bcmath zip intl xsl pdo_mysql soap sockets

RUN mkdir /composer
COPY composer.json /composer
RUN cd /composer && composer install

FROM standards-runtime

ENV PYTHONUNBUFFERED=1
RUN apt-get install -y python3-dev python3-pip
RUN apt-get clean

COPY pipe /
RUN chmod a+x /pipe.py
COPY requirements.txt /
RUN python3 -m venv /venv
RUN /venv/bin/pip install --no-cache-dir -r /requirements.txt

# Allow git access to mounted build directories
RUN git config --global --add safe.directory '*'
RUN mkdir -p /opt/atlassian/pipelines/agent/build

ENTRYPOINT ["/pipe.py"]
