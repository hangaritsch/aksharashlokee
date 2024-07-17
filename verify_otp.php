<?php
session_start();
require 'vendor/autoload.php';

$client = new MongoDB\Client("mongodb://localhost:27017");
$collection = $client->shloka_app->users;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $otp = $_POST['otp'];

    if ($otp == $_SESSION['otp']) {
        // OTP is correct, create the user account
        $name = $_SESSION['name'];
        $email = $_SESSION['email'];
        $password = $_SESSION['password'];
        $role = $_SESSION['role'];

        $collection->insertOne([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'role' => $role
        ]);

        // Clear session data
        unset($_SESSION['name']);
        unset($_SESSION['email']);
        unset($_SESSION['password']);
        unset($_SESSION['role']);
        unset($_SESSION['otp']);
        unset($_SESSION['otp_sent']);

        $message = 'Account created successfully. You can now login.';
        $redirect = true;
    } else {
        $message = 'Invalid OTP. Please try again.';
        $redirect = false;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify OTP</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
</head>
<body>
    <div class="container">
        <h2>Verify OTP</h2>
        <form action="verify_otp.php" method="post">
            <div class="form-group">
                <label for="otp">Enter OTP:</label>
                <input type="text" class="form-control" id="otp" name="otp" required>
            </div>
            <button type="submit" class="btn btn-primary">Verify OTP</button>
        </form>
    </div>

    <?php if (isset($message)): ?>
    <script>
        Swal.fire({
            icon: '<?php echo $redirect ? "success" : "error"; ?>',
            title: '<?php echo $redirect ? "Success" : "Error"; ?>',
            text: '<?php echo $message; ?>',
            showConfirmButton: true
        }).then((result) => {
            <?php if ($redirect): ?>
            window.location.href = 'login.php';
            <?php endif; ?>
        });
    </script>
    <?php endif; ?>
</body>
</html>
