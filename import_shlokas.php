<?php
session_start();
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;
use MongoDB\Client;

if (!isset($_SESSION['role']) || $_SESSION['role'] != 'admin') {
    header('Location: index.php');
    exit();
}

$client = new Client("mongodb://localhost:27017");
$collection = $client->shloka_app->shlokas;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $file = $_FILES['file']['tmp_name'];
    $fileType = $_FILES['file']['type'];
    $extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);

    $success = false;

    if ($extension == 'csv') {
        $file = fopen($file, 'r');
        while (($line = fgetcsv($file)) !== FALSE) {
            $akshara = $line[0];
            $content = $line[1];
            $collection->insertOne([
                'akshara' => $akshara,
                'content' => $content
            ]);
        }
        fclose($file);
        $success = true;
    } elseif ($extension == 'xlsx') {
        $spreadsheet = IOFactory::load($file);
        $sheetData = $spreadsheet->getActiveSheet()->toArray(null, true, true, true);
        foreach ($sheetData as $row) {
            $akshara = $row['A'];
            $content = $row['B'];
            $collection->insertOne([
                'akshara' => $akshara,
                'content' => $content
            ]);
        }
        $success = true;
    }

    if ($success) {
        echo '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>';
        echo '<script>
                window.onload = function() {
                    Swal.fire({
                        icon: "success",
                        title: "Import Successful",
                        text: "Shlokas have been successfully imported."
                    }).then(function() {
                        window.location.href = "dashboard.php";
                    });
                }
              </script>';
    } else {
        echo '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>';
        echo '<script>
                window.onload = function() {
                    Swal.fire({
                        icon: "error",
                        title: "Import Failed",
                        text: "There was an issue with the file import. Please try again."
                    }).then(function() {
                        window.location.href = "dashboard.php";
                    });
                }
              </script>';
    }
} else {
    header('Location: dashboard.php');
    exit();
}
?>
