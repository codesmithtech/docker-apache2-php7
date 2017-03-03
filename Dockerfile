FROM centos:latest

MAINTAINER david@codesmith.tech

RUN yum makecache && yum update -y

RUN yum install -y \
    unzip \
    gcc \
    libc-dev \
    make \
    autoconf \
    automake \
    libtool \
    bison \
    wget \
    ssmtp \
    libpcre3-dev \
    libxml2-devel.x86_64 \
    openssl-devel.x86_64 \
    libcurl-devel.x86_64 \
    libiodbc-devel.x86_64 \
    libmemcached-devel.x86_64 \
    zlib-devel.x86_64

RUN mkdir /php && \
    cd /php && \
    wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz && \
    tar xvzf libmcrypt-2.5.7.tar.gz && \
    cd libmcrypt-2.5.7 && \
    ./configure && \
    make && \
    make install && \
    rm -rf /php

RUN mkdir /apr && \
    cd /apr && \
    wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org//apr/apr-1.5.2.tar.gz && \
    tar xvzf apr-1.5.2.tar.gz && \
    cd apr-1.5.2 && \
    ./configure && \
    make && \
    make install && \
    rm -rf /apr

RUN mkdir /apr-util && \
    cd /apr-util && \
    wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org//apr/apr-util-1.5.4.tar.gz && \
    tar xvzf apr-util-1.5.4.tar.gz && \
    cd apr-util-1.5.4 && \
    ./configure --with-apr=/usr/local/apr && \
    make && \
    make install && \
    rm -rf /apr-util

RUN mkdir /apache && \
    cd /apache && \
    wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org//httpd/httpd-2.4.25.tar.gz && \
    tar xvzf httpd-2.4.25.tar.gz && \
    cd httpd-2.4.25 && \
    ./configure \
    --enable-rewrite \
    --enable-ssl \
    --enable-so \
    --enable-status && \
    make && \
    make install && \
    rm -rf /apache

RUN mkdir -p /php && \
    cd /php && \
    wget https://github.com/php/php-src/archive/PHP-7.1.2.zip && \
    unzip PHP-7.1.2.zip && \
    mv php-src-PHP-7.1.2 src && \
    cd /php/src && \
    ./buildconf --force && \
    ./configure -C \
    --with-apxs2=/usr/local/apache2/bin/apxs \
    --with-config-file-path=/etc/php.ini \
    --with-config-file-scan-dir=/etc/php.d \
    --enable-bcmath \
    --enable-calendar \
    --enable-mbstring \
    --enable-xml \
    --enable-pcntl \
    --enable-ftp \
    --enable-zip \
    --enable-sockets \
    --enable-soap \
    --with-openssl \
    --with-openssl-dir=/usr/include/openssl \
    --with-curl=/usr/include/curl \
    --with-mcrypt=/usr/local/include \
    --with-zlib-dir=/usr/include \
    --with-pdo-mysql=mysqlnd && \
    make && \
    make install && \
    cp /php/src/php.ini-production /etc/php.ini && \
    mkdir -p /etc/php.d && \
    rm -rf /php

WORKDIR /app

RUN pecl install memcached && \
	echo "extension=memcached.so" > /etc/php.d/memcache.ini

RUN sed -i -e "s/expose_php\ =\ On/expose_php\ =\ Off/g" /etc/php.ini \
    && sed -i -e "s/\;error_log\ =\ php_errors\.log/error_log\ =\ \/var\/log\/php_errors\.log/g" /etc/php.ini \
    && sed -i -e "s/\;date\.timezone =/date\.timezone = Europe\/London/g" /etc/php.ini

RUN sed -i -e "s/#LoadModule rewrite_module/LoadModule rewrite_module/g" /usr/local/apache2/conf/httpd.conf && \
    sed -i -e "s/#LoadModule ssl_module/LoadModule ssl_module/g" /usr/local/apache2/conf/httpd.conf && \
    rm -f /usr/local/apache2/conf/extra/httpd-vhosts.conf

RUN wget https://getcomposer.org/installer && \
	mv installer composer-installer.php && \
	php composer-installer.php --install-dir=/usr/local/bin --filename=composer && \
	rm -rf composer-installer.php

RUN useradd -d /home/apache -u 1000 -s /bin/bash apache && chown apache:apache /home/apache

RUN unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/London /etc/localtime && \
    ln -s /usr/local/bin/php /usr/bin/php

RUN ln -sf /dev/stdout /var/log/httpd-access.log && ln -sf /dev/stderr /var/log/httpd-error.log

RUN yum remove -y unzip gcc libc-dev make autoconf automake libtool bison wget

CMD ["/usr/local/apache2/bin/httpd", "-DFOREGROUND"]
