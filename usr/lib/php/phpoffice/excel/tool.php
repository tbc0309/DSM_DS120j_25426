#!/usr/bin/php
<?php

function IsFileFormatValid($format) {
	$whiteList = array("Excel2007", "Excel5", "OOCalc", "SYLK", "Excel2003XML", "Gnumeric");
	return in_array($format, $whiteList);
}

function Usage()
{
	echo "Copyright (c) 2000-2015 Synology Inc. All rights reserved.\n";
	echo "Usage: " . basename(__FILE__) . " [options]\n";
	echo "  -i<string>    : input file path\n";
	echo "  -f<string>    : input file format(Excel2007, Excel5, OOCalc, SYLK, Excel2003XML, Gnumeric) case-sensitive\n";
	echo "  -h            : show help\n";
}

// Check args
$optCfg = "i:f:h::";
$options = getopt($optCfg);
$format = empty($options['f']) ? "" : $options['f'];
$inputPath = empty($options['i']) ? "" : $options['i'];

if (isset($options['h']) || empty($format) || empty($inputPath)) {
	Usage();
	exit(1);
}

if (!IsFileFormatValid($format)) {
	echo "wrong file format: " . $format . " \n";
	exit(1);
}

// Load PHPExcel modules
require_once dirname(__FILE__) . '/PHPExcel/IOFactory.php';

// Load input file with specified reader
$objReader = PHPExcel_IOFactory::createReader($format);
$objPHPExcel = $objReader->load($inputPath);

// Create cvs writer
$objWriter = PHPExcel_IOFactory::createWriter($objPHPExcel, 'CSV');
$objWriter->setDelimiter(', ')->setEnclosure('')->setLineEnding("\n")->setPreCalculateFormulas(false);

// Output each sheet
$sheetCount = $objPHPExcel->getSheetCount();
for ($i = 0; $i < $sheetCount; $i++) {
	if (0 !== $i) {
		echo "---\n";
	}
	$objWriter->setSheetIndex($i);
	$objWriter->save('php://stdout');
}

?>
