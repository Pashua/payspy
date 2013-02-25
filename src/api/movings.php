<?php

require_once 'connection.php';

function getMovings() {
	$sql = "select * FROM movings ORDER BY id";
	try {
		$db = getConnection();
		$stmt = $db->query($sql);
		$movings = $stmt->fetchAll(PDO::FETCH_OBJ);
		$db = null;
		echo json_encode($movings);
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}';
	}
}

function getMoving($id) {
	$sql = "SELECT * FROM movings WHERE id=:id";
	try {
		$db = getConnection();
		$stmt = $db->prepare($sql);
		$stmt->bindParam("id", $id);
		$stmt->execute();
		$moving = $stmt->fetchObject();
		$db = null;
		echo json_encode($moving);
	} catch(PDOException $e) {
		echo '{"error":{"text":'. $e->getMessage() .'}}';
	}
}


?>