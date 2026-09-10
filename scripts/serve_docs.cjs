const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../docs-site');
const prefix = '/uq-course-graph/';
http.createServer((req, res) => {
  let url;
  try { url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); }
  catch { res.writeHead(400).end(); return; }
  if (!url.startsWith(prefix)) { res.writeHead(404).end(); return; }
  const file = path.resolve(root, url.slice(prefix.length) || 'index.html');
  if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
  fs.readFile(file, (error, data) => {
    if (error) { res.writeHead(404).end(); return; }
    const types = {'.html':'text/html', '.md':'text/plain', '.png':'image/png', '.svg':'image/svg+xml'};
    res.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream', 'Cache-Control':'no-store'});
    res.end(data);
  });
}).listen(8766, '127.0.0.1');
