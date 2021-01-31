#! /usr/bin/php
<?php
$arr = preg_split("/:/", $_SERVER["argv"][1], 2);

echo "aa=".preg_replace("/=/", "%3D", trim(base64_encode($arr[0]))).
     "&ab=".preg_replace("/=/", "%3D", trim(base64_encode($arr[1])));
?>
