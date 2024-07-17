<?php
session_start();
require 'vendor/autoload.php';

if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'editor') {
    header('Location: login.php');
    exit();
}

$client = new MongoDB\Client("mongodb://localhost:27017");
$shlokasCollection = $client->shloka_app->shlokas;

$shlokas = $shlokasCollection->find()->toArray();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['delete_shloka'])) {
        $shlokaId = $_POST['shloka_id'];
        $shlokasCollection->deleteOne(['_id' => new MongoDB\BSON\ObjectID($shlokaId)]);
        echo "<script>Swal.fire('Success', 'Shloka deleted successfully!', 'success');</script>";
        header('Refresh: 1; URL=editor_dashboard.php');
        exit();
    } elseif (isset($_POST['add_shloka'])) {
        $akshara = $_POST['akshara'];
        $content = $_POST['content'];
        $shlokasCollection->insertOne(['akshara' => $akshara, 'content' => $content]);
        echo "<script>Swal.fire('Success', 'Shloka added successfully!', 'success');</script>";
        header('Refresh: 1; URL=editor_dashboard.php');
        exit();
    } elseif (isset($_POST['update_shloka'])) {
        $shlokaId = $_POST['shloka_id'];
        $akshara = $_POST['akshara'];
        $content = $_POST['content'];
        $shlokasCollection->updateOne(
            ['_id' => new MongoDB\BSON\ObjectID($shlokaId)],
            ['$set' => ['akshara' => $akshara, 'content' => $content]]
        );
        echo "<script>Swal.fire('Success', 'Shloka updated successfully!', 'success');</script>";
        header('Refresh: 1; URL=editor_dashboard.php');
        exit();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editor Dashboard</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10/dist/sweetalert2.min.css">
    <script src="https://cdn.ckeditor.com/4.16.2/standard/ckeditor.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
</head>
<body>
    <?php include 'navbar.php'; ?>

    <div class="container mt-5">
        <div class="card mb-4">
            <div class="card-header">
                <h3>Manage Shlokas</h3>
            </div>
            <div class="card-body">
                <table class="table table-bordered">
                    <thead>
                        <tr>
                            <th>Akshara</th>
                            <th>Content</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($shlokas as $shloka): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($shloka['akshara']); ?></td>
                            <td><?php echo htmlspecialchars($shloka['content']); ?></td>
                            <td>
                                <form action="editor_dashboard.php" method="post" style="display:inline;">
                                    <input type="hidden" name="shloka_id" value="<?php echo $shloka['_id']; ?>">
                                    <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#editModal<?php echo $shloka['_id']; ?>">Edit</button>
                                    <button type="submit" name="delete_shloka" class="btn btn-danger">Delete</button>
                                </form>

                                <!-- Edit Modal -->
                                <div class="modal fade" id="editModal<?php echo $shloka['_id']; ?>" tabindex="-1" role="dialog" aria-labelledby="editModalLabel<?php echo $shloka['_id']; ?>" aria-hidden="true">
                                    <div class="modal-dialog" role="document">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <h5 class="modal-title" id="editModalLabel<?php echo $shloka['_id']; ?>">Edit Shloka</h5>
                                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                    <span aria-hidden="true">&times;</span>
                                                </button>
                                            </div>
                                            <form action="editor_dashboard.php" method="post">
                                                <div class="modal-body">
                                                    <input type="hidden" name="shloka_id" value="<?php echo $shloka['_id']; ?>">
                                                    <div class="form-group">
                                                        <label for="akshara">Akshara:</label>
                                                        <input type="text" class="form-control" id="akshara" name="akshara" value="<?php echo htmlspecialchars($shloka['akshara']); ?>" required>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="content">Content:</label>
                                                        <textarea class="form-control" id="content" name="content" rows="3" required><?php echo htmlspecialchars($shloka['content']); ?></textarea>
                                                    </div>
                                                </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                                                    <button type="submit" name="update_shloka" class="btn btn-primary">Save changes</button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-header">
                <h3>Add Shloka</h3>
            </div>
            <div class="card-body">
                <form action="editor_dashboard.php" method="post">
                    <div class="form-group">
                        <label for="akshara">Akshara:</label>
                        <input type="text" class="form-control" id="akshara" name="akshara" required>
                    </div>
                    <div class="form-group">
                        <label for="content">Content:</label>
                        <textarea class="form-control" id="content" name="content" rows="3" required></textarea>
                    </div>
                    <button type="submit" name="add_shloka" class="btn btn-primary">Add Shloka</button>
                </form>
            </div>
        </div>
    </div>

    <script>
        CKEDITOR.replace('content');
    </script>
</body>
</html>
