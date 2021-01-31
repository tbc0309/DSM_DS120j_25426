#! /usr/bin/php
<?php
$value = file_get_contents($_SERVER["argv"][1]);

if (preg_match("#<virtual_server>(.*?)</virtual_server>#is", $value, $i)) {
    if (preg_match("#<row_info>(.*?)</row_info>#is", $i[1], $j)) {
        if (preg_match("#<rowid>([^<]*?)</rowid>#is", $j[1], $k)) {
            echo $k[1];
            exit(0);
        }
    }
}

echo "-1";
?>
