# Portainer'da otomatik boş portlar — v3

Portainer Git template ortam değişkenlerinden HOST_HTTP_PORT ve HOST_SSH_PORT
eski sabit değerlerini KALDIRIN. Varsayılan aralıklar HTTP 300–399 ve SSH 400–499.
İsterseniz aynı aralıkları açıkça girin:
HOST_HTTP_PORT=300-399
HOST_SSH_PORT=400-499
COMPOSE_PROJECT_NAME=dene3

Docker her konteyner için aralıktan boş port seçer. Kesin ardışık sıra ve
HTTP/SSH eşleşen son rakam garantisi YOKTUR; port çakışması olmadan otomatik
atama yapılır. Stack için bu değişkeni stack adıyla aynı girin; her projenin
HTML klasörü ayrı kalır. Kesin 300/400, 301/401 sırası sadece Python betiğindedir.
Portainer Published ports alanından atanan portları kontrol edin. Konteyner
silinip yeniden oluşturulursa portlar değişebilir; aynı konteyner yeniden
başlatıldığında eşlemeleri korunur. Aralıkta boş port kalmazsa kurulum durur.

Yeni imaj etiketi mahmut-php-web:8.5-v3'tür. Yeni özellikleri almak için bir kez
derlenir. Aynı sunucudaki sonraki stack'ler hazır imajı kullanabilir.
Başlangıç index.php dosyası ana sayfası olmayan HTML klasörlerine eklenir;
mevcut index.php/index.html üzerine yazılmaz. Bileşen bilgileri gösterilir,
şifreler ve ortam değişkenlerinin değerleri sayfada yayımlanmaz.

---

## Git deposuna yükleme
ZIP içindeki klasörün dosyalarını deponuza yükleyin. Dockerfile ile Compose
aynı dizinde kalmalı; Portainer Compose path alanını gerçek yola ayarlayın.
build: . eksik imajı derler; yerel imaj için force pull kullanmayın.

# Güncellenmiş PHP / Apache / SSH / Node ortamı — hızlı v2

SSH ve SFTP hesabı aynen korundu: **mahmut / 1234**.
250 MB yükleme, 250 MB POST, 512 MB bellek ve 300 saniye çalışma limiti korundu.

## İmajı bir kez hazırlama / bilinçli güncelleme
```bash
sudo sh build-image.sh
```
Yeni sürümün imaj etiketi `mahmut-php-web:8.5-v3` olduğundan eski paketin imajı
ile karışmaz. Bu işlem çalışan konteynerleri değiştirmez. İlk new-container.py
çağrısı imaj eksikse aynı derlemeyi otomatik yapar. Sonraki projelerde imaj
indirilmez veya yeniden derlenmez. Python komutu hazır imajı kullanır. Portainer Git kurulumu ise
Compose içindeki build: . tanımından eksik imajı derleyebilir.

## Yeni konteyner açma
Linux Docker sunucusunda Docker Engine, Compose v2 ve Python 3 gerekir.
ZIP'i açın ve bu dosyaların bulunduğu klasörde çalıştırın:

```bash
sudo python3 new-container.py proje1
sudo python3 new-container.py proje2
sudo python3 new-container.py proje3
```

| Proje | HTTP host → konteyner | SSH/SFTP host → konteyner |
|---|---|---|
| proje1 | 300 → 80 | 400 → 22 |
| proje2 | 301 → 80 | 401 → 22 |
| proje3 | 302 → 80 | 402 → 22 |

Dolu port çiftleri atlanır; durmuş Docker konteynerlerinin portları da ayrılmış sayılır.
100 çift (HTTP 300–399, SSH 400–499) desteklenir. Aynı sunucuda bu komutun
paralel çalışmaları kilitlenir. Başka bir araç tam bu sırada port alırsa Docker
başlatma hatası bildirir; oluşturulan proje klasörü silinmez.
Ağ her zaman Docker'ın mevcut **bridge** ağıdır (`network_mode: bridge`).
Python komutu ardışık çiftleri seçer; Portainer boş portları aralıklardan seçer.
Portainer aralık eşlemeleri ile boş portları otomatik seçer;
COMPOSE_PROJECT_NAME değerini her stack için farklı girin.

```bash
ssh mahmut@SUNUCU_IP -p 400
```
SFTP: SUNUCU_IP, port 400, kullanıcı mahmut, şifre 1234.
Dosyalar `/var/www/html`, sunucuda `/home/umbrel/web/proje1/www` içindedir.
Açılışta mevcut ve yeni dosyalar için mahmut / www-data ACL yazma izinleri
ayarlanır. SFTP ile yükleme için her seferinde chmod gerekmez. ACL destekleyen
Linux dosya sistemi gerekir; desteklenmeyen disklerde açılış hata vererek durur.
Mevcut dosya sahipleri, içerikleri ve çalıştırma izinleri korunur.

## Mevcut projeyi güncelleme (veriler aynı klasörde kalır)
Önce www klasörünü yedekleyin. Eski projenin adı ve portlarıyla bir env dosyası
hazırlayın; şablon:

```dotenv
COMPOSE_PROJECT_NAME=mevcutproje
WEB_ROOT=/home/umbrel/web
HOST_HTTP_PORT=300
HOST_SSH_PORT=400
```

Yeni paketin klasöründe önce `sudo sh build-image.sh` çalıştırın; ardından env dosyasının gerçek yoluyla:

```bash
docker compose --env-file /tam/yol/mevcut.env -p mevcutproje up -d --no-build --pull never
```
Eski portlarınız farklıysa aynı kalmaları için env dosyasına eski değerleri yazın.
Var olan index.php/index.html korunur; ana sayfa yoksa bilgi sayfası eklenir.

## Bileşenler
- PHP 8.5 Apache resmi imajı; yalnızca build-image.sh ile bilinçli güncellemede en yeni 8.5 yaması.
- Node.js 24 LTS + npm, Composer 2, Git, nano, curl, wget, zip/unzip.
- PHP: mysqli, PDO MySQL, pgsql, PDO PostgreSQL, PDO SQLite, GD (JPEG/PNG/WebP),
  ZIP, Intl, mbstring, bcmath, sockets, pcntl, exif, cURL ve Redis.
- PHP'nin yerleşik JSON, OpenSSL, fileinfo, session ve diğer çekirdek modülleri.
- Paylaşılan PHP araçları: php-mqtt/client, Guzzle, PHPMailer, Dotenv, Monolog, Predis.
- MySQL/PostgreSQL CLI istemcileri; Mosquitto publish/subscribe istemcileri.
- Apache rewrite, headers, expires, HTTP/WebSocket proxy modülleri.
- Kalıcı SSH host anahtarları, restart: always, uygulama klasöründen bağımsız PHP/HTTP sağlık kontrolü.

PHP araçları www bind mount altında değildir; boş HTML klasörü bunları gizlemez.
PHP dosyanızda kullanımı:

```php
require '/opt/php-tools/vendor/autoload.php';
```
Projenizin kendi composer.json/vendor klasörü ayrıca kullanılabilir. MQTT örneği:

```bash
MQTT_HOST=192.168.1.10 php /opt/examples/mqtt-publish.php
```
Broker kullanıcı/şifre gerekiyorsa MQTT_USERNAME / MQTT_PASSWORD ortam değişkenlerini
verin. MySQL, PostgreSQL, Redis sunucuları ve MQTT broker bu web konteynerinde
başlatılmaz; mevcut sunucunuzun IP adresiyle bağlanın. Varsayılan bridge ağı
konteyner isimleri için otomatik DNS sağlamaz.

## Next.js / TSX
Node/npm hazırdır; uygulama bağımlılıkları projeye göre yüklenir:

```bash
cd /var/www/html
npx create-next-app@latest nextapp
cd nextapp
npm run build
npm run start -- --hostname 0.0.0.0
```
Next.js ayrı Node sürecidir. Eski paketteki gibi otomatik başlamaz ve 3000 portu
dışarı açılmaz. HTTP 80 üzerinden erişim için Apache reverse proxy yapılandırması
ve kalıcı süreç yöneticisi gerekir; PHP siteniz varsayılan olarak Apache'dedir.

## Boş HTML klasörü ve başlangıç logları
Sağlık kontrolü sadece konteyner içinde erişilebilen `127.0.0.1:8081` üzerindeki
PHP sayfasını kullanır. HTML klasörünün boş olması veya uygulamanın giriş ekranı
sağlık durumunu etkilemez; PHP/Apache kontrol edilir, MQTT/veritabanı kontrol edilmez.
Dışarıdan ana sayfada 403 görürseniz kendi index.php / index.html dosyanızı yükleyin.
Supervisor user=root ve global Apache ServerName localhost ayarları eklendi.

## Kontrol
```bash
docker compose --env-file /home/umbrel/web/proje1/compose.env -p proje1 exec web php -v
docker compose --env-file /home/umbrel/web/proje1/compose.env -p proje1 exec web php -m
docker compose --env-file /home/umbrel/web/proje1/compose.env -p proje1 exec web node -v
```
SFTP ile dosya oluşturup PHP üzerinden yazmayı kontrol edin. 8.1 → 8.5 geçişinde
eski uygulamanızın uyumluluğunu ayrıca kontrol edin. Next.js/proje bağımlılıkları
ve veri tabanı parolaları eski pakette bulunmuyordu; burada icat edilmedi.

## Doğrulama kapsamı
Bu paketin shell/Python sözdizimi, YAML/JSON dosyaları ve port seçim mantığı
kontrol edildi. Hazırlama ortamında Docker/PHP bulunmadığından Docker imajı
build, Composer çözümlemesi, SFTP ve MQTT canlı bağlantısı çalıştırılamadı.
İlk kurulumda internet erişimi ve Docker derlemesi gereklidir.

Resmi kaynaklar: https://www.php.net/releases/8.5/en.php
https://nodejs.org/en/download/ https://github.com/php-mqtt/client
