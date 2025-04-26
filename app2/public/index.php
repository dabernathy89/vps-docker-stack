<?php
// public/index.php (for App 2)
// Simple example script for the second application.

// Set the content type header to plain text
header('Content-Type: text/plain');

// Output a unique greeting message for the second app
echo "Greetings from Application TWO - Also on FrankenPHP!\n\n";

// Output the hostname of the container serving the request
echo "Served by container: " . gethostname() . "\n";

// Output the current server time using a specific format
echo "Current Time: " . date(DATE_RFC3339) . "\n";

// Add different logic for your second app...
