#!/usr/bin/php -d open_basedir=/usr/syno/bin/ddns
<?php

if ($argc !== 5) {
    echo 'badparam';
    exit();
}

$account = $argv[1];
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

$url = 'https://nic.changeip.com/nic/update?hostname='.$hostname.'&myip='.$ip.'&system=dyndns';

$req = curl_init();
curl_setopt($req, CURLOPT_URL, $url);
curl_setopt($req, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
curl_setopt($req, CURLOPT_USERPWD, $account.':'.$pwd);
$res = curl_exec($req);
curl_close($req);


