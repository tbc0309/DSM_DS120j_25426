#! /usr/bin/php
<?php
$file = file_get_contents($_SERVER["argv"][1]);
$count = 0;
if (preg_match("/var VSList = \[(.*)\];/" , $file, $match))  {
    if (preg_match('/(\[".*", ".*", ".*", ".*", ".*", ".*"\])/', $match[1], $rules)) {
        $count = count($rules) - 1;
    }
}
exit($count);
?>
