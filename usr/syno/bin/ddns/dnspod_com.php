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
    echo "badparam";
    exit();
}

// only for IPv4 format
if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
    echo "badparam";
    exit();
}

$url = 'https://api.dnspod.com/Auth';
$post = array(
    'login_email'=>$account,
    'login_password'=>$pwd,
    'format'=>'json'
);
$req = curl_init();
$options = array(
  CURLOPT_URL=>$url,
  CURLOPT_HEADER=>0,
  CURLOPT_VERBOSE=>0,
  CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_USERAGENT=>'Mozilla/4.0 (compatible;)',
  CURLOPT_POST=>true,
  CURLOPT_POSTFIELDS=>http_build_query($post),
);
curl_setopt_array($req, $options);
$res = curl_exec($req);
$json = json_decode($res, true);

if (1 != $json['status']['code']) {
    //print_r($json['status']['code']);
    echo 'badauth';
    curl_close($req);
    exit();
}
$user_token = $json['user_token'];

$url = 'https://api.dnspod.com/Domain.List';
$post = array(
    'user_token'=>$user_token,
    'format'=>'json'
);
$options = array(
  CURLOPT_URL=>$url,
  CURLOPT_HEADER=>0,
  CURLOPT_VERBOSE=>0,
  CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_USERAGENT=>'Mozilla/4.0 (compatible;)',
  CURLOPT_POST=>true,
  CURLOPT_POSTFIELDS=>http_build_query($post),
);
curl_setopt_array($req, $options);
$res = curl_exec($req);
$json = json_decode($res, true);

if (1 != $json['status']['code']) {
    echo 'Get Domain List failed';
    curl_close($req);
    exit();
}
$domain_total = $json['info']['domain_total'];

$domainID = -1;
for ($i = 0; $i < $domain_total; $i++) {
    $domain_tmp = $json['domains'][$i]['name'];
    if (strlen($domain_tmp) != 0 && $domain_tmp === substr($hostname, -strlen($domain_tmp))) {
        $domainID = $json['domains'][$i]['id'];
        $domain = $domain_tmp;
        if (strlen($hostname)>strlen($domain)) {
            $subDomain = substr($hostname, 0, strlen($hostname)-strlen($domain_tmp)-1);
        } else {
            $subDomain = '@';
        }
        break;
    }
}

if ($domainID === -1) {
    echo 'nohost';
    exit();
}

$url = 'https://api.dnspod.com/Record.List';
$post = array(
    'user_token'=>$user_token,
    'domain_id'=>$domainID,
    'format'=>'json'
);
$options = array(
  CURLOPT_URL=>$url,
  CURLOPT_HEADER=>0,
  CURLOPT_VERBOSE=>0,
  CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_USERAGENT=>'Mozilla/4.0 (compatible;)',
  CURLOPT_POST=>true,
  CURLOPT_POSTFIELDS=>http_build_query($post),
);
curl_setopt_array($req, $options);
$res = curl_exec($req);
$json = json_decode($res, true);

if (1 != $json['status']['code']) {
    echo 'Get Record List failed';
    curl_close($req);
    exit();
}

$recordID = -1;
$record_total = $json['info']['record_total'];
for ($i = 0; $i < $record_total; $i++) {
    if (($json['records'][$i]['name'] === $subDomain) and ($json['records'][$i]['type'] === 'A')) {
        $recordID = $json['records'][$i]['id'];
        break;
    }
}

if ($recordID === -1) {
    echo 'nohost';
    curl_close($req);
    exit();
}

$url = 'https://api.dnspod.com/Record.Modify';
$post = array(
    'user_token'=>$user_token,
    'domain_id'=>$domainID,
    'record_id'=>$recordID,
    'sub_domain'=>$subDomain,
    'value'=>$ip,
    'record_type'=>'A',
    'record_line'=>'default',
    'format'=>'json'
);
$options = array(
  CURLOPT_URL=>$url,
  CURLOPT_HEADER=>0,
  CURLOPT_VERBOSE=>0,
  CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_USERAGENT=>'Mozilla/4.0 (compatible;)',
  CURLOPT_POST=>true,
  CURLOPT_POSTFIELDS=>http_build_query($post),
);
curl_setopt_array($req, $options);
$res = curl_exec($req);
curl_close($req);
$json = json_decode($res, true);

if (1 != $json['status']['code']) {
    echo 'Update Record failed';
    exit();
}

echo 'good';

