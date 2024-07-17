<?php
session_start();
require 'vendor/autoload.php';

if (!isset($_SESSION['role']) || $_SESSION['role'] != 'admin') {
    header('Location: index.php');
    exit();
}

$client = new MongoDB\Client("mongodb://localhost:27017");
$collection = $client->shloka_app->users;

$users = $collection->find()->toArray();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <h2>Admin Dashboard</h2>
        <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($users as $user): ?>
                <tr>
                    <td><?php echo $user['name']; ?></td>
                    <td><?php echo $user['email']; ?></td>
                    <td><?php echo $user['role']; ?></td>
                    <td>
                        <form action="change_role.php" method="post">
                            <input type="hidden" name="user_id" value="<?php echo $user['_id']; ?>">
                            <select name="role" onchange="this.form.submit()">
                                <option value="learner" <?php echo $user['role'] == 'learner' ? 'selected' : ''; ?>>Learner</option>
                                <option value="editor" <?php echo $user['role'] == 'editor' ? 'selected' : ''; ?>>Editor</option>
                                <option value="admin" <?php echo $user['role'] == 'admin' ? 'selected' : ''; ?>>Admin</option>
                            </select>
                        </form>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        
        <h3>Import Shlokas</h3>
        <form action="import_shlokas.php" method="post" enctype="multipart/form-data">
            <div class="form-group">
                <label for="file">Select Excel/CSV File:</label>
                <input type="file" class="form-control" id="file" name="file" accept=".csv, .xlsx" required>
            </div>
            <button type="submit" class="btn btn-primary">Import Shlokas</button>
        </form>
    </div>
</body>
</html>
