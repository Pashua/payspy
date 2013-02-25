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
	error_log('addaddStatisticData\n', 3, 'php.log');
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
			
		ob_start();
		getMovings();
		$movingsJSON = ob_get_contents();
		ob_end_clean();
		
		date_default_timezone_set("UTC");
		for ($i=1 ; $i < count($csv); $i++ ) {
			$line = $csv[$i];
			
			// FIELDS: account,booking,valuta,type,text,recipient,recipient_account,recipient_bankcode,value,currency,info
			
			$statObj = array();
			$statObj['account']            = $line[0];
			
			$valuta = $line[2];
			$valutaDD   = substr($valuta, 0, 2);
			$valutaMM   = substr($valuta, 3, 2);
			$valutaYYYY = "20".substr($valuta, 6, 2);
			$valutaTS = strtotime($valutaYYYY.$valutaMM.$valutaDD);
			$statObj['valuta']             = date("Y-d-mTG:i:sz", $valutaTS);
			
			$booking = $line[2];
			$bookingDD = substr($valuta, 0, 2);
			$bookingMM = substr($valuta, 3, 2);
			$bookingTS = strtotime($valutaYYYY.$bookingMM.$bookingDD);
			$statObj['booking']            = date("Y-d-mTG:i:sz", $bookingTS);
			
			$statObj['type']               = $line[3];
			$statObj['text']               = $line[4];
			$statObj['recipient']          = $line[5];
			$statObj['recipient_account']  = $line[6];
			$statObj['recipient_bankcode'] = $line[7];
			$statObj['value']              = $line[8];
			$statObj['currency']           = $line[9];
			$statObj['info']               = $line[10];
			
			
			$movings = json_decode($movingsJSON);
			//var_dump($movings);
			foreach($movings as $moving) {
				echo "<br>checking for'".$moving->matches."'";
				$lastDayOfMonthTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY);
				$toleranceLimitTS = mktime(1,1,1,$valutaMM+1,0,$valutaYYYY)-(86400 * $moving->tolerance);
				if( $valutaTS <= $lastDayOfMonthTS && $valutaTS >= $toleranceLimitTS) {
					$checkFields = array('type','text');
					foreach($checkFields as $checkField) {
						// TODO fix preg_match !!!
						if( preg_match("/".$moving->matches."/i", $checkField, $matches) ) {
							var_dump($matches);
							echo "adding '".$moving->add_month."' month for:".$moving->matches;
							$statObj['month'] = date("Y-m", strtotime($moving->add_month." month",$valutaTS));
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
			
			echo implode("|",$line);
			print_r($statObj);
		}
	}
	
	return;
	
	/*
	$sql = "INSERT INTO csvdata (account, booking,valuta, type, text, recipient, recipient_account, recipient_bankcode, value, currency, info,
								month, category) VALUES (:name, :grapes, :country, :region, :year, :description)";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("name", $wine->name);
		$stmt->bindParam("grapes", $wine->grapes);
		$stmt->bindParam("country", $wine->country);
		$stmt->bindParam("region", $wine->region);
		$stmt->bindParam("year", $wine->year);
		$stmt->bindParam("description", $wine->description);
		$stmt->execute();
		$wine->id = $db->lastInsertId();
		$db = null;
		echo json_encode($wine); 
	} catch(PDOException $e) {
		error_log($e->getMessage(), 3, '/var/tmp/php.log');
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
	*/
}

?>