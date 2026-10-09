<?php
// CLI: MQTT_HOST=192.168.1.10 php /opt/examples/mqtt-publish.php
require '/opt/php-tools/vendor/autoload.php';
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
$settings = (new ConnectionSettings())
    ->setUsername(getenv('MQTT_USERNAME') ?: null)
    ->setPassword(getenv('MQTT_PASSWORD') ?: null);
$mqtt = new MqttClient(getenv('MQTT_HOST') ?: '127.0.0.1', (int)(getenv('MQTT_PORT') ?: 1883), 'php-' . bin2hex(random_bytes(6)));
$mqtt->connect($settings, true);
$mqtt->publish('farming4/test', json_encode(['message'=>'Merhaba','time'=>date(DATE_ATOM)]), 0);
$mqtt->disconnect();
