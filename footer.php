<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>अक्षरश्लोकी</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href=https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js>
    <!-- <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css"> -->
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        $(document).ready(function () {
            $('#search').on('keyup', function () {
                var value = $(this).val().toLowerCase();
                $('#shlokas div').filter(function () {
                    $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
                });
            });
        });
    </script>
    <style>
        .footer {
            position: sticky;
            bottom: 0;
            width: 100%;
            background-color: #f8c471;
            color: white;
            text-align: center;
            padding: 10px 0;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">
    <!-- Your page content goes here -->

    <!-- Footer -->
    <footer class="footer mt-auto">
        <div class="container">
            <span class="text-muted">© All rights reserved, aksharashlokee.in</span><br>
        </div>
        
    </footer>
</body>
</html>
