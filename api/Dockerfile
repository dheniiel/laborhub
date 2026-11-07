FROM php:8.3-apache

# Extensão do MySQL, php.ini de produção e roteamento de tudo para public/index.php.
RUN docker-php-ext-install pdo_mysql \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && printf 'expose_php=Off\nlog_errors=On\nerror_log=/dev/stderr\n' > "$PHP_INI_DIR/conf.d/laborhub.ini" \
    && sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
    && printf '<Directory /var/www/html/public>\n  AllowOverride None\n  FallbackResource /index.php\n  CGIPassAuth On\n</Directory>\nServerTokens Prod\nServerSignature Off\n' \
       > /etc/apache2/conf-enabled/laborhub.conf

COPY src/ /var/www/html/src/
COPY public/ /var/www/html/public/
