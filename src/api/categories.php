<?php

require_once 'connection.php';

function getCategories() {
	$sql = "select * FROM categories ORDER BY name";
	try {
		$db = getConnection();
		$stmt = $db->query($sql);  
		$categories = $stmt->fetchAll(PDO::FETCH_OBJ);
		$db = null;
		echo json_encode($categories);
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}

function getCategory($id) {
	$sql = "SELECT * FROM accounts WHERE account=:id";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);  
		$stmt->bindParam("id", $id);
		$stmt->execute();
		$category = $stmt->fetchObject();  
		$db = null;
		echo json_encode($category); 
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}'; 
	}
}


?>