# 🛰️ GPS Professional - Guía de Uso

## Características Principales

### ✨ **NUEVA APLICACIÓN PROFESIONAL**
Accede a: **http://localhost:5000/professional**

La aplicación GPS Professional incluye TODAS las funcionalidades que necesitas:

---

## 📋 **1. PROYECTOS**
- **Crear Proyectos**: Organiza tus trabajos por proyecto
- **Cargar Proyectos**: Selecciona y cambia entre proyectos existentes
- **Eliminar Proyectos**: Gestión completa de proyectos
- **Información**: Visualiza puntos, fotos y fecha de creación

### Cómo usar:
1. Ve a la pestaña "📋 Proyecto"
2. Escribe el nombre del nuevo proyecto
3. Haz clic en "✨ Crear Proyecto"
4. Selecciona el proyecto activo desde el menú desplegable

---

## ⚙️ **2. CONFIGURACIÓN**

### **Selección de DATUM**
Datums disponibles:
- **WGS84** (GPS Mundial) - Por defecto
- **SIRGAS 2000** (América Latina)
- **NAD83** (Norte América)
- **ETRS89** (Europa)
- **GDA2020** (Australia)
- **PSAD56** (Sudamérica)

### **Sistema de Coordenadas**
- Geográficas (Lat/Lon)
- UTM
- Locales

### **Formato de Altura**
- Elipsoidal
- Ortométrica

### **Conexión GPS**
1. Configura la URL del servidor (por defecto: http://localhost:5000)
2. Haz clic en "🔌 Conectar GPS"
3. El indicador de estado cambiará a verde cuando esté conectado

---

## 📍 **3. TOMAR PUNTOS**

### Visualización en Tiempo Real:
- **Calidad del FIX**: NO FIX / GPS / DGPS / RTK FLOAT / RTK FIXED
- **Coordenadas**: Latitud, Longitud, Altura
- **Estadísticas**: Satélites, HDOP, Precisión en cm

### Captura de Puntos:
1. Espera a tener un FIX válido (mínimo GPS, ideal RTK FIXED)
2. Ingresa el nombre del punto (ej: P1, ESQ1, BM1)
3. Agrega descripción opcional
4. Haz clic en "📍 TOMAR PUNTO"

### Datos Capturados:
- Coordenadas (Lat, Lon, Alt)
- Calidad del FIX
- Número de satélites
- HDOP
- Precisión estimada (cm)
- DATUM configurado
- Timestamp
- Datos TILT (si está activado)

### Exportar Puntos:
- Haz clic en "📥 Exportar CSV"
- Archivo incluye: Nombre, Descripción, Coordenadas, Calidad, Satelites, HDOP, Precisión, DATUM, Fecha

---

## 🎯 **4. REPLANTEAR PUNTOS**

### Preparación:
1. Crea un archivo CSV con formato:
   ```
   Nombre,Latitud,Longitud,Altura
   P1,-12.046374,-77.042793,154.5
   P2,-12.046380,-77.042800,155.2
   ```

2. Sube el archivo en la pestaña "🎯 Replantear"

### Navegación:
- Selecciona el punto a replantear
- Haz clic en "🎯 IR"
- La aplicación mostrará en tiempo real:
  - **DISTANCIA**: metros hasta el punto
  - **AZIMUT**: dirección (grados)
  - **Δ ALTURA**: diferencia de altura

### Replanteo Preciso:
- Muévete hasta que la distancia sea < 1cm
- Verifica el azimut para la dirección correcta
- Compensa la altura según Δ ALTURA

---

## 🔧 **5. COMANDOS PPP (Post-Processing)**

### Servicios PPP Disponibles:
- **CSRS-PPP** (Canadá)
- **AUSPOS** (Australia)
- **OPUS** (USA)
- **IBGE-PPP** (Brasil)

### Comandos:
1. **▶️ START**: Inicia grabación de datos RINEX
2. **⏹️ STOP**: Detiene la grabación
3. **📥 DOWNLOAD**: Descarga archivo RINEX
4. **☁️ UPLOAD**: Sube a servicio PPP para procesamiento

### Configuración:
- Selecciona servicio PPP
- Define duración de observación (recomendado: 15-60 min)
- Tiempo mínimo: 15 minutos
- Para precisión milimétrica: 4+ horas

---

## 📐 **6. TILT (Compensación de Inclinación)**

### ¿Qué es TILT?
Permite medir con el jalón inclinado, la antena GPS compensa automáticamente la inclinación.

### Activación:
1. Ve a la pestaña "📐 TILT"
2. Haz clic en "✅ ACTIVAR TILT"
3. Configura la altura de antena (metros)

### Visualización:
- **Burbuja virtual**: Muestra inclinación en tiempo real
- **PITCH**: Inclinación adelante/atrás
- **ROLL**: Inclinación lateral
- **HEADING**: Dirección de la inclinación

### Ventajas:
- No necesitas nivelar el jalón
- Mayor rapidez en mediciones
- Útil en terrenos difíciles
- Precisión mantenida con inclinaciones hasta 30°

---

## 📷 **7. CÁMARA CON GEOLOCALIZACIÓN**

### Características:
- ✅ Captura fotos con coordenadas GPS
- ✅ Metadatos EXIF completos
- ✅ Datum incluido en EXIF
- ✅ Timestamp automático
- ✅ Descripción personalizada

### Uso:
1. Ve a la pestaña "📷 Cámara"
2. Haz clic en el botón de cámara para iniciar
3. Permite acceso a la cámara del dispositivo
4. Escribe una descripción
5. Haz clic en ✓ para capturar

### Metadatos EXIF Incluidos:
```json
{
  "GPSLatitude": -12.046374,
  "GPSLongitude": -77.042793,
  "GPSAltitude": 154.5,
  "GPSDatum": "WGS84",
  "DateTime": "2024-01-15T14:30:00Z",
  "Make": "GPS Professional App",
  "Description": "Tu descripción"
}
```

### Exportar Fotos:
- Haz clic en "📥 Exportar Fotos"
- Se descarga un archivo JSON con:
  - Imágenes en base64
  - Coordenadas GPS
  - Metadatos EXIF completos
  - Información del proyecto

---

## 🚀 **INICIO RÁPIDO**

### 1. Iniciar el Servidor:
```bash
cd /home/user/tareas
python3 gps_server.py
```

### 2. Acceder a la Aplicación:
```
http://localhost:5000/professional
```

### 3. Workflow Típico:

#### **A. Levantamiento Topográfico:**
1. Crear proyecto nuevo
2. Configurar DATUM (ej: SIRGAS 2000)
3. Conectar GPS
4. Activar TILT (opcional)
5. Tomar puntos
6. Tomar fotos de referencia
7. Exportar CSV

#### **B. Replanteo:**
1. Cargar proyecto
2. Subir archivo de puntos a replantear
3. Conectar GPS
4. Navegar a cada punto
5. Replantear con precisión

#### **C. Medición PPP:**
1. Configurar servicio PPP
2. Iniciar grabación RINEX
3. Esperar tiempo recomendado (15-60 min)
4. Detener grabación
5. Descargar y subir a servicio PPP

---

## 📱 **COMPATIBILIDAD**

### Dispositivos:
- ✅ Smartphones (Android/iOS)
- ✅ Tablets
- ✅ Laptops/PC
- ✅ Raspberry Pi con pantalla táctil

### Navegadores:
- Chrome/Chromium (recomendado)
- Safari (iOS)
- Firefox
- Edge

### Permisos Necesarios:
- 📍 Geolocalización
- 📷 Cámara
- 💾 Almacenamiento local

---

## 💡 **TIPS Y BUENAS PRÁCTICAS**

### Toma de Puntos:
- ✅ Espera RTK FIXED para máxima precisión
- ✅ Usa TILT solo cuando sea necesario
- ✅ Toma fotos de cada punto importante
- ✅ Agrega descripciones descriptivas

### Gestión de Proyectos:
- ✅ Usa nombres descriptivos
- ✅ Exporta CSV regularmente
- ✅ Mantén backup de proyectos

### Replanteo:
- ✅ Verifica el DATUM antes de replantear
- ✅ Usa RTK FIXED para precisión cm
- ✅ Confirma la altura de antena

### Cámara:
- ✅ Toma fotos con GPS conectado
- ✅ Agrega descripciones claras
- ✅ Exporta periódicamente

---

## ⚠️ **SOLUCIÓN DE PROBLEMAS**

### Error "No se puede conectar al GPS":
- Verifica que gps_server.py esté corriendo
- Confirma la URL en Configuración
- Revisa el firewall

### No aparecen datos GPS:
- Verifica que gnssai_collector.py esté corriendo
- Revisa que el receptor GPS esté conectado
- Espera unos segundos para adquisición de satélites

### La cámara no funciona:
- Permite permisos de cámara en el navegador
- Usa HTTPS si es posible (algunos navegadores lo requieren)
- Verifica que no haya otra app usando la cámara

### Los proyectos no se guardan:
- Verifica que el navegador permita localStorage
- No uses modo incógnito
- Exporta CSV como backup

---

## 📊 **ESPECIFICACIONES TÉCNICAS**

### Almacenamiento:
- **LocalStorage**: Proyectos, configuración, fotos
- **IndexedDB**: No usado (futuro)
- **Límite**: ~5-10 MB por navegador

### Precisión:
- **RTK FIXED**: ±1-2 cm
- **RTK FLOAT**: ±10-30 cm
- **DGPS**: ±0.5-2 m
- **GPS**: ±3-10 m

### Formatos de Exportación:
- **Puntos**: CSV (compatible con CAD, GIS)
- **Fotos**: JSON con base64 + EXIF
- **RINEX**: .obs, .nav (PPP)

---

## 🎓 **CAPACITACIÓN**

### Orden Recomendado de Aprendizaje:
1. Familiarízate con la interfaz
2. Practica tomar puntos en modo GPS
3. Aprende a crear y gestionar proyectos
4. Experimenta con TILT
5. Practica replanteo con puntos conocidos
6. Aprende PPP para alta precisión
7. Integra la cámara en tu workflow

---

## 📞 **SOPORTE**

Para problemas o consultas:
1. Revisa esta documentación
2. Verifica los logs del servidor
3. Revisa la consola del navegador (F12)

---

## 🔄 **ACTUALIZACIONES**

### Versión 1.0 (Actual):
- ✅ Gestión de proyectos
- ✅ Selección de DATUM
- ✅ Toma de puntos
- ✅ Replanteo
- ✅ Comandos PPP
- ✅ Compensación TILT
- ✅ Cámara con EXIF

### Próximas Mejoras:
- 🔄 Exportación DXF/DWG
- 🔄 Mapas en tiempo real
- 🔄 Cálculo de áreas/volúmenes
- 🔄 Sincronización cloud

---

**¡Disfruta de GPS Professional! 🛰️**
