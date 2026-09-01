const http = require('http');
const net = require('net');
const os = require('os');

const APP_NAME = 'nodejs';
const PORT = parseInt(process.env.APP_PORT || '3000', 10);
const MYSQL_HOST = process.env.MYSQL_HOST || '';
const MYSQL_PORT = parseInt(process.env.MYSQL_PORT || '3306', 10);
const REDIS_HOST = process.env.REDIS_HOST || '';
const REDIS_PORT = parseInt(process.env.REDIS_PORT || '6379', 10);

function checkTcp(host, port) {
  return new Promise(function (resolve) {
    const socket = net.createConnection({ host: host, port: port, timeout: 2000 });
    socket.on('connect', function () { socket.destroy(); resolve(true); });
    socket.on('error', function () { resolve(false); });
    socket.on('timeout', function () { socket.destroy(); resolve(false); });
  });
}

http.createServer(function (req, res) {
  Promise.all([
    checkTcp(MYSQL_HOST, MYSQL_PORT),
    checkTcp(REDIS_HOST, REDIS_PORT)
  ]).then(function (results) {
    const body = {
      app: APP_NAME,
      hostname: os.hostname(),
      mysql: { host: MYSQL_HOST, port: MYSQL_PORT, reachable: results[0] },
      redis: { host: REDIS_HOST, port: REDIS_PORT, reachable: results[1] }
    };
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body, null, 2));
  });
}).listen(PORT, function () {
  console.log('nodejs app listening on port ' + PORT);
});
