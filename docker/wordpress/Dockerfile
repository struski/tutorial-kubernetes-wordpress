FROM php:7.1.9-fpm-alpine
MAINTAINER Michael Struski <no-reply@struscode.com>

COPY bashrc /etc/bash.bashrc
COPY profile /etc/profile

RUN apk add --no-cache git openssh-client nginx mysql-client \
    supervisor curl bash nano

# START - COPIED FROM OFFICIAL WORDPRESS DOCKERFILE - https://github.com/docker-library/wordpress/blob/master/php7.1/fpm-alpine/Dockerfile
# Modifications made to original:
#     - Jetpack plugin - added libxml2-dev package and php extensions: xml and xmlrpc - remove if plugin not used
# install the PHP extensions we need
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		libjpeg-turbo-dev \
		libpng-dev \
		libxml2-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache xml xmlrpc; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --recursive \
			/usr/local/lib/php/extensions \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini



ENV WORDPRESS_VERSION 4.8.3
ENV WORDPRESS_SHA1 8efc0b9f6146e143ed419b5419d7bb8400a696fc

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz;
# END - COPIED FROM OFFICIAL WORDPRESS DOCKERFILE - https://github.com/docker-library/wordpress/blob/master/php7.1/fpm-alpine/Dockerfile

# iconv FIX - uncomment if you ever encounter iconv problem
#RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
#ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# based on tutorial https://codeable.io/wordpress-developers-intro-to-docker-part-two/
ENV WORDPRESS_ROOT /usr/src/wordpress

RUN adduser -D deployer -s /bin/bash -G www-data

#Modify to reflect your project's domain name
VOLUME /var/www/example.com
WORKDIR /var/www/example.com

COPY wp-config.php $WORDPRESS_ROOT
RUN chown -R deployer:www-data $WORDPRESS_ROOT \
    && chmod 770 $WORDPRESS_ROOT \
    && chmod 640 $WORDPRESS_ROOT/wp-config.php

COPY cron.conf /etc/crontabs/deployer
RUN chmod 600 /etc/crontabs/deployer

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY nginx.conf /etc/nginx/nginx.conf
COPY wordpress.conf /etc/nginx/conf.d/
COPY restrictions.conf /etc/nginx/restrictions.conf
COPY html/index.html /var/www/html
RUN  mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf-original
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

COPY supervisor/supervisord.conf /etc/supervisord.conf
COPY supervisor/stop-supervisor.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]