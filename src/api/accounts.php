<?php

require_once 'connection.php';

function getAccounts() {
	$sql = "select * FROM accounts ORDER BY name";
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

function getAccount($id) {
	$sql = "SELECT * FROM accounts WHERE id=:id";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("id", $id);
		$stmt->execute();
		$account = $stmt->fetchObject();  
		$db = null;
		echo json_encode($account); 
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

function addAccount() {
	error_log('addAccount\n', 3, '/var/tmp/php.log');
	$request = Slim::getInstance()->request();
	$account = json_decode($request->getBody());
	$sql = "INSERT INTO accounts (id, name, start_date, start_value) VALUES (:account, :name, :start_date, :start_value)";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("account", $account->account);
		$stmt->bindParam("name", $account->name);
		$stmt->bindParam("start_date", $account->startDate);
		$stmt->bindParam("start_value", $account->startValue);
		$stmt->execute();
		$account->id = $db->lastInsertId();
		$db = null;
		echo json_encode($account); 
	} catch(PDOException $e) {
		error_log($e->getMessage(), 3, '/var/tmp/php.log');
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

function updateAccount($id) {
	$request = Slim::getInstance()->request();
	$body = $request->getBody();
	$account = json_decode($body);
	$sql = "UPDATE accounts SET id=:account, name=:name, start_date=:startDate, start_value=:startValue WHERE id=:id";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("account", $account->account);
		$stmt->bindParam("name", $account->name);
		$stmt->bindParam("start_date", $account->startDate);
		$stmt->bindParam("start_value", $account->startValue);
		$stmt->bindParam("id", $id);
		$stmt->execute();
		$db = null;
		echo json_encode($account); 
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

function deleteAccount($id) {
	$sql = "DELETE FROM accounts WHERE id=:id";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("id", $id);
		$stmt->execute();
		$db = null;
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

?>