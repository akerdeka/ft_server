FROM debian:buster

LABEL maintainer="<akerdeka@student.le-101.fr>"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nginx
RUN apt-get install -y default-mysql-server
RUN apt-get install -y default-mysql-client
RUN apt-get install -y mariadb-server
RUN apt-get install -y php-mbstring php-zip php-gd php-xml php-pear php-gettext php-cli php-fpm php-cgi
RUN apt-get install -y php-mysql
RUN apt-get install -y libnss3-tools
RUN apt-get install -y wget


EXPOSE 80 443


COPY srcs/localhost.conf /etc/nginx/sites-available/default


WORKDIR /var/www/html


RUN wget https://fr.wordpress.org/latest-fr_FR.tar.gz

RUN tar xf latest-fr_FR.tar.gz && \
	rm -f latest-fr_FR.tar.gz


COPY srcs/wp-config.php wordpress/


RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-all-languages.tar.xz

RUN tar xf phpMyAdmin-4.9.5-all-languages.tar.xz && \
	rm -f phpMyAdmin-4.9.5-all-languages.tar.xz && \
	mv phpMyAdmin-4.9.5-all-languages ./phpmyadmin


RUN service mysql start && \
	echo "CREATE DATABASE wordpress;" | mysql -u root && \
	echo "ALTER USER root@localhost IDENTIFIED VIA mysql_native_password;"  | mysql -u root && \
	echo "CREATE user user@localhost identified by 'password';" | mysql -u root && \
	echo "SET PASSWORD = PASSWORD('password');" | mysql -u root && \
	echo "grant all privileges on wordpress.* to user@localhost;" | mysql -u root && \
	echo "flush privileges;" | mysql -u root


RUN mkdir ~/mkcert && \
	cd ~/mkcert && \
	wget https://github.com/FiloSottile/mkcert/releases/download/v1.1.2/mkcert-v1.1.2-linux-amd64 && \
	mv mkcert-v1.1.2-linux-amd64 mkcert && \
	chmod +x mkcert && \
	./mkcert -install && \
	./mkcert localhost && \
	cp /root/mkcert/* /etc/nginx/


COPY srcs/config.inc.php ./phpmyadmin/

RUN chmod 660 /var/www/html/phpmyadmin/config.inc.php && chown -R www-data:www-data /var/www/html/phpmyadmin

RUN chown www-data:www-data * -R && usermod -a -G www-data www-data

CMD service mysql restart 2> /dev/null && echo "Launching nginx" && service php7.3-fpm start && nginx -g 'daemon off;'