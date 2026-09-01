<?php
// Router script for PHP's built-in web server (`php -S ... router.php`).
//
// Without this, the built-in server maps the request path directly to a
// file under the docroot, so a request forwarded by a load balancer's
// path-based rule (e.g. GET /php/anything) would 404 instead of reaching
// index.php. This router always serves index.php regardless of path,
// matching the Node.js/Python apps, which already respond identically to
// any path.
require __DIR__ . '/index.php';
