<?php

require_once 'connection.php';
require_once 'movings.php';
require_once 'categories.php';


function getStatisticsMonths() {
	$sql = "SELECT h.month as name, h.sum_value as value_h, s.sum_value as value_s
			FROM
			(SELECT month, SUM(value) sum_value
			FROM csvdata
			WHERE value >= 0
			GROUP BY month) h,
			(SELECT month, SUM(value) sum_value
			FROM csvdata
			WHERE value < 0
			GROUP BY month) s
			where h.month = s.month
			ORDER BY h.month DESC";
	try {
		$db = getConnection();
		$stmt = $db->query($sql);  
		$accounts = $stmt->fetchAll(PDO::FETCH_OBJ);
		$db = null;
		echo json_encode($accounts);
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

function addStatisticData() {
	error_log('addStatisticData\n', 3, 'php.log');
	$request = Slim::getInstance()->request();
	
	if(!isset($_FILES['fileData'])) {
		echo "No files uploaded!!";
		return;
	}
	
	$tmpFilePath = $_FILES['fileData']['tmp_name'];
	
	$csv = array();
	if($tmpFilePath) {
		
		$lines = file($tmpFilePath, FILE_IGNORE_NEW_LINES);
		foreach ($lines as $key => $value) {
			$csv[$key] = str_getcsv($value, ';');
		}
		//print_r($csv);
	}
	
	if( count($csv) > 0 ) {
		date_default_timezone_set("UTC");
			
		ob_start();
		getMovings();
		$movingsJSON = ob_get_contents();
		ob_end_clean();
		
		
		$lastData = getLastDataRows($csv[0][0]);
		$lastValuta = $lastData[0]->valuta;
		$lastValutaDD   = substr($lastValuta, 0, 2);
		$lastValutaMM   = substr($lastValuta, 3, 2);
		$lastValutaYYYY = "20".substr($lastValuta, 6, 2);
		# if the are no values in db the earliest import date is Jan. 1980
		$lastValutaYMD      = $lastData ? $lastValutaYYYY.$lastValutaMM.$lastValutaDD : '198001';
		
		//var_dump($lastData);
		//return;
		
		for ($i=1 ; $i < count($csv); $i++ ) {
			$line = $csv[$i];
			$statObj = array();
			$doImport = true;
			
			// *** FIELDS: account,booking,valuta,type,text,recipient,recipient_account,recipient_bankcode,value,currency,info
			
			$valuta = $line[2];
			
			$statObj['account']            = $line[0];
			
			$valutaDD   = substr($valuta, 0, 2);
			$valutaMM   = substr($valuta, 3, 2);
			$valutaYYYY = "20".substr($valuta, 6, 2);
			$valutaYMD  = $valutaYYYY.$valutaMM.$valutaDD;
			$valutaTS = strtotime($valutaYYYY.$valutaMM.$valutaDD);
			$statObj['valuta']             = date("Y-m-d", $valutaTS);
			
			$booking = $line[2];
			$bookingDD = substr($valuta, 0, 2);
			$bookingMM = substr($valuta, 3, 2);
			$bookingTS = strtotime($valutaYYYY.$bookingMM.$bookingDD);
			$statObj['booking']            = date("Y-m-d", $bookingTS);
			
			$statObj['type']               = $line[3];
			$statObj['text']               = $line[4];
			$statObj['recipient']          = $line[5];
			$statObj['recipient_account']  = $line[6];
			$statObj['recipient_bankcode'] = $line[7];
			$statObj['value']              = $line[8];
			$statObj['currency']           = $line[9];
			$statObj['info']               = $line[10];
			
			if( $valutaYMD < $lastValutaYMD) {
				$doImport = false;
			} else if( $valutaYMD == $lastValutaYMD) {
				$checkFields = array('valuta','booking','type','text','recipient_account');
				$identicalData = true;
				foreach($checkFields as $checkField) {
					if($lastData[$checkField] != $statObj[$checkField]) {
						$identicalData = false;
						break;
					}
				}
				$doImport = !$identicalData;
			}
			
			if( $doImport ) {
				$movings = json_decode($movingsJSON);
				//var_dump($movings);
				foreach($movings as $moving) {
					echo "<br>checking for'".$moving->matches."'";
					$firstDayOfMonthTS = mktime(1,1,1,$valutaMM,1,$valutaYYYY);
					$lastDayOfMonthTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY);
					$toleranceLimitTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY)-(86400 * $moving->tolerance);
					if( $valutaTS <= $lastDayOfMonthTS && $valutaTS >= $toleranceLimitTS) {
						$checkFields = array('type','text');
						foreach($checkFields as $checkField) {
							// echo "<br>CHECK: reg_exp:".$moving->matches." - field:".$statObj[$checkField];
							if( preg_match("/".$moving->matches."/i", $statObj[$checkField], $matches) ) {
								var_dump($matches);
								echo "adding '".$moving->add_month."' month for:".$moving->matches;
								$statObj['month'] = date("Ym", strtotime("+".$moving->add_month." month ", $firstDayOfMonthTS));
								break;
							}
						}
						if( isset($statObj['month']) ) {
							break;
						}
					}
				}
				
				if( !isset($statObj['month']) ) {
					$statObj['month'] = $valutaYYYY.$valutaMM;
				}
				
				$msg = saveStatisticData($statObj);
			}
			
			//echo implode("|",$line);
			//print_r($statObj);
		}
	}
	
	// TODO return count of inserted
	echo '{"message":"'.$msg.'"}';
}

// ********************************

function getLastDataRows($account) {
	$sql = "SELECT valuta, booking, type, text, recipient_account
			FROM csvdata
			where valuta = ( SELECT MAX(VALUTA) FROM CSVDATA WHERE account=:account )";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("account", $account);
		$stmt->execute();
		$lastData = $stmt->fetchAll(PDO::FETCH_OBJ);
		$db = null;
		return $lastData;
	} catch(PDOException $e) {
		return 'error:'. $e->getMessage();
	}
}

function saveStatisticData($data) {
	$response = Slim::getInstance()->response();
	
	try {
		$db = getConnection();
	} catch(PDOException $e) {
		$response->status(400);
		return '"error":{"text":'. $e->getMessage() .'}}'; 
	}
	
	foreach($data as $row) {
		$sql = "INSERT INTO csvdata (account, booking,valuta, type, text, recipient, recipient_account, recipient_bankcode, value, currency, info, month)
							VALUES (:account, :booking, :valuta, :type, :text, :recipient, :recipient_account, :recipient_bankcode, :value, :currency, :info, :month)";
		try {
			$stmt = $db->prepare($sql);
			
			foreach($row as $key => $val) {
				$stmt->bindParam($key, $val);
			}
			$stmt->execute();
		} catch(PDOException $e) {
			error_log($e->getMessage(), 3, '/var/tmp/php.log');
			$response->status(400);
			return '"error":{"text":'. $e->getMessage() .'}}';
		}
	}
	
	$db = null;
	$response->status(200);
	return "ok";
}

?>