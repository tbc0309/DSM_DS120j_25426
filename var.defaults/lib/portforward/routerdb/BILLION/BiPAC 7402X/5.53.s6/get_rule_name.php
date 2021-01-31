#! /usr/bin/php
<?php
$file = file ($_SERVER["argv"][1]) or exit(-1);
foreach ($file as $value) {
    if (preg_match('/name="(.*?)_node"/' ,$value , $match))  {
        echo preg_replace("/\+/", "%20", urlencode($match[1]));
        return;
	}
}
echo "";
?>
