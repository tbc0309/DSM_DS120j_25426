<?php
//SMTP needs accurate times, and the PHP time zone MUST be set
require 'PHPMailerAutoload.php';
ini_set("memory_limit", "256M");
$err_log_file = "/var/log/smtp_log";
ini_set("error_log", $err_log_file);
error_reporting(E_STRICT);

function getErrorCode($code, $msg)
{
	$errorMap = array(
		'SMTP Error: Could not authenticate.',
		'SMTP Error: Could not connect to SMTP host.',
		'SMTP Error: data not accepted.',
		'The following From address failed: ',
		'Invalid address',
		'Disabled: The following recipients failed: ',
		'SMTP connect() failed.',
		'SMTP server error: '
	);
	//550 server error, return unknow error code -10
	if (550 == $code) {
		return -10;
	}
	for ($i=0;$i<sizeof($errorMap);$i++) {
		if (false !== strpos($msg, $errorMap[$i])) {
			//handle AOL 512 data not accepted, because of blocked words(like: .com .org)
			if (521 == $code) {
				return -9;
			} else {
				return -$i-1;
			}
		}
	}
	return -10;
}

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

function fillMailContent(&$mail, &$data)
{
	$i = 0;
	try {
		if (isset($data["sender_account"]) && "" != $data["sender_account"]) {
			if (isset($data["sender_name"]) && ""!=$data["sender_name"]){
				$mail->setFrom($data["sender_account"], $data["sender_name"]);
			} else {
				$mail->setFrom($data["sender_account"]);
			}
		} else {
			if (isset($data["sender_name"]) && ""!=$data["sender_name"]){
				$mail->setFrom($data["account"], $data["sender_name"]);
			} else {
				$mail->setFrom($data["account"]);
			}
		}
		if (isset($data["cc"])) {
			for ($i=0; $i< sizeof($data["cc"]); $i++){
				if ("" != $data["cc"][$i]) {
					$mail->addCC($data["cc"][$i]);
				}
			}
		}
		if (isset($data["to"])) {
			for ($i=0; $i<sizeof($data["to"]); $i++){
				if ("" != $data["to"][$i]) {
					$mail->addAddress($data["to"][$i]);
				}
			}
		}
		if (isset($data["subject"])) {
			$mail->Subject = $data["subject"];
		}
		if (isset($data["body"])) {
			$mail->msgHTML($data["body"]);
		}
		if (isset($data["ics"]) && '' != $data["ics"]) {
			$mail->Ical = $data["ics"];
			addICSFile($mail, $data["ics"]);
		}
		//Attach files
		if (isset($data["attachment"])) {
			for ($i=0; $i<sizeof($data["attachment"]); $i++) {
				if ("" != $data["attachment"][$i] && preg_match("/^\/volume*/", $data["attachment"][$i]["path"])) {
					$mail->addAttachment($data["attachment"][$i]["path"], $data["attachment"][$i]["name"]);
				}
			}
		}
		if (isset($data["inline_attachment"])) {
			for ($i=0; $i<sizeof($data["inline_attachment"]); $i++) {
				if ("" != $data["inline_attachment"][$i]) {
					if ("" != $data["inline_attachment"][$i]["name"]) {
						$mail->addEmbeddedImage($data["inline_attachment"][$i]["path"], $data["inline_attachment"][$i]["cid"], $data["inline_attachment"][$i]["name"]);
					} else {
						$mail->addEmbeddedImage($data["inline_attachment"][$i]["path"], $data["inline_attachment"][$i]["cid"]);
					}
				}
			}
		}
	} catch (phpmailerException $e) {
		throw $e;
	}
}
function rotateLogFile()
{
	if (100*1024*1024 <= filesize($err_log_file)) {
		unlink($err_log_file);
	}
}
function addICSFile (&$mail, &$ics)
{
	$mail->addStringAttachment($ics, 'invite.ics', '8BIT', 'application/ics');
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
		fillMailContent($mail,$_data);

		$mail->SMTPOptions = array(
			'ssl' => array(
				'verify_peer' => false,
				'verify_peer_name' => false,
				'allow_self_signed' => true
			)
		);
		//send the message, negative means error, 0 means success
		$mail->send();
		echo "0 success\n";
	} catch (phpmailerException $e) {
		$err = $mail->getError();
		$detailMsg = $e->getMessage();
		if (null != $err && is_array($err)) {
			if (isset($err["detail"])) {
				$detailMsg = $err["detail"];
			}
			error_log(implode(" ", $err));
		}
		echo getErrorCode($mail->getErrorCode(), $e->getMessage()) . " " . $detailMsg . "\n";
	}
}
//enter point
$data = $argv[1];
main($data);
?>
