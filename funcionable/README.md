# 📍 GNSS Point Collector - Comnav

Aplicación web para toma de puntos GNSS con dispositivos Comnav.

## 🚀 Características

✅ **Conectividad GNSS**
- Conexión con receptores GNSS Comnav
- Soporte para RTK (Real-Time Kinematic)
- Correcciones NTRIP
- Múltiples constelaciones GNSS (GPS, GLONASS, Galileo, BeiDou, QZSS)

✅ **Toma de Puntos**
- Captura de coordenadas (Latitud, Longitud, Altura)
- Visualización en tiempo real
- Precisión horizontal y vertical
- Información de satélites

✅ **Gestión de Proyectos**
- Creación de proyectos de levantamiento
- Exportación de datos
- Almacenamiento local

✅ **Interfaz**
- Dashboard en tiempo real
- Vista de satélites
- Configuración de parámetros
- Modo día/noche

## 📋 Requisitos

- Navegador web moderno (Chrome, Firefox, Edge, Safari)
- Dispositivo GNSS Comnav compatible
- Conexión WiFi o Bluetooth con el receptor

## 🔧 Instalación

### Opción 1: Uso Local (Recomendado)

1. **Descargar los archivos**
   ```bash
   # Descomprime el archivo ZIP o clona el repositorio
   ```

2. **Servir con un servidor web local**
   
   **Python:**
   ```bash
   # Python 3
   cd gnss-comnav-app
   python -m http.server 8080
   ```
   
   **Node.js:**
   ```bash
   # Instalar http-server
   npm install -g http-server
   
   # Ejecutar
   cd gnss-comnav-app
   http-server -p 8080
   ```

3. **Abrir en el navegador**
   ```
   http://localhost:8080
   ```

### Opción 2: Uso Directo (Solo para pruebas)

Abre directamente el archivo `index.html` en tu navegador (algunas funciones pueden estar limitadas).

## 📱 Conexión con el Receptor GNSS

### 1. Conexión WiFi

1. Conecta tu dispositivo a la red WiFi del receptor Comnav
2. La app se conectará automáticamente a la IP del receptor
3. Por defecto: `192.168.1.XXX` o `192.168.0.XXX`

### 2. Conexión Bluetooth

1. Empareja tu dispositivo con el receptor via Bluetooth
2. En la app, selecciona "Bluetooth" como fuente de datos
3. Sigue las instrucciones en pantalla

## 🎯 Uso de la Aplicación

### Dashboard Principal

El dashboard muestra:
- **Estado de la solución**: FIX, FLOAT, SINGLE, NO SOLUTION
- **Satélites visibles**: Cantidad y SNR
- **Coordenadas actuales**: Lat, Lon, Altura
- **Precisión**: Horizontal y vertical
- **Baseline**: Distancia a la base RTK

### Tomar un Punto

1. Espera a tener solución **FIX** para máxima precisión
2. Verifica la cantidad de satélites (recomendado: >8)
3. Haz clic en "Tomar Punto" o botón similar
4. El punto se guardará con:
   - Coordenadas
   - Precisión
   - Timestamp
   - Número de satélites

### Exportar Datos

1. Ve a la sección "Proyectos" o "Survey Projects"
2. Selecciona el proyecto
3. Haz clic en "Exportar"
4. Los datos se descargarán en formato:
   - CSV
   - KML
   - Shapefile (si está disponible)

## ⚙️ Configuración

### Parámetros GNSS

En la sección "Configuración GNSS" puedes ajustar:

- **Tasa de actualización**: 1Hz, 5Hz, 10Hz
- **Constelaciones**: GPS, GLONASS, Galileo, BeiDou, QZSS
- **Máscara de elevación**: Ángulo mínimo de satélites
- **Modo de posicionamiento**: Kinematic, Static

### Correcciones RTK

En "Correction Input" configura:

- **NTRIP Caster**
  - Host: `[tu servidor NTRIP]`
  - Puerto: `2101` (por defecto)
  - Usuario y contraseña
  - Mountpoint

- **Base local**
  - IP de la base
  - Puerto

## 📊 Formatos de Exportación

### CSV
```csv
Point,Latitude,Longitude,Height,Precision_H,Precision_V,Satellites,Timestamp
1,-12.0456789,-77.0123456,150.234,0.014,0.022,12,2025-01-01T10:30:15
2,-12.0457890,-77.0124567,151.456,0.015,0.023,13,2025-01-01T10:31:20
```

### KML (Google Earth)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>Point 1</name>
      <Point>
        <coordinates>-77.0123456,-12.0456789,150.234</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
```

## 🔍 Solución de Problemas

### La app no se conecta al receptor

1. **Verifica la conexión WiFi/Bluetooth**
   - ¿Estás conectado a la red del receptor?
   - ¿El Bluetooth está emparejado?

2. **Verifica la IP del receptor**
   - Accede al panel de configuración del receptor
   - Anota la IP
   - Actualiza en la app si es necesario

3. **Firewall/Antivirus**
   - Asegúrate de que no bloqueen la conexión

### No obtengo solución FIX

1. **Cielo despejado**
   - Necesitas vista clara del cielo
   - Evita árboles, edificios

2. **Correcciones RTK**
   - Verifica que las correcciones estén llegando
   - Check en "Correction Input" → debería mostrar "Receiving"

3. **Baseline**
   - La distancia a la base no debe exceder 10-15 km
   - Para mejor precisión: < 5 km

### Los puntos no se guardan

1. **Verifica el almacenamiento local**
   - El navegador debe permitir LocalStorage

2. **Permisos del navegador**
   - Asegúrate de dar permisos necesarios

## 📁 Estructura de Archivos

```
gnss-comnav-app/
├── index.html              # Archivo principal
├── README.md               # Esta documentación
├── static/
│   ├── css/
│   │   ├── chunk-vendors.css   # Estilos de librerías
│   │   └── index.css           # Estilos principales
│   └── js/
│       ├── chunk-vendors.js    # Vue.js y librerías
│       ├── chunk-common.js     # Código común
│       └── index.js            # Código principal de la app
└── assets/                 # Imágenes y recursos (opcional)
```

## 💡 Tips y Mejores Prácticas

1. **Siempre espera FIX** antes de tomar puntos importantes
2. **Verifica la precisión** en cada punto (debería ser < 2cm H, < 5cm V)
3. **Exporta regularmente** tus proyectos como backup
4. **Usa NTRIP** para RTK en campo abierto
5. **Calibra la altura de la antena** antes de iniciar

## 🆘 Soporte

Para soporte adicional:
- Consulta el manual de tu receptor Comnav
- Verifica la configuración NTRIP con tu proveedor
- Revisa los logs en la consola del navegador (F12)

## 📄 Licencia

Esta aplicación es de uso libre para trabajos topográficos y geodésicos.

---

**¿Necesitas ayuda?** Abre la consola del navegador (F12) y revisa los mensajes de error para diagnóstico.
