<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>अक्षरश्लोकी</title>
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
        .header-title {
            flex-grow: 1;
            text-align: center;
            margin: 0;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">
    <!-- Header and Navbar -->
    <header class="header">
        <div class="container">
            <div class="d-flex align-items-center justify-content-between">
                <div class="header-title animate__animated animate__fadeInDown">
                    <h2>अक्षरश्लोकी</h2>
        </div>
        <?php if (isset($_SESSION['user_id'])): ?>
    <div class="bg-tan text-dark p-2 text-right" style="font-size: small;">
        Welcome, <?php echo htmlspecialchars($_SESSION['name']); ?>
    </div>
<?php endif; ?>
    </header>

    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
