#! /usr/bin/php
<?php
foreach (file ($_SERVER["argv"][1]) as $value) {
    if (preg_match('/var challenge = "([^"]*)";/' ,$value , $match))  {
        echo $match[1];
        return;
	}
}
echo "";
?>
