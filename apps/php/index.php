<?php
$appName = "php";
$port = (int) (getenv("APP_PORT") ?: 5000);
$mysqlHost = getenv("MYSQL_HOST") ?: "";
$mysqlPort = (int) (getenv("MYSQL_PORT") ?: 3306);
$redisHost = getenv("REDIS_HOST") ?: "";
$redisPort = (int) (getenv("REDIS_PORT") ?: 6379);

function checkTcp($host, $port, $timeout = 2) {
    $conn = @fsockopen($host, $port, $errno, $errstr, $timeout);
    if ($conn) {
        fclose($conn);
        return true;
    }
    return false;
}

$mysqlReachable = checkTcp($mysqlHost, $mysqlPort);
$redisReachable = checkTcp($redisHost, $redisPort);

$body = array(
    "app" => $appName,
    "hostname" => gethostname(),
    "mysql" => array("host" => $mysqlHost, "port" => $mysqlPort, "reachable" => $mysqlReachable),
    "redis" => array("host" => $redisHost, "port" => $redisPort, "reachable" => $redisReachable),
);

header("Content-Type: application/json");
echo json_encode($body, JSON_PRETTY_PRINT);
