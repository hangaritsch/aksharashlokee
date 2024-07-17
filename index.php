<?php
session_start();
require 'vendor/autoload.php';

// MongoDB client setup
$client = new MongoDB\Client("mongodb://localhost:27017");
$shlokasCollection = $client->shloka_app->shlokas;

// Fetch all shlokas from the database
$shlokas = $shlokasCollection->find()->toArray();

// Extract unique aksharas from shlokas
$aksharas = array_unique(array_map(function($shloka) { return $shloka['akshara']; }, $shlokas));
sort($aksharas);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shloka Dictionary</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css"/>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
    <style>
        .header {
            background-color: tan;
            padding: 10px 0;
            color: white;
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        .akshara-section {
            margin-bottom: 20px;
        }
        .input-group-text {
            background-color: #fff;
            border-left: 0;
            cursor: pointer;
        }
        .custom-select {
            border-radius: 0.25rem;
            box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.1);
            transition: all 0.2s ease-in-out;
            max-width: 100px;
        }
        .custom-select:hover,
        .custom-select:focus {
            border-color: #007bff;
            box-shadow: 0 0.5rem 1rem rgba(0, 123, 255, 0.25);
        }
        h2 {
            text-align: center;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">
    <!-- Header and Navbar -->
     <?php include 'header.php'; ?> 
                <?php include 'navbar.php'; ?>

    <div class="container-fluid">
        <div class="content">
            <div class="mb-3">
                <div class="input-group">
                    <input type="text" id="search" class="form-control" placeholder="अन्वेषणम्">
                    <div class="input-group-append">
                        <span class="input-group-text"><i class="fas fa-search"></i></span>
                    </div>
                </div>
            </div>
            <div class="mb-3">
                <select id="aksharaSelector" class="form-control custom-select">
                    <option value="">अक्षराणि</option>
                    <?php
                    // Display aksharas as options in the selector
                    foreach ($aksharas as $akshara) {
                        echo '<option value="' . $akshara . '">' . $akshara . '</option>';
                    }
                    ?>
                </select>
            </div>
            <div id="shlokas">
                <?php
                // Display shlokas categorized by aksharas
                foreach ($aksharas as $akshara) {
                    echo '<div id="' . $akshara . '" class="akshara-section" style="display: none;">';
                    echo '<h3>' . $akshara . '</h3>';
                    foreach ($shlokas as $shloka) {
                        if ($shloka['akshara'] == $akshara) {
                            echo '<pre>' . $shloka['content'] . '</pre>';
                        }
                    }
                    echo '</div>';
                }
                ?>
            </div>
        </div>
    </div>

    <?php include 'footer.php'; ?>

    <script>
    document.getElementById('search').addEventListener('input', function() {
        var searchQuery = this.value.toLowerCase();
        document.querySelectorAll('.akshara-section').forEach(function(section) {
            var sectionText = section.textContent.toLowerCase();
            section.style.display = sectionText.includes(searchQuery) ? 'block' : 'none';
        });
    });

    document.getElementById('aksharaSelector').addEventListener('change', function() {
        var selectedAkshara = this.value;
        document.querySelectorAll('.akshara-section').forEach(function(section) {
            if (section.id === selectedAkshara) {
                section.style.display = 'block';
            } else {
                section.style.display = 'none';
            }
        });
    });
    </script>

    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.5.4/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
