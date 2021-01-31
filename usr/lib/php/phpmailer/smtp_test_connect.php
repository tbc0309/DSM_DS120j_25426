<?php
//SMTP needs accurate times, and the PHP time zone MUST be set
require 'PHPMailerAutoload.php';
ini_set("memory_limit", "256M");
$err_log_file = "/var/log/smtp_log";
ini_set("error_log", $err_log_file);
error_reporting(E_STRICT);

function initTimezone()
{
	$timezone = date_default_timezone_get();
	if (!$timezone) {
		date_default_timezone_set("Etc/UTC");
	}
}

function fillServerCfg(&$mail, &$data)
{
	//Set the hostname of the mail server
	$mail->Host = $data["host"];
	//Set the SMTP port number - 587 for authenticated TLS, a.k.a. RFC4409 SMTP submission
	$mail->Port = $data["port"];
	//Set the encryption system to use - ssl (deprecated) or tls
	if (!isset($data["tls"]) || ("false" != $data["tls"] && "true" != $data["tls"])) {
		$data["tls"] = "true";
	}
	if (isset($data["tls"]) && "true" == $data["tls"]) {
		if (465 == $mail->Port) {
			$mail->SMTPSecure = "ssl";
		} else {
			$mail->SMTPSecure = "tls";
		}
	}
	//Whether to use SMTP authenticatioin
	if (isset($data["auth"]) && "true" == $data["auth"]) {
		$mail->SMTPAuth = true;
		$mail->AuthType = $data["auth_type"];
		$mail->Username = $data["account"];
		$mail->Password = $data["passwd"];
	}
}

function rotateLogFile()
{
	if (100*1024*1024 <= filesize($err_log_file)) {
		unlink($err_log_file);
	}
}
function main($data)
{
	initTimezone();
	rotateLogFile();
	try {
		$_data = json_decode($data, true);
		if (JSON_ERROR_NONE != json_last_error()) {
			echo "-1 input error\n";
			exit(1);
		}
		$mail = new PHPMailer(true);
		$mail->CharSet = 'utf-8';
		$mail->isSMTP();
		$mail->AllowEmpty = true;
		//Enable SMTP debugging
		// 0 = off (for production use)
		// 1 = client messages
		// 2 = client and server messages
		$mail->SMTPDebug = 0;
		$mail->Debugoutput = "error_log";
		fillServerCfg($mail, $_data);

		$mail->SMTPOptions = array(
			'ssl' => array(
				'verify_peer' => false,
				'verify_peer_name' => false,
				'allow_self_signed' => true
			)
		);
		//send the message, negative means error, 0 means success
		if ($mail->smtpConnect($mail->SMTPOptions)){
			echo "0 success\n";
		} else {
			echo "-2 connect error\n";
		}
	} catch (phpmailerException $e) {
		echo "-1 auth error\n";
	}
}
//enter point
$data = $argv[1];
main($data);
?>
