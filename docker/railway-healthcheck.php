<?php

declare(strict_types=1);

$context = stream_context_create([
    'http' => [
        'timeout'       => 8,
        'ignore_errors' => true,
        'header'        => "Host: localhost\r\nConnection: close\r\n",
    ],
]);

$body = @file_get_contents('http://127.0.0.1/status.php', false, $context);
if ($body === false) {
    fwrite(STDERR, "GLPI status endpoint is unreachable.\n");
    exit(1);
}

$statusLine = $http_response_header[0] ?? '';
if (!preg_match('/\\s200(?:\\s|$)/', $statusLine)) {
    fwrite(STDERR, "GLPI status endpoint did not return HTTP 200.\n");
    exit(1);
}

$status = json_decode($body, true);
$glpiStatus = is_array($status) ? ($status['glpi']['status'] ?? null) : null;

// WARNING keeps the service available while signalling a degraded optional
// integration. PROBLEM means a core check such as DB or filesystem failed.
if (!in_array($glpiStatus, ['OK', 'WARNING'], true)) {
    fwrite(STDERR, "GLPI reports an unhealthy core service.\n");
    exit(1);
}

exit(0);
