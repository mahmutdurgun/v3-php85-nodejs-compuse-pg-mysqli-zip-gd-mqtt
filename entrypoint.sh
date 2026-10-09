#!/bin/sh
set -eu
umask 0002
mkdir -p /run/sshd /var/www/html /etc/ssh/host-keys
for kind in rsa ecdsa ed25519; do
    key="/etc/ssh/host-keys/ssh_host_${kind}_key"
    [ -f "$key" ] || ssh-keygen -q -t "$kind" -N '' -f "$key"
done
printf 'HostKey /etc/ssh/host-keys/ssh_host_rsa_key\nHostKey /etc/ssh/host-keys/ssh_host_ecdsa_key\nHostKey /etc/ssh/host-keys/ssh_host_ed25519_key\n' > /etc/ssh/sshd_config.d/host-keys.conf
# Başlangıç sayfasını yalnızca ana sayfa yoksa oluştur; mevcut siteye dokunma.
if [ ! -e /var/www/html/index.php ] && [ ! -e /var/www/html/index.html ]; then
    cp /opt/examples/welcome.php /var/www/html/index.php
fi
# Bind mount açıldıktan sonra mevcut dosyalar + gelecekteki SFTP/Apache dosyaları.
# Dosya sahipleri değiştirilmez; ACL ile mahmut ve Apache yazabilir.
setfacl -R -m u:mahmut:rwX,u:www-data:rwX /var/www/html
find /var/www/html -type d -exec setfacl -m d:u:mahmut:rwx,d:u:www-data:rwx {} +
exec docker-php-entrypoint "$@"
