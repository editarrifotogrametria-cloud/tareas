# ⚡ Inicio Rápido - GNSS Point Collector

## 🚀 Empezar en 3 pasos

### Paso 1: Extraer archivos
```bash
# Descomprime el ZIP en una carpeta
unzip gnss-comnav-app.zip
cd gnss-comnav-app
```

### Paso 2: Iniciar servidor

**Linux/macOS:**
```bash
./start.sh
```

**Windows:**
```bash
start.bat
```

**O manualmente:**
```bash
# Python
python -m http.server 8080

# Node.js
npx http-server -p 8080
```

### Paso 3: Abrir en navegador
```
http://localhost:8080
```

---

## 📡 Conexión Rápida con Receptor Comnav

### WiFi (Recomendado)

1. **Conectar al WiFi del receptor**
   - Busca red: `Comnav_XXXX`
   - Password: (ver manual del receptor)

2. **En la app**
   - La conexión es automática
   - IP por defecto: `192.168.1.100` o `192.168.0.100`

3. **Verificar conexión**
   - Dashboard debe mostrar: "Connected"
   - Satélites deben aparecer en unos segundos

### Bluetooth

1. **Emparejar dispositivo**
   - Bluetooth → Buscar → Comnav_XXXX
   - Código: `0000` o `1234`

2. **En la app**
   - Settings → Connection → Bluetooth
   - Select device → Connect

---

## 🎯 Primer Punto - Tutorial

### 1. Verificar Estado
✅ **Solución: FIX** (verde)  
✅ **Satélites: >8**  
✅ **Precisión H: <2cm**  
✅ **Precisión V: <5cm**  

### 2. Tomar Punto
```
1. Dashboard → Botón "Take Point"
2. Espera confirmación (sonido/vibración)
3. Punto guardado automáticamente
```

### 3. Ver Puntos
```
Menu → Survey Projects → Ver lista de puntos
```

### 4. Exportar
```
Survey Projects → Export → Seleccionar formato (CSV/KML)
```

---

## ⚙️ Configuración RTK (Opcional)

Si necesitas correcciones RTK para precisión centimétrica:

### NTRIP (Internet)

```
1. Menu → Correction Input
2. Tipo: NTRIP Client
3. Configurar:
   - Host: rtk2go.com
   - Puerto: 2101
   - User: tu_email@example.com
   - Mountpoint: RTCM32_GG (o el tuyo)
4. Connect
```

### Base Local (Radio/LoRa)

```
1. Menu → Correction Input
2. Tipo: Serial / TCP / Bluetooth
3. IP de la base: 192.168.1.200
4. Puerto: 5000
5. Connect
```

---

## 📊 Formato de Datos Exportados

### CSV
```csv
Point,Lat,Lon,Height,PrecH,PrecV,Sats,Time
1,-12.0456,-77.0123,150.234,0.014,0.022,12,2025-01-01T10:30:15
```

### KML (Google Earth)
```
Directo import en Google Earth Pro
```

### GeoJSON
```json
{
  "type": "FeatureCollection",
  "features": [...]
}
```

---

## 🆘 Problemas Comunes

### ❌ No conecta al receptor
```
→ Verifica WiFi/Bluetooth
→ Ping 192.168.1.100 (en terminal)
→ Reinicia receptor y app
```

### ❌ No obtengo FIX
```
→ Cielo despejado necesario
→ Verifica correcciones RTK llegando
→ Espera 1-2 minutos para convergencia
```

### ❌ Puntos no se guardan
```
→ Permite permisos de almacenamiento
→ Verifica espacio en disco
→ Usa Export para backup manual
```

---

## 💡 Consejos Pro

1. **Siempre espera FIX** antes de puntos críticos
2. **Check baseline** si usas RTK (<10km)
3. **Exporta cada hora** como backup
4. **Calibra altura antena** antes de iniciar
5. **Usa averaging** para puntos de control

---

## 📞 Ayuda

**Consola del navegador (F12)** para ver errores  
**Manual Comnav** para configuración receptor  
**Proveedor NTRIP** para mountpoints

---

¡Listo! Ya puedes empezar a tomar puntos. 🎉
