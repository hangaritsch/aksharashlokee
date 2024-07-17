<?php
session_start();
require 'vendor/autoload.php';

if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'admin') {
    header('Location: login.php');
    exit();
}

$client = new MongoDB\Client("mongodb://localhost:27017");
$usersCollection = $client->shloka_app->users;
$shlokasCollection = $client->shloka_app->shlokas;

$users = $usersCollection->find()->toArray();
$shlokas = $shlokasCollection->find()->toArray();

function convertToUtf8($str) {
    if (mb_detect_encoding($str, 'UTF-8', true) === false) {
        return utf8_encode($str);
    }
    return $str;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['update_role'])) {
        $userId = $_POST['user_id'];
        $newRole = $_POST['role'];
        $usersCollection->updateOne(['_id' => new MongoDB\BSON\ObjectID($userId)], ['$set' => ['role' => $newRole]]);
        echo "<script>Swal.fire('Success', 'User role updated successfully!', 'success');</script>";
        header('Refresh: 1; URL=admin_dashboard.php');
        exit();
    } elseif (isset($_POST['delete_shloka'])) {
        $shlokaId = $_POST['shloka_id'];
        $shlokasCollection->deleteOne(['_id' => new MongoDB\BSON\ObjectID($shlokaId)]);
        echo "<script>Swal.fire('Success', 'Shloka deleted successfully!', 'success');</script>";
        header('Refresh: 1; URL=admin_dashboard.php');
        exit();
    } elseif (isset($_POST['add_shloka'])) {
        $akshara = convertToUtf8($_POST['akshara']);
        $content = convertToUtf8($_POST['content']);
        $shlokasCollection->insertOne(['akshara' => $akshara, 'content' => $content]);
        echo "<script>Swal.fire('Success', 'Shloka added successfully!', 'success');</script>";
        header('Refresh: 1; URL=admin_dashboard.php');
        exit();
    } elseif (isset($_POST['import_shlokas'])) {
        if (isset($_FILES['csv_file']) && $_FILES['csv_file']['error'] == 0) {
            $file = $_FILES['csv_file']['tmp_name'];
            $extension = pathinfo($_FILES['csv_file']['name'], PATHINFO_EXTENSION);

            if ($extension == 'csv') {
                $csvFile = fopen($file, 'r');
                while (($line = fgetcsv($csvFile)) !== FALSE) {
                    $akshara = convertToUtf8($line[0]);
                    $content = convertToUtf8($line[1]);
                    $shlokasCollection->insertOne(['akshara' => $akshara, 'content' => $content]);
                }
                fclose($csvFile);
            } elseif (in_array($extension, ['xls', 'xlsx'])) {
                $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file);
                $worksheet = $spreadsheet->getActiveSheet();
                foreach ($worksheet->getRowIterator() as $row) {
                    $cellIterator = $row->getCellIterator();
                    $cellIterator->setIterateOnlyExistingCells(false);

                    $line = [];
                    foreach ($cellIterator as $cell) {
                        $line[] = $cell->getValue();
                    }
                    $akshara = convertToUtf8($line[0]);
                    $content = convertToUtf8($line[1]);
                    $shlokasCollection->insertOne(['akshara' => $akshara, 'content' => $content]);
                }
            }
            echo "<script>Swal.fire('Success', 'Shlokas imported successfully!', 'success');</script>";
            header('Refresh: 1; URL=admin_dashboard.php');
            exit();
        }
    } elseif (isset($_POST['update_shloka'])) {
        $shlokaId = $_POST['shloka_id'];
        $akshara = convertToUtf8($_POST['akshara']);
        $content = convertToUtf8($_POST['content']);
        $shlokasCollection->updateOne(
            ['_id' => new MongoDB\BSON\ObjectID($shlokaId)],
            ['$set' => ['akshara' => $akshara, 'content' => $content]]
        );
        echo "<script>Swal.fire('Success', 'Shloka updated successfully!', 'success');</script>";
        header('Refresh: 1; URL=admin_dashboard.php');
        exit();
    }
}

if (isset($_GET['export'])) {
    $spreadsheet = new \PhpOffice\PhpSpreadsheet\Spreadsheet();
    $sheet = $spreadsheet->getActiveSheet();

    $sheet->setCellValue('A1', 'Akshara');
    $sheet->setCellValue('B1', 'Content');

    $row = 2;
    foreach ($shlokas as $shloka) {
        $sheet->setCellValue('A' . $row, $shloka['akshara']);
        $sheet->setCellValue('B' . $row, $shloka['content']);
        $row++;
    }

    $writer = \PhpOffice\PhpSpreadsheet\IOFactory::createWriter($spreadsheet, 'Xlsx');
    $fileName = sys_get_temp_dir() . '/shlokas_export.xlsx';
    $writer->save($fileName);

    header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    header('Content-Disposition: attachment; filename="shlokas_export.xlsx"');
    readfile($fileName);
    unlink($fileName);
    exit();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10/dist/sweetalert2.min.css">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
</head>
<body>
    <?php include 'header.php'; ?>

    <div class="container mt-5">
        <div class="card mb-4">
            <div class="card-header">
                <h3>Manage Users</h3>
            </div>
            <div class="card-body">
                <table class="table table-bordered">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($users as $user): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($user['name']); ?></td>
                            <td><?php echo htmlspecialchars($user['email']); ?></td>
                            <td><?php echo htmlspecialchars($user['role']); ?></td>
                            <td>
                                <form action="admin_dashboard.php" method="post">
                                    <input type="hidden" name="user_id" value="<?php echo $user['_id']; ?>">
                                    <select name="role" class="form-control">
                                        <option value="learner" <?php if ($user['role'] == 'learner') echo 'selected'; ?>>Learner</option>
                                        <option value="editor" <?php if ($user['role'] == 'editor') echo 'selected'; ?>>Editor</option>
                                        <option value="admin" <?php if ($user['role'] == 'admin') echo 'selected'; ?>>Admin</option>
                                    </select>
                                    <button type="submit" name="update_role" class="btn btn-primary mt-2">Update Role</button>
                                </form>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

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
                                <form action="admin_dashboard.php" method="post" style="display:inline;">
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
                                            <form action="admin_dashboard.php" method="post">
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
                <form action="admin_dashboard.php" method="post">
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

        <div class="card mb-4">
            <div class="card-header">
                <h3>Import Shlokas</h3>
            </div>
            <div class="card-body">
                <form action="admin_dashboard.php" method="post" enctype="multipart/form-data">
                    <div class="form-group">
                        <label for="csv_file">CSV or Excel File:</label>
                        <input type="file" class="form-control-file" id="csv_file" name="csv_file" required>
                    </div>
                    <button type="submit" name="import_shlokas" class="btn btn-primary">Import Shlokas</button>
                </form>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-header">
                <h3>Export Shlokas</h3>
            </div>
            <div class="card-body">
                <form action="admin_dashboard.php" method="get">
                    <button type="submit" name="export" class="btn btn-primary">Export to Excel</button>
                </form>
            </div>
        </div>
    </div>
    <?php include 'footer.php'; ?>
</body>
</html>
