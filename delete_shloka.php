<?php
session_start();
require 'vendor/autoload.php';

if (!isset($_SESSION['role']) || $_SESSION['role'] != 'editor') {
    header('Location: index.php');
    exit();
}

$client = new MongoDB\Client("mongodb://localhost:27017");
$collection = $client->shloka_app->shlokas;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $shloka_id = new MongoDB\BSON\ObjectId($_POST['shloka_id']);

    $collection->deleteOne(['_id' => $shloka_id]);
    header('Location: editorial.php');
}
?>
