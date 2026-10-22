# REGLAS Y ÓRDENES PARA GENERACIÓN DE TICKETS DE VENTA

Este archivo define las órdenes e instrucciones permanentes para Antigravity al atender solicitudes de tickets en este espacio de trabajo.

---

## 1. COMPORTAMIENTO PRINCIPAL

Cuando el usuario pida generar un **ticket de venta** (por ejemplo: *"hazme un ticket de $350"*, *"necesito un ticket con fecha de ayer de $500"*, etc.):

1. **Catálogo Exclusivo de Productos**:
   - Los productos a incluir en el ticket deben seleccionarse **estricta y exclusivamente al azar** del catálogo oficial de cervezas y bebidas guardado en `productos.json` y `productos.txt` (464+ productos: Indio, Tecate, Carta Blanca, Heineken, Bohemia, Amstel, Sol, Dos Equis XX, Strongbow, Superior, Miller, Tempus, Jabalí, Canijilla, etc.).
   - No inventar productos ajenos a esta lista.

2. **Rango de Monto Obligatorio ($200 a $600 MXN)**:
   - Los tickets generados **DEBEN ser mayores a $200.00 y NO rebasar los $600.00 pesos** (por ejemplo: $245.00, $282.00, $350.00, $420.50, $580.00, etc.).
   - Si el usuario no pide un monto específico, elegir un monto aleatorio realista dentro de este rango ($201 a $600 MXN).

3. **Cálculo Matemático Exacto del Total**:
   - La suma de los subtotales de los productos (`col-tot`) **DEBE ser exactamente igual** al monto total solicitado o generado.
   - Cada renglón de producto tiene:
     - Cantidad (`col-cant`, ej. `1`, `2`, `3`, `4`, `6`, etc.).
     - Descripción (`col-desc`, nombre exacto del producto tomado de la lista).
     - Subtotal de la línea (`col-tot`, en formato `$XXX.XX`).
   - La suma de todas las líneas debe coincidir con precisión de centavos con el Total.

4. **Variación Dinámica Obligatoria en Cada Ticket**:
   - Cada que se genere un ticket DEBEN cambiar:
     - **Productos seleccionados** (elegidos al azar del catálogo de 464 productos).
     - **Precios y cantidades** de los productos (sumando exactamente el total).
     - **Folio** (nuevo folio aleatorio formato `T-XXXXXX`).
     - **C.U** (nuevo UUID v4 único en minúsculas).
     - **CECO y Sucursal** (rotar entre sucursales SIX como Camelinas, Ventura Puente, La Huerta, Altozano, etc.).
     - **Fecha y hora** (la solicitada por el usuario o fecha actual/reciente en horario comercial creíble).

5. **Formato Obligatorio (Lienzo Blanco)**:
   - Debe entregarse con el código HTML exacto de la plantilla (`plantilla_ticket.html`), respetando la estética de ticket térmico sobre lienzo blanco (`background-color: #ffffff`, fuente `Courier New`, contenedor de 320px con borde dashed `1px dashed #000000`).
   - **SOLO deben cambiarse los siguientes campos dinámicos**:
     - **Folio**: `Folio: T-XXXXXX` (ej. `T-649102` o aleatorio/especificado).
     - **Estatus**: `Liberada` (a menos que se pida otro).
     - **CECO**: Centro de costos (ej. `300481920` o el especificado).
     - **Nombre**: Nombre de la tienda/sucursal (ej. `MICH SIX CAMELINAS` o el especificado).
     - **C.U**: Código Único / UUID en minúsculas (ej. `b3e810a4-7f12-45dc-91b3-4f9012a67bc3` o el especificado).
     - **Lugar exp**: `Morelia, Michoacán` (o la plaza/ciudad especificada).
     - **Fecha exp**: La fecha y hora solicitada por el usuario (formato `DD/MM/YYYY hh:mm a. m./p. m.`). Si no indica hora, utilizar una hora comercial creíble.
     - **Tabla de productos**: Renglones `<tr><td class="col-cant">#</td><td class="col-desc">PRODUCTO</td><td class="col-tot">$XXX.XX</td></tr>`.
     - **Totales**:
       - `Usted Ahorra: $0.00`
       - `Total: $XXX.XX`
     - **Total en letra**: El total expresado en palabras en mayúsculas seguido de `XX/100 PESOS M.N.` (ej. `DOSCIENTOS OCHENTA Y DOS 00/100 PESOS M.N.`).
   - **Campos fijos que NUNCA deben modificarse**:
     - Header fiscal:
       ```html
       CONTROLADORA DE NEGOCIOS COMERCIALES<br>
       RFC: CNC820428674<br>
       Ave. Alfonso Reyes # 2202, Col. Bella Vista<br>
       Monterrey, Nuevo León, MEX. C.P. 64410<br>
       Régimen General de Ley de Personas Morales
       ```
     - Título: `TICKET DE VENTA`
     - Logo oficial Six: `<div class="logo-box"><img src="logo_six.png" alt="SIX"></div>`
     - Footer de facturación y tipo de pago:
       ```html
       <b>Tipo de pago: Efectivo</b><br><br>
       ¿Necesitas Factura? Envía tu ticket de venta, CSF (Constancia de Situación Fiscal) y Forma de pago a facturacionsix@expins.mx. ¿Tienes dudas? Comunícate al 800 CERVEZA (2378392)<br><br>
       <div class="center"><b>PAGO EN UNA SOLA EXHIBICIÓN</b></div>
       ```

---

## 2. FORMATO HTML BASE

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<style>
  body {
    background-color: #ffffff;
    display: flex;
    justify-content: center;
    padding: 20px;
    font-family: "Courier New", Courier, monospace;
    font-size: 13px;
    color: #000;
  }
  .ticket-container {
    width: 320px;
    background: #ffffff;
    border: 1px dashed #000000;
    padding: 16px 14px;
    box-sizing: border-box;
  }
  .header-bloque {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    gap: 6px;
    margin-bottom: 6px;
  }
  .logo-box {
    width: 50px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .logo-box img {
    max-width: 50px;
    max-height: 36px;
    object-fit: contain;
  }
  .header-fiscal {
    flex: 1;
    text-align: center;
    font-family: Arial, "Helvetica Neue", Helvetica, sans-serif;
    font-size: 8px;
    line-height: 1.25;
    font-weight: 700;
    color: #000;
    letter-spacing: -0.15px;
  }
  .titulo {
    font-family: Arial, "Helvetica Neue", Helvetica, sans-serif;
    font-size: 13.5px;
    font-weight: 800;
    text-align: center;
    margin: 8px 0 10px 0;
    letter-spacing: 0.5px;
    color: #000;
  }
  .info-bloque {
    font-size: 11.5px;
    line-height: 1.35;
    margin-bottom: 12px;
  }
  .info-fila {
    display: flex;
    justify-content: space-between;
  }
  .cu-texto {
    word-break: break-all;
    font-size: 10px;
  }
  .tabla-productos {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
  }
  .tabla-productos th {
    font-size: 11.5px;
    padding-bottom: 6px;
    text-align: left;
  }
  .tabla-productos td {
    padding: 5px 0;
    vertical-align: top;
    font-size: 11px;
  }
  .col-cant { width: 12%; text-align: center; }
  .col-desc { 
    width: 60%; 
    padding-left: 8px !important;
    padding-right: 8px !important;
    border-left: 1px solid #000;
    border-right: 1px solid #000;
  }
  .col-tot  { width: 28%; text-align: right; }
  .totales-bloque {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    font-weight: bold;
    margin: 15px 0 8px 0;
  }
  .total-letra {
    font-size: 10px;
    text-align: center;
    margin: 8px 0 12px 0;
  }
  .footer-bloque {
    font-size: 9.5px;
    line-height: 1.35;
  }
  .center {
    text-align: center;
  }
</style>
</head>
<body>

<div class="ticket-container">

  <div class="header-bloque">
    <div class="logo-box"><img src="logo_six.png" alt="SIX"></div>
    <div class="header-fiscal">
      CONTROLADORA DE NEGOCIOS COMERCIALES<br>
      RFC: CNC820428674<br>
      Ave. Alfonso Reyes # 2202, Col. Bella Vista<br>
      Monterrey, Nuevo León, MEX. C.P. 64410<br>
      Régimen General de Ley de Personas Morales
    </div>
  </div>

  <div class="titulo">TICKET DE VENTA</div>

  <div class="info-bloque">
    <div class="info-fila">
      <span>Folio: {{FOLIO}}</span>
      <span>Estatus: {{ESTATUS}}</span>
    </div>
    <div>CECO: {{CECO}}</div>
    <div>Nombre: {{NOMBRE}}</div>
    <div class="cu-texto">C.U: {{CU}}</div>
    <div>Lugar exp: {{LUGAR_EXP}}</div>
    <div>Fecha exp: {{FECHA_EXP}}</div>
  </div>

  <table class="tabla-productos">
    <thead>
      <tr>
        <th class="col-cant">#</th>
        <th class="col-desc" style="text-align: center; border: none;">Descripción</th>
        <th class="col-tot">Total</th>
      </tr>
    </thead>
    <tbody>
      <!-- Renglones de productos -->
    </tbody>
  </table>

  <div class="totales-bloque">
    <span>Usted Ahorra: $0.00</span>
    <span>Total: ${{TOTAL}}</span>
  </div>

  <div class="total-letra">
    {{TOTAL_LETRA}}
  </div>

  <div class="footer-bloque">
    <b>Tipo de pago: Efectivo</b><br><br>
    ¿Necesitas Factura? Envía tu ticket de venta, CSF (Constancia de Situación Fiscal) y Forma de pago a facturacionsix@expins.mx. ¿Tienes dudas? Comunícate al 800 CERVEZA (2378392)<br><br>
    <div class="center"><b>PAGO EN UNA SOLA EXHIBICIÓN</b></div>
  </div>

</div>

</body>
</html>
```

---

## 3. VALORES POR DEFECTO PARA CAMPOS NO ESPECIFICADOS

- **Folio**: `T-` seguido de 6 dígitos aleatorios (ej. `T-649102`, `T-718294`).
- **Estatus**: `Liberada`
- **CECO**: 9 dígitos numéricos (ej. `300481920`, `300512847`).
- **Nombre**: `MICH SIX CAMELINAS` (o sucursal SIX indicada por el usuario).
- **C.U**: UUID v4 aleatorio en minúsculas (ej. `b3e810a4-7f12-45dc-91b3-4f9012a67bc3`).
- **Lugar exp**: `Morelia, Michoacán` (o el indicado).
- **Fecha exp**: La fecha y hora pedida por el usuario. Formato estricto: `DD/MM/YYYY hh:mm a. m.` o `DD/MM/YYYY hh:mm p. m.`.
- **Cantidad de renglones de producto**: Generalmente entre 1 y 4 productos al azar (a menos que el monto requiera más o el usuario pida una cantidad específica).
