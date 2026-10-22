/**
 * Servidor y Driver Bridge para Impresora Térmica POS - Tickets SIX
 * 100% nativo en Node.js (sin dependencias externas requeridas)
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec, spawn } = require('child_process');

const PORT = process.env.PORT || 3000;
const ROOT_DIR = __dirname;

// Catálogo de productos en memoria
let CATALOGO_PRODUCTOS = [];
const prodsPath = path.join(ROOT_DIR, 'productos.json');
if (fs.existsSync(prodsPath)) {
  try {
    CATALOGO_PRODUCTOS = JSON.parse(fs.readFileSync(prodsPath, 'utf8'));
  } catch (e) {
    console.error('Error al leer productos.json:', e);
  }
}

// Logo SIX en base64
let SIX_LOGO_B64 = '';
const logoB64Path = path.join(ROOT_DIR, 'logo_base64.txt');
if (fs.existsSync(logoB64Path)) {
  SIX_LOGO_B64 = fs.readFileSync(logoB64Path, 'utf8').trim();
}

/**
 * Obtener lista de impresoras de Windows usando PowerShell
 */
function getWindowsPrinters() {
  return new Promise((resolve) => {
    const psCmd = `Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus | ConvertTo-Json`;
    exec(`powershell -NoProfile -Command "${psCmd}"`, { encoding: 'utf8' }, (error, stdout) => {
      if (error || !stdout.trim()) {
        resolve([]);
        return;
      }
      try {
        let parsed = JSON.parse(stdout.trim());
        if (!Array.isArray(parsed)) parsed = [parsed];
        
        // Identificar candidatos a impresoras térmicas
        const printers = parsed.map(p => {
          const name = p.Name || '';
          const driver = p.DriverName || '';
          const port = p.PortName || '';
          const isPos = /pos|thermal|termic|receipt|ticket|58|80|xprint|epson|generic|bixolon|rongta/i.test(name + ' ' + driver + ' ' + port);
          return {
            name,
            driver,
            port,
            isPos
          };
        });
        resolve(printers);
      } catch (e) {
        console.error('Error parseando JSON de impresoras:', e);
        resolve([]);
      }
    });
  });
}

/**
 * Enviar impresión a través de driver_pos.ps1
 */
function printViaDriver(options) {
  return new Promise((resolve, reject) => {
    const { printerName, mode, ticket, anchoMm } = options;
    const scriptPath = path.join(ROOT_DIR, 'driver_pos.ps1');

    if (mode === 'html') {
      // Guardar HTML temporal
      const tempHtmlPath = path.join(ROOT_DIR, `temp_ticket_${Date.now()}.html`);
      fs.writeFileSync(tempHtmlPath, options.htmlContent || '', 'utf8');

      const cmd = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -Accion print-html -Impresora "${printerName}" -Archivo "${tempHtmlPath}"`;
      exec(cmd, { encoding: 'utf8' }, (err, stdout, stderr) => {
        // Limpiar archivo temporal después de unos segundos
        setTimeout(() => {
          try { if (fs.existsSync(tempHtmlPath)) fs.unlinkSync(tempHtmlPath); } catch (_) {}
        }, 8000);

        if (err) {
          reject(new Error(stderr || stdout || err.message));
        } else {
          resolve({ success: true, message: `Ticket enviado a ${printerName}` });
        }
      });
    } else {
      // Modo RAW ESC/POS usando test o JSON
      const tempJsonPath = path.join(ROOT_DIR, `temp_ticket_${Date.now()}.json`);
      fs.writeFileSync(tempJsonPath, JSON.stringify(ticket, null, 2), 'utf8');

      // Generar y enviar vía imprimir_ticket.ps1
      const printScript = path.join(ROOT_DIR, 'imprimir_ticket.ps1');
      const cmd = `powershell -ExecutionPolicy Bypass -File "${printScript}" -Total ${ticket.total} -Impresora "${printerName}" -AnchoMm ${anchoMm || 80} -Folio "${ticket.folio}" -Nombre "${ticket.nombre}" -Ceco "${ticket.ceco}" -CU "${ticket.cu}" -Fecha "${ticket.fecha}"`;
      
      exec(cmd, { encoding: 'utf8' }, (err, stdout, stderr) => {
        setTimeout(() => {
          try { if (fs.existsSync(tempJsonPath)) fs.unlinkSync(tempJsonPath); } catch (_) {}
        }, 2000);

        if (err) {
          reject(new Error(stderr || stdout || err.message));
        } else {
          resolve({ success: true, message: `Ticket enviado en modo RAW a ${printerName}`, stdout });
        }
      });
    }
  });
}

// Servidor HTTP
const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // CORS headers para permitir llamadas locales
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // --- API: Lista de Impresoras ---
  if (pathname === '/api/printers' && req.method === 'GET') {
    try {
      const printers = await getWindowsPrinters();
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, printers }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: e.message }));
    }
    return;
  }

  // --- API: Imprimir Ticket ---
  if (pathname === '/api/print' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const data = JSON.parse(body);
        const result = await printViaDriver(data);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify(result));
      } catch (e) {
        console.error('Error al imprimir:', e);
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: e.message }));
      }
    });
    return;
  }

  // --- API: Test Ticket ---
  if (pathname === '/api/test' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const data = JSON.parse(body || '{}');
        const printerName = data.printerName || '';
        const scriptPath = path.join(ROOT_DIR, 'driver_pos.ps1');
        const cmd = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -Accion test -Impresora "${printerName}" -AnchoMm ${data.anchoMm || 80}`;
        exec(cmd, { encoding: 'utf8' }, (err, stdout, stderr) => {
          if (err) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: false, error: stderr || stdout || err.message }));
          } else {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, message: 'Ticket de prueba enviado', stdout }));
          }
        });
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: e.message }));
      }
    });
    return;
  }

  // --- Archivos Estáticos ---
  let filePath = path.join(ROOT_DIR, pathname === '/' ? 'index.html' : pathname);

  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(ROOT_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.txt': 'text/plain; charset=utf-8'
  };

  const contentType = mimeTypes[ext] || 'application/octet-stream';
  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(404);
      res.end('Archivo no encontrado');
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
});

// Obtener IPs de red local para acceso desde móvil
const os = require('os');
function getNetworkIps() {
  const nets = os.networkInterfaces();
  const results = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        results.push({ name, ip: net.address });
      }
    }
  }
  return results;
}

server.listen(PORT, '0.0.0.0', () => {
  const ips = getNetworkIps();
  console.log(`=======================================================`);
  console.log(` 🖨️  SERVIDOR DE IMPRESION POS TICKETS SIX INICIADO`);
  console.log(`=======================================================`);
  console.log(` 💻 Desde esta PC:   http://localhost:${PORT}`);
  ips.forEach(n => {
    console.log(` 📱 Desde tu Móvil: http://${n.ip}:${PORT}  (${n.name})`);
  });
  console.log(`=======================================================`);
  console.log(` Presiona Ctrl+C para detener el servicio.`);
});
