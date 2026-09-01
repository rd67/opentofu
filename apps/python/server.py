import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

APP_NAME = "python"
PORT = int(os.environ.get("APP_PORT", "4000"))
MYSQL_HOST = os.environ.get("MYSQL_HOST", "")
MYSQL_PORT = int(os.environ.get("MYSQL_PORT", "3306"))
REDIS_HOST = os.environ.get("REDIS_HOST", "")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))


def check_tcp(host, port, timeout=2):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = {
            "app": APP_NAME,
            "hostname": socket.gethostname(),
            "mysql": {"host": MYSQL_HOST, "port": MYSQL_PORT, "reachable": check_tcp(MYSQL_HOST, MYSQL_PORT)},
            "redis": {"host": REDIS_HOST, "port": REDIS_PORT, "reachable": check_tcp(REDIS_HOST, REDIS_PORT)},
        }
        payload = json.dumps(body, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("python app listening on port " + str(PORT))
    server.serve_forever()
