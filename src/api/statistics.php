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
	$response = Slim::getInstance()->response();
	
	$countInserted = 0;
	$returnMsg = '';
	
	if(!isset($_FILES['fileData'])) {
		$response->status(400);
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
	}
	
	if( count($csv) > 0 ) {
		date_default_timezone_set("UTC");
			
		ob_start();
		getMovings();
		$movingsJSON = ob_get_contents();
		ob_end_clean();
		
		$account = $csv[1][0];
		$lastData = getLastDataRows($account);
		
		if($lastData) {
			$lastValuta = $lastData[0]->valuta;
			//$lastValutaDD   = substr($lastValuta, 0, 2);
			//$lastValutaMM   = substr($lastValuta, 3, 2);
			//$lastValutaYYYY = "20".substr($lastValuta, 6, 2);
			$lastValutaYMD  = $lastData ? str_replace("-", "", $lastValuta) : '';
		}
		
		// *** Do not import data of the latest valuta date and check if
		//     valuta and booking exists... 
		//var_dump($csv);
		$csv = getImportableData($csv);
		//echo "\n\n\n******************************\n\n\n";
		//var_dump($csv);
		//return;
		
		$prevValuta = '';
		
		// *** process data reverse...
		for ($i=count($csv)-1 ; $i >= 0; $i-- ) {
			$line = $csv[$i];
			$statObj = array();
			$doImport = true;
			
			// *** FIELDS: account,booking,valuta,type,text,recipient,recipient_account,recipient_bankcode,value,currency,info
			
			$statObj['account']            = $line[0];
			
			$valuta = $line[2];
			$valutaDD   = substr($valuta, 0, 2);
			$valutaMM   = substr($valuta, 3, 2);
			$valutaYYYY = "20".substr($valuta, 6, 2);
			$valutaYMD  = $valutaYYYY.$valutaMM.$valutaDD;
			$valutaTS = strtotime($valutaYYYY.$valutaMM.$valutaDD);
			$statObj['valuta']             = date("Y-m-d", $valutaTS);
			
			$booking = $line[1];
			$bookingDD = substr($booking, 0, 2);
			$bookingMM = substr($booking, 3, 2);
			$bookingTS = strtotime($valutaYYYY.$bookingMM.$bookingDD);
			$statObj['booking']            = date("Y-m-d", $bookingTS);
			
			$statObj['type']               = $line[3];
			$statObj['text']               = $line[4];
			$statObj['recipient']          = $line[5];
			$statObj['recipient_account']  = $line[6];
			$statObj['recipient_bankcode'] = $line[7];
			$statObj['value']              = str_replace(",", ".", $line[8]);
			$statObj['currency']           = $line[9];
			$statObj['info']               = $line[10];
			
			// *** prevent duplicate data...
			if( isset($lastValutaYMD) && $valutaYMD <= $lastValutaYMD) {
				//echo "\ncanceled import: valutaYMD:$valutaYMD < lastValutaYMD:$lastValutaYMD";
				$doImport = false;
			}
			
			if( $doImport ) {
				$movings = json_decode($movingsJSON);
				//var_dump($movings);
				foreach($movings as $moving) {
					//echo "\nchecking for'".$moving->matches."'";
					$firstDayOfMonthTS = mktime(1,1,1,$valutaMM,1,$valutaYYYY);
					$lastDayOfMonthTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY);
					$toleranceLimitTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY)-(86400 * $moving->tolerance);
					if( $valutaTS <= $lastDayOfMonthTS && $valutaTS >= $toleranceLimitTS) {
						$checkFields = array('type','text');
						foreach($checkFields as $checkField) {
							// echo "<br>CHECK: reg_exp:".$moving->matches." - field:".$statObj[$checkField];
							if( preg_match("/".$moving->matches."/i", $statObj[$checkField], $matches) ) {
								//echo "\nadding '".$moving->add_month."' month for:".$moving->matches;
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
				
				$returnMsg = saveStatisticData($statObj);
				
				if( $response->status() != 200 ) {
					break;
				} else {
					$countInserted++;
				}
			}
			
			//echo implode("|",$line);
			//print_r($statObj);
		}
	}
	
	// TODO return count of inserted
	if( $response->status() != 200 ) {
		echo '{"error":"'.$returnMsg.'"}';
	} else {
		echo '{"countInserted":'.$countInserted.'}';
	}
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

function getImportableData($csv) {
	$returnData = array();
	$latestImpDate = '';
	for ($i=1 ; $i < count($csv); $i++ ) {
		$row = $csv[$i];
		
		$booking = $row[1];
		$valuta  = $row[2];
		
		if( $booking && $valuta ) {
			$valutaDD   = substr($valuta, 0, 2);
			$valutaMM   = substr($valuta, 3, 2);
			$valutaYYYY = "20".substr($valuta, 6, 2);
			$valutaYMD  = $valutaYYYY.$valutaMM.$valutaDD;
			
			if( $latestImpDate != '' && $valutaYMD != $latestImpDate ) {
				array_push($returnData, $row);
			}
			
			if( $latestImpDate == '') {
				$latestImpDate = $valutaYMD;
			}
		}
	}
	
	return $returnData;
}

function saveStatisticData($data) {
	$response = Slim::getInstance()->response();
	
	try {
		$db = getConnection();
	} catch(PDOException $e) {
		$response->status(400);
		return '"error":{"text":'. $e->getMessage() .'}}'; 
	}
	
	$sql = "INSERT INTO csvdata (account, booking, valuta, type, text, recipient, recipient_account, recipient_bankcode, value, currency, info, month)
						VALUES (:account, :booking, :valuta, :type, :text, :recipient, :recipient_account, :recipient_bankcode, :value, :currency, :info, :month)";
	
	try {
		$stmt = $db->prepare($sql);
		
		foreach($data as $key => &$val) {
			$stmt->bindParam($key, $val);
		}
		$stmt->execute();
	} catch(PDOException $e) {
		error_log($e->getMessage(), 3, 'php.log');
		$response->status(400);
		return '"error":{"text":'. $e->getMessage() .',db:'.var_export($data, true).'}';
	}
	
	$db = null;
	$response->status(200);
	return "ok";
}

?>