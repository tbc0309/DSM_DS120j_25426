#! /usr/bin/php
<?php
$pass = $_SERVER["argv"][2];
$rule = "0";
foreach (file ($_SERVER["argv"][1]) as $value) {
    if (preg_match("/var salt = \"(.*?)\"/" ,$value , $match))  {
        $salt = $match[1];
        break;
    }
}
unset($value);

while(strlen($pass) < 16) {
    $pass .= chr(1);
}

$input = $salt . $pass;
while(strlen($input) < 64) {
    $input .= chr(1);
}

$md5 = hash("md5", $input);
$login_hash = $salt . $md5;

echo $login_hash;
?>
