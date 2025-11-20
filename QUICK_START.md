# 🚀 Guía Rápida - GNSS.AI Point Collector

## ⚡ Instalación en 5 Pasos

### 1️⃣ Preparar Hardware

**Conexiones K222 → Raspberry Pi:**
```
K222 Pin    →  Raspberry Pi Pin
─────────────────────────────────
TXD1        →  GPIO 15 (Pin 10)
RXD1        →  GPIO 14 (Pin 8)
GND         →  GND (Pin 6)
VCC         →  5V (Pin 2 o 4)
```

### 2️⃣ Flashear Raspberry Pi OS

1. Descargar **Raspberry Pi Imager**: https://www.raspberrypi.com/software/
2. Seleccionar **Raspberry Pi OS Lite (64-bit)**
3. Configurar WiFi y SSH en opciones avanzadas (⚙️)
4. Flashear en tarjeta microSD
5. Insertar en Pi Zero 2W y encender

### 3️⃣ Conectar por SSH

```bash
# Desde tu computadora
ssh pi@raspberrypi.local
# Contraseña: la que configuraste
```

### 4️⃣ Instalar Sistema

```bash
# Clonar repositorio
git clone https://github.com/editarrifotogrametria-cloud/tareas.git gnssai
cd gnssai

# Ejecutar instalador
chmod +x install_pi_zero.sh
./install_pi_zero.sh

# Seguir instrucciones en pantalla
# (responder 'y' a las preguntas)
```

### 5️⃣ Reiniciar y Usar

```bash
# Reiniciar Pi
sudo reboot

# Esperar 30 segundos...

# Desde tu celular, abrir navegador:
http://192.168.4.1:8080
# (Si configuraste WiFi Hotspot)

# O desde la misma red WiFi:
http://[IP-DE-TU-PI]:8080
```

---

## 📱 Uso desde el Celular

### Primera Vez

1. **Conectar WiFi**:
   - SSID: `GNSS-AI-Collector`
   - Contraseña: `gnssai2024`

2. **Abrir navegador**:
   - URL: `http://192.168.4.1:8080`

3. **Instalar como App** (opcional):
   - Chrome Android: Menú → "Agregar a pantalla de inicio"
   - Safari iOS: Compartir → "Agregar a pantalla de inicio"

### Tomar Puntos

1. Esperar que aparezca **"RTK FIXED"** (verde)
2. Presionar botón grande **📍 TOMAR PUNTO**
3. ✅ Punto guardado

### Exportar Datos

- Presionar **📄 Exportar CSV** (Excel)
- O presionar **💾 Exportar JSON** (programación)
- Archivo se descarga automáticamente

---

## 🔍 Verificar que Funciona

### Ver datos NMEA en vivo
```bash
ssh pi@raspberrypi.local
sudo cat /dev/serial0
# Deberías ver frases NMEA pasando
# Presiona Ctrl+C para salir
```

### Ver logs del sistema
```bash
# Log del procesador GNSS
sudo journalctl -u gnssai-processor -f

# Log de la aplicación web
sudo journalctl -u gnssai-collector -f
```

### Verificar servicios
```bash
sudo systemctl status gnssai-processor
sudo systemctl status gnssai-collector
# Ambos deben mostrar "active (running)"
```

---

## 🆘 Problemas Comunes

### ❌ No veo datos NMEA

**Solución**: Verificar conexiones físicas
```bash
# Test 1: ¿Existe el puerto serial?
ls -l /dev/serial0

# Test 2: ¿Recibe datos?
sudo cat /dev/serial0
# Si no sale nada: revisar cables

# Test 3: ¿Baudrate correcto?
# Editar smart_processor.py línea 39
nano ~/gnssai/smart_processor.py
# Cambiar: self.uart_baud = 115200 a 230400 si es necesario
```

### ❌ Aplicación no carga

**Solución**: Reiniciar servicios
```bash
sudo systemctl restart gnssai-processor
sudo systemctl restart gnssai-collector

# Esperar 10 segundos y volver a intentar
```

### ❌ No aparece WiFi "GNSS-AI-Collector"

**Solución**: Configurar hotspot manualmente
```bash
# Ver estado
sudo systemctl status hostapd

# Si no está instalado:
sudo apt-get install hostapd dnsmasq
sudo systemctl enable hostapd
sudo systemctl start hostapd
```

### ❌ Botón "Tomar Punto" deshabilitado

**Causas posibles**:
- ⏳ K222 sin fix GPS (esperar)
- ⏳ Datos GNSS no llegan (ver logs)
- ⏳ Calidad < 1 (necesita al menos GPS fix)

**Solución**: Esperar o llevar equipo a cielo abierto

---

## 📞 Ayuda Rápida

| Problema | Comando |
|----------|---------|
| Ver logs | `sudo journalctl -u gnssai-processor -f` |
| Reiniciar sistema | `sudo systemctl restart gnssai-*` |
| Ver IP de la Pi | `hostname -I` |
| Test UART | `sudo cat /dev/serial0` |
| Estado servicios | `sudo systemctl status gnssai-*` |

---

## ✅ Checklist de Instalación

- [ ] Hardware conectado correctamente
- [ ] Raspberry Pi OS instalado
- [ ] SSH funcionando
- [ ] Repositorio clonado
- [ ] `install_pi_zero.sh` ejecutado
- [ ] Sistema reiniciado
- [ ] Servicios corriendo (status = active)
- [ ] NMEA visible en `/dev/serial0`
- [ ] Aplicación accesible en navegador
- [ ] WiFi Hotspot funcionando (opcional)

---

## 🎓 Próximos Pasos

Una vez funcionando:

1. **Leer documentación completa**: `README_POINT_COLLECTOR.md`
2. **Entender arquitectura**: `CLAUDE.md`
3. **Personalizar configuración**: Editar archivos .py
4. **Entrenar modelo ML**: Seguir guía de ML en CLAUDE.md
5. **Configurar backup automático**: Programar exports

---

**¿Todo listo? ¡A tomar puntos! 📍**

---

**Soporte**: Ver `README_POINT_COLLECTOR.md` para documentación completa
