ARG PHP_VERSION
FROM aligent/m2-base-image:${PHP_VERSION}

COPY pipe /
RUN apt-get update && apt-get install wget 
RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

RUN chmod a+x /*.sh

ENTRYPOINT ["/pipe.sh"]
