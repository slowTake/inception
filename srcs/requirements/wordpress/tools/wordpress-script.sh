#!/bin/sh
set -e

echo "==> Setting up WordPress..."
{
	echo "memory_limit = 256M"
	echo "max_execution_time = 120"
} >> /etc/php83/php.ini

cd /var/www/html

if [ ! -x /usr/local/bin/wp ]; then
	echo "==> Downloading WP-CLI..."
	wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp \
		|| { echo "Failed to download wp-cli"; exit 1; }
	chmod +x /usr/local/bin/wp
fi

echo "==> Waiting for MariaDB..."
mariadb-admin ping \
	--protocol=tcp \
	--host=mariadb \
	-u "${WORDPRESS_DATABASE_USER}" \
	--password="${WORDPRESS_DATABASE_USER_PASSWORD}" \
	--wait=300

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "==> Installing WordPress..."
	wp core download --allow-root --path=/var/www/html

	wp config create \
		--dbname="${WORDPRESS_DATABASE_NAME}" \
		--dbuser="${WORDPRESS_DATABASE_USER}" \
		--dbpass="${WORDPRESS_DATABASE_USER_PASSWORD}" \
		--dbhost=mariadb \
		--allow-root \
		--path=/var/www/html \
		--force

	wp core install \
		--url="https://${DOMAIN_NAME}" \
		--title="${WORDPRESS_TITLE}" \
		--admin_user="${WORDPRESS_ADMIN}" \
		--admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
		--admin_email="${WORDPRESS_ADMIN_EMAIL}" \
		--allow-root \
		--skip-email \
		--path=/var/www/html

	echo "==> Creating secondary WordPress user..."
	wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
		--role=subscriber \
		--user_pass="${WORDPRESS_USER_PASSWORD}" \
		--allow-root \
		--path=/var/www/html
else
	echo "==> WordPress already configured."
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "==> Starting PHP-FPM..."
exec php-fpm83 -F
