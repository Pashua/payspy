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
$app->get('/statistics/months/:month/categories', 'getStatisticsCategories');
$app->get('/statistics/months/:month/categories/:category/rawdata', 'getStatisticsRawdata');
$app->get('/statistics/months/:month/sticky', 'getStickyRawdata');
$app->put('/statistics/raw/:id', 'markStatisticData');
$app->post('/statistics/:account', 'addStatisticData');
# ******************************
$app->run();

?>
