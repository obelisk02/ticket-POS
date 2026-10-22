# 🖨️ Solución Completa de Generación e Impresión de Tickets SIX para Impresora Térmica POS

Esta solución integra el generador oficial de tickets de **SIX** (Controladora de Negocios Comerciales &bull; RFC: `CNC820428674`) clonado del repositorio oficial con un **driver y motor de impresión térmica POS** (80 mm y 58 mm) para Windows.

Permite generar tickets idénticos a [`ticket_T-131334_352.html`](file:///c:/Users/Darwi/Downloads/Impresora%20Tickets%20SIX/ticket_T-131334_352.html) e imprimirlos directamente en tu impresora térmica POS.

---

## 🚀 Inicio Rápido en 1 Clic

1. Haz doble clic en el archivo [`iniciar_sistema.bat`](file:///c:/Users/Darwi/Downloads/Impresora%20Tickets%20SIX/iniciar_sistema.bat).
2. Se iniciará el servicio local de driver (`server.js`) y se abrirá automáticamente tu navegador en `http://localhost:3000`.
3. Haz clic en el botón verde **⚡ Generar y Mandar a POS** para generar un ticket aleatorio ($200 - $600) y enviarlo a imprimir en un solo paso.

---

## 📋 Características Principales

### 1. Generador Oficial de Tickets SIX Integrado
- **Rango Obligatorio**: Genera automáticamente montos entre **$200.00 y $600.00 MXN** o permite fijar un monto manual exacto.
- **Catálogo Oficial**: Más de **464 productos reales** de cervezas y bebidas (*Indio, Tecate, Carta Blanca, Heineken, Bohemia, Amstel, Sol, Dos Equis XX, Strongbow, Canijilla*, etc.).
- **Matemática Exacta**: La suma de los subtotales de cada renglón (`col-tot`) coincide al centavo con el Total.
- **Total en Letras**: Conversión a palabras en mayúsculas en español (*ej. "TRESCIENTOS CINCUENTA Y DOS 00/100 PESOS M.N."*).
- **Metadatos Oficiales**: Folio aleatorio `T-XXXXXX`, UUID `C.U` en minúsculas, rotación entre sucursales SIX reales de **Ciudad de México (CDMX)** (*Condesa, Roma Norte, Coyoacán, Polanco, Del Valle, Narvarte, Insurgentes Sur*) y **Michoacán** (*Camelinas, Ventura Puente, La Huerta, Altozano, Acueducto, Solidaridad, Las Tijeras, Madero Poniente*) con sus respectivos CECOs y Lugar de Expedición correspondiente.
- **Fidelidad Visual Total**: Incluye el logotipo oficial en Base64, encabezado fiscal inalterable, líneas punteadas y fuente monoespaciada para ticket térmico continuo.

### 2. Impresión en Hoja Tamaño Carta (4 Tickets de 80 mm por Hoja)
- **Aprovechamiento Máximo de Papel**: En una hoja estándar tamaño Carta (215.9 mm × 279.4 mm) se acomodan **exactamente 4 tickets en su tamaño físico real original de 80 mm** en una cuadrícula de 2 columnas × 2 filas con márgenes y separación estética.
- **Tamaño Real 100% Original**: Cada ticket mantiene exactamente sus 80 mm físicos (`width: 80mm !important`), sin deformaciones, sin reducciones ni estiramientos. Al imprimirlos en cualquier impresora láser o de inyección de tinta común, lucen con fidelidad idéntica al ticket de rollo térmico.
- **Guías de Corte con Tijera**: Cada ticket incluye bordes punteados y un distintivo superior `✂ - - - - CORTE 80 mm (TICKET #) - - - - ✂` para recortarlos fácilmente al tamaño original de recibo.
- **Generación Multi-Hoja**: Puedes elegir generar desde 1 hoja (4 tickets) hasta 4 hojas (16 tickets) en un solo clic, con folios únicos `T-XXXXXX`, UUIDs auténticos, fecha y hora independientes y sumas exactas cuadradas al centavo.
- **Rotación de Sucursales**: Puedes elegir si rotar sucursales entre las tiendas oficiales SIX de Ciudad de México y Michoacán o mantener la misma sucursal en todos los tickets.
- **Exportación Flexible**: Puedes previsualizar en pantalla conmutando pestañas, imprimir directamente en tamaño Carta con `Ctrl + P`, descargar un archivo `.html` autónomo listo para imprimir en cualquier PC o guardar la imagen en PNG de alta resolución.

### 3. Driver Térmico POS Multimodo (Rollo Continuo)
- **Soporte de Ancho de Rollo**: Alterna fácilmente entre **80 mm (Estándar)** y **58 mm (Mini / Portátil)**.
- **Modo 1: Impresión Directa con Driver Local (Cero Ventanas)**:
  - Detecta automáticamente las impresoras térmicas conectadas en Windows.
  - Envía la orden directamente al Spooler de Windows usando la API Win32 (`winspool.drv`), con comando de corte de papel automático (`GS V 0`).
- **Modo 2: Impresión Directa Web (Cero Configuración)**:
  - Si abres [`index.html`](file:///c:/Users/Darwi/Downloads/Impresora%20Tickets%20SIX/index.html) directamente en cualquier navegador (Chrome, Edge), detecta automáticamente si estás imprimiendo un ticket individual en rollo térmico o la hoja tamaño Carta.
- **Modo 3: Exportación Rápida**:
  - Descarga el archivo `.html` listo para archivar.
  - Copia el código HTML al portapapeles.
  - Guarda imagen PNG o comparte con apps móviles (*RawBT*).

---

## 💻 Uso por Línea de Comandos (CLI / Automatización)

Puedes generar e imprimir tickets directamente desde PowerShell o terminal sin abrir el navegador:

```powershell
# Generar ticket aleatorio ($200 a $600) e imprimirlo en la impresora predeterminada:
powershell -ExecutionPolicy Bypass -File .\imprimir_ticket.ps1 -Azar

# Generar un ticket de monto exacto y mandarlo a una impresora térmica específica:
powershell -ExecutionPolicy Bypass -File .\imprimir_ticket.ps1 -Total 350.00 -Impresora "POS-80"

# Generar para rollo de 58 mm:
powershell -ExecutionPolicy Bypass -File .\imprimir_ticket.ps1 -Total 280.00 -AnchoMm 58 -Impresora "POS-58"

# Generar y guardar el archivo HTML sin imprimir:
powershell -ExecutionPolicy Bypass -File .\imprimir_ticket.ps1 -Total 420.00 -GuardarHtml "mi_ticket.html"
```

---

## 🛠️ Diagnóstico y Configuración de tu Impresora POS

Si conectas una nueva impresora térmica POS y quieres verificar que Windows la reconozca:

1. Ejecuta [`configurar_impresora_pos.bat`](file:///c:/Users/Darwi/Downloads/Impresora%20Tickets%20SIX/configurar_impresora_pos.bat).
2. Te mostrará los puertos USB detectados (ej. `USB001`), puertos COM y las impresoras instaladas.
3. En la interfaz web, el selector detectará automáticamente tu impresora y la marcará como `🖨️ [POS TÉRMICA]`.

---

## 📱 Uso desde el Teléfono Móvil (Android / iPhone)

La versión web está diseñada con interfaz responsive táctil y soporta **3 formas de imprimir desde el celular**:

### 1. En la Misma Red Wi-Fi (Imprimir en la impresora USB de la PC desde el celular)
1. Enciende la PC y ejecuta [`iniciar_sistema.bat`](file:///c:/Users/Darwi/Downloads/Impresora%20Tickets%20SIX/iniciar_sistema.bat).
2. Desde tu celular conectado al mismo Wi-Fi, abre el navegador en:
   ```
   http://192.168.100.6:3000
   ```
   *(O si usas Tailscale VPN para imprimir desde la calle: `http://100.81.148.105:3000`)*
3. En la pantalla del celular verás el panel táctil. Al pulsar **"🖨️ Imprimir Ticket"**, la orden viaja a tu PC e imprime de inmediato en la impresora térmica conectada por USB con corte de papel.

### 2. Impresoras Térmicas Portátiles Bluetooth (Chrome en Android)
1. Enciende tu mini impresora térmica Bluetooth (58mm u 80mm).
2. En la app web en tu celular, pulsa el botón azul **"🔵 Conectar Bluetooth POS"**.
3. Selecciona tu impresora en la ventana del navegador (API Web Bluetooth nativa).
4. Al pulsar imprimir, los comandos binarios ESC/POS se enviarán directamente a la impresora sin apps externas ni cables.

### 3. Compartir con Apps de Impresión (RawBT / Bluetooth Print)
1. En la web móvil, pulsa el botón morado **"📲 Compartir / RawBT"**.
2. Se generará una imagen HD del ticket y se abrirá el menú nativo de compartir de Android.
3. Elige tu app de impresión favorita (*RawBT*, *Bluetooth Print*, *ESC POS Wifi Print*, o WhatsApp) y saldrá impresa al instante.

---

## 🌐 Cómo Hospedar la App en GitHub Pages (Gratis y Permanente)

Puedes tener tu generador de tickets SIX accesible en la nube desde cualquier parte del mundo de forma 100% gratuita con **GitHub Pages**:

### Paso 1: Crear el repositorio en GitHub
1. Entra a [github.com](https://github.com) e inicia sesión.
2. Crea un nuevo repositorio público (ejemplo: `tickets-six`).

### Paso 2: Subir los archivos estáticos
Sube los siguientes archivos clave de esta carpeta:
- `index.html` (Contiene toda la aplicación web, diseño móvil y lógica)
- `productos.json` (Catálogo de 464 productos SIX)
- `logo_six.png` (Logo oficial)

*(Opcional: Si tienes Git instalado, ejecuta en esta carpeta:)*
```bash
git init
git add index.html productos.json logo_six.png
git commit -m "Web App Tickets SIX"
git branch -M main
git remote add origin https://github.com/<tu-usuario>/tickets-six.git
git push -u origin main
```

### Paso 3: Activar GitHub Pages
1. En tu repositorio de GitHub, entra a la pestaña **Settings** (Configuración).
2. En la columna izquierda, haz clic en **Pages**.
3. En **Build and deployment**:
   - **Source**: `Deploy from a branch`
   - **Branch**: Selecciona `main` y la carpeta `/ (root)`
4. Haz clic en **Save** (Guardar).

### Paso 4: ¡Listo!
En aproximadamente 1 minuto, tu aplicación web estará activa con certificado HTTPS gratis en:
```
https://<tu-usuario>.github.io/tickets-six/
```
*(El certificado HTTPS de GitHub Pages es indispensable para que funcione el Web Bluetooth en dispositivos móviles).*
