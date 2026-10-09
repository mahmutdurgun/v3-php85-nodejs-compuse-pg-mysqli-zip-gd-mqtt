#!/bin/sh
set -eu
cd "$(dirname "$0")"
# İlk hazırlık veya bilinçli güncelleme: çalışan konteynerleri değiştirmez.
docker build --pull -t mahmut-php-web:8.5-v3 .
