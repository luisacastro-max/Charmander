// Servidor estático mínimo para ver o build web do app (app/build/web).
const http = require('http'), fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..', 'app', 'build', 'web');
// Uso: node serve-web.js [porta] [host]. Host "0.0.0.0" abre para a rede
// local (para testar no celular no mesmo Wi-Fi).
const port = Number(process.argv[2] || process.env.PORT || 8097);
const host = process.argv[3] || 'localhost';
const tipos = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css', '.svg': 'image/svg+xml' };
http.createServer((req, res) => {
  let p = path.normalize(decodeURIComponent(req.url.split('?')[0])).replace(/^([\/])+/, '');
  let f = path.join(root, p);
  if (!f.startsWith(root)) { res.writeHead(403); return res.end(); }
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(root, 'index.html');
  res.writeHead(200, { 'Content-Type': tipos[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
  fs.createReadStream(f).pipe(res);
}).listen(port, host, () => console.log('Servindo em http://' + host + ':' + port));
