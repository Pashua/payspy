<?php

require_once 'connection.php';

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
	
	//print_r($_FILES);
	if(!isset($_FILES['fileData'])) {
		echo "No files uploaded!!";
		return;
	}
	
	$tmpFilePath = $_FILES['fileData']['tmp_name'];
	
	if($tmpFilePath) {
		$csv = array();
		
		$lines = file($tmpFilePath, FILE_IGNORE_NEW_LINES);
		foreach ($lines as $key => $value) {
			$csv[$key] = str_getcsv($value, ';');
		}
		print_r($csv);
	}
	
	# validate the data here....
	return;
	
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
}

?>