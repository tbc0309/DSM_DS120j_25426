#! /usr/bin/php
<?php
$file = file ($_SERVER["argv"][1]) or exit(-1);
foreach ($file as $value) {
    #<INPUT type="hidden" name="syno0_Interface" value="ipwan">
    if (preg_match('/name=".*?_Interface" value="(.*?)">/' ,$value , $match))  {
	    echo $match[1];
        return;
	}
}
echo "";
?>
