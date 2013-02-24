<?php

require 'Slim/Slim.php';
require 'accounts.php';
require 'statistics.php';

$app = new Slim();

# ********** Accounts **********
$app->get('/accounts', 'getAccounts');
$app->get('/accounts/:id',	'getAccount');
# ******************************

# ********** Statistics*********
$app->get('/statistics/months', 'getStatisticsMonths');
$app->post('/statistics',	'addStatisticData');
# ******************************
$app->run();

?>
