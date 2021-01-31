#!/usr/bin/php -d open_basedir=/usr/syno/bin/ddns
<?php

if ($argc !== 5) {
    echo 'badparam';
    exit();
}

$account = (string)$argv[1];
$pwd = (string)$argv[2];
$hostname = (string)$argv[3];
$ip = (string)$argv[4];

// check the hostname contains '.'
if (strpos($hostname, '.') === false) {
    echo 'badparam';
    exit();
}

// only for IPv4 format
if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
    echo "badparam";
    exit();
}

$url = 'http://update.dnsexit.com/RemoteUpdate.sv?login='.$account.'&password='.$pwd.'&host='.$hostname.'&myip='.$ip;

$req = curl_init();
curl_setopt($req, CURLOPT_URL, $url);
$res = curl_exec($req);
curl_close($req);


