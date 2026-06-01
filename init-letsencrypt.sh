#!/bin/sh
# Первичный выпуск сертификата Let's Encrypt для nginx.
# Запускать ОДИН РАЗ на сервере после того, как A-запись домена указывает на этот сервер.
# Дальше certbot-контейнер продлевает сертификат автоматически.
set -e

DOMAIN="castapp.ru"
WWW_DOMAIN="www.castapp.ru"
EMAIL="q1zin@mail.ru"
COMPOSE="docker compose -f docker-compose.infra.yml"

STAGING=0

echo ">> 1/4 Создаю временный самоподписанный сертификат, чтобы nginx смог стартовать..."
$COMPOSE run --rm --entrypoint "\
  sh -c 'mkdir -p /etc/letsencrypt/live/$DOMAIN && \
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -out /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -subj \"/CN=$DOMAIN\"'" certbot

echo ">> 2/4 Поднимаю nginx с временным сертификатом..."
$COMPOSE up -d nginx
sleep 5

echo ">> 3/4 Удаляю временный сертификат и запрашиваю настоящий у Let's Encrypt..."
$COMPOSE run --rm --entrypoint "rm -rf /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/archive/$DOMAIN /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

STAGING_ARG=""
[ "$STAGING" != "0" ] && STAGING_ARG="--staging"

$COMPOSE run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $STAGING_ARG \
    -d $DOMAIN -d $WWW_DOMAIN \
    --email $EMAIL \
    --rsa-key-size 2048 \
    --agree-tos \
    --no-eff-email \
    --force-renewal" certbot

echo ">> 4/4 Перезагружаю nginx с настоящим сертификатом..."
$COMPOSE exec nginx nginx -s reload

echo ">> Готово. HTTPS должен работать: https://$DOMAIN"
