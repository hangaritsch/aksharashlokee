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
    $akshara = $_POST['akshara'];
    $content = $_POST['content'];

    $collection->insertOne(['akshara' => $akshara, 'content' => $content]);
    header('Location: editorial.php');
}

$shlokas = $collection->find()->toArray();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editorial Dashboard</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <h2>Editorial Dashboard</h2>
        <form action="editorial.php" method="post">
            <div class="form-group">
                <label for="akshara">Akshara:</label>
                <input type="text" class="form-control" id="akshara" name="akshara" required>
            </div>
            <div class="form-group">
                <label for="content">Content:</label>
                <textarea class="form-control" id="content" name="content" rows="3" required></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Add Shloka</button>
        </form>
        <hr>
        <h3>Existing Shlokas</h3>
        <ul class="list-group">
            <?php foreach ($shlokas as $shloka): ?>
            <li class="list-group-item">
                <strong><?php echo $shloka['akshara']; ?></strong>: <?php echo $shloka['content']; ?>
                <form action="delete_shloka.php" method="post" class="float-right">
                    <input type="hidden" name="shloka_id" value="<?php echo $shloka['_id']; ?>">
                    <button type="submit" class="btn btn-danger btn-sm">Delete</button>
                </form>
            </li>
            <?php endforeach; ?>
        </ul>
    </div>
</body>
</html>
