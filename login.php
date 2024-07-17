<?php
session_start();
require 'vendor/autoload.php';
require 'config.php';
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$client = new MongoDB\Client("mongodb://localhost:27017");
$usersCollection = $client->shloka_app->users;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['login'])) {
        $email = $_POST['email'];
        $password = $_POST['password'];

        $user = $usersCollection->findOne(['email' => $email]);
        if ($user && password_verify($password, $user['password'])) {
            $_SESSION['user_id'] = (string) $user['_id'];
            $_SESSION['name'] = $user['name'];
            $_SESSION['email'] = $user['email'];
            $_SESSION['role'] = $user['role'];

            header('Location: index.php');
            exit();
        } else {
            $loginError = 'Invalid email or password.';
        }
    } elseif (isset($_POST['register'])) {
        $name = $_POST['name'];
        $email = $_POST['email'];
        $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
        $role = 'learner';

        // Generate OTP
        $otp = rand(100000, 999999);

        // Save the user data and OTP in session
        $_SESSION['name'] = $name;
        $_SESSION['email'] = $email;
        $_SESSION['password'] = $password;
        $_SESSION['role'] = $role;
        $_SESSION['otp'] = $otp;

        // Send OTP email
        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host = SMTP_HOST;
            $mail->SMTPAuth = true;
            $mail->Username = SMTP_USERNAME;
            $mail->Password = SMTP_PASSWORD;
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port = 587;

            $mail->setFrom(SMTP_FROM_EMAIL, 'AKSHARASHLOKEE');
            $mail->addAddress($email, $name);

            $mail->isHTML(true);
            $mail->Subject = 'Your OTP Code';
            $mail->Body = "Your OTP code is: $otp";

            $mail->send();
            $_SESSION['otp_sent'] = true;
            header('Location: verify_otp.php');
            exit();
        } catch (Exception $e) {
            $registerError = "Message could not be sent. Mailer Error: {$mail->ErrorInfo}";
        }
    } elseif (isset($_POST['forgot_password'])) {
        // Handle forgot password logic here
        // Example: Generate reset token, save it to the database, send email with reset link
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login/Register</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <?php include 'header.php'; ?>
    <?php include 'navbar.php'; ?>
</head>
<body>
    <div class="container">
        <h2>Login/Register</h2>
        <?php if (isset($loginError)): ?>
            <div class="alert alert-danger"><?php echo $loginError; ?></div>
        <?php endif; ?>
        <?php if (isset($registerError)): ?>
            <div class="alert alert-danger"><?php echo $registerError; ?></div>
        <?php endif; ?>

        <!-- Login Form -->
        <form id="loginForm" action="login.php" method="post">
            <div class="form-group">
                <label for="loginEmail">Email:</label>
                <input type="email" class="form-control" id="loginEmail" name="email" required>
            </div>
            <div class="form-group">
                <label for="loginPassword">Password:</label>
                <input type="password" class="form-control" id="loginPassword" name="password" required>
            </div>
            <button type="submit" class="btn btn-primary" name="login">Login</button>
        </form>

        <!-- Register Form -->
        <form id="registerForm" action="login.php" method="post" style="display: none;">
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" class="form-control" id="name" name="name" required>
            </div>
            <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" class="form-control" id="email" name="email" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" class="form-control" id="password" name="password" required>
            </div>
            <div class="form-group">
                <label for="confirm_password">Confirm Password:</label>
                <input type="password" class="form-control" id="confirm_password" required>
            </div>
            <button type="submit" class="btn btn-primary" name="register">Register</button>
        </form>

        <!-- Forgot Password Form -->
        <form id="forgotPasswordForm" action="login.php" method="post" style="display: none;">
            <div class="form-group">
                <label for="forgotEmail">Email:</label>
                <input type="email" class="form-control" id="forgotEmail" name="email" required>
            </div>
            <button type="submit" class="btn btn-primary" name="forgot_password">Reset Password</button>
        </form>

        <!-- Toggle Links -->
        <a href="#" id="showRegisterForm">Create an account</a>
        <a href="#" id="showForgotPasswordForm">Forgot password?</a>
    </div>

    <script>
        $(document).ready(function() {
            $('#showRegisterForm').click(function(e) {
                e.preventDefault();
                $('#loginForm').hide();
                $('#forgotPasswordForm').hide();
                $('#registerForm').show();
            });

            $('#showForgotPasswordForm').click(function(e) {
                e.preventDefault();
                $('#loginForm').hide();
                $('#registerForm').hide();
                $('#forgotPasswordForm').show();
            });

            $('#registerForm').submit(function(event) {
                const password = $('#password').val();
                const confirmPassword = $('#confirm_password').val();
                if (password !== confirmPassword) {
                    event.preventDefault();
                    alert('Passwords do not match.');
                }
            });
        });
    </script>
</body>
</html>
