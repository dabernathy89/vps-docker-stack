<?php
// public/index.php (for App 1)
// Simple example script for the first application.

// Set the content type header to plain text
header('Content-Type: text/plain');

// Output a greeting message
echo "Hello from App 1 - Powered by FrankenPHP!\n\n";

// Output the hostname of the container serving the request
echo "Hostname: " . gethostname() . "\n";

// Output the currently running PHP version
echo "PHP Version: " . phpversion() . "\n";

// Add more application logic here...

?>
