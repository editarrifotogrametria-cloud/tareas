# 🔧 Solución Socket.IO Compatibility Error en Pi Zero

## 📋 Problema Identificado

Estás viendo estos errores en el servidor:

```
The client is using an unsupported version of the Socket.IO or Engine.IO protocols
GET /socket.io/?EIO=3&transport=polling HTTP/1.1" 400
```

**Causa**: El servidor tiene instalado Flask-SocketIO 5.x que solo soporta Engine.IO v4, pero el cliente FUNCIONABLE usa Engine.IO v3 (EIO=3).

**Solución**: Instalar Flask-SocketIO 4.x que soporta tanto EIO=3 como EIO=4.

## 🚀 Solución Rápida (Recomendada)

En tu Pi Zero, ejecuta:

```bash
cd ~/gnss-system
./fix_socketio_pi.sh
```

Este script automáticamente:
1. ✅ Desinstala versiones incompatibles
2. ✅ Instala versiones correctas desde requirements.txt
3. ✅ Verifica que las versiones sean correctas
4. ✅ Fuerza reinstalación si hay problemas

## 🛠️ Solución Manual

Si prefieres hacerlo manualmente:

```bash
cd ~/gnss-system

# Crear/activar entorno virtual
python3 -m venv venv
source venv/bin/activate

# Limpiar instalaciones anteriores
pip uninstall -y Flask-SocketIO python-socketio python-engineio

# Instalar versiones correctas
pip install -r requirements.txt

# Verificar versiones
pip list | grep -E "socketio|engineio"
```

Deberías ver:
- **Flask-SocketIO 4.x** (NO 5.x)
- **python-socketio 4.x** (NO 5.x)
- **python-engineio 3.x** (NO 4.x)

## ✅ Verificación

Después de la instalación, inicia el servidor:

```bash
cd ~/gnss-system
source venv/bin/activate
cd gnssai
python gps_server.py
```

### ✅ Señales de Éxito

**Desaparecerán:**
- ❌ `The client is using an unsupported version...`
- ❌ `GET /socket.io/?EIO=3 HTTP/1.1" 400`

**Aparecerán:**
- ✅ `🔗 Client connected to /gnss` (cuando abres FUNCIONABLE en el navegador)
- ✅ Datos en tiempo real en la interfaz FUNCIONABLE

### Errores 404 Normales (NO son problemas)

Estos errores son **esperados** y **no afectan** la funcionalidad:
```
GET /static/css/90.88d412b8.css HTTP/1.1" 404
GET /static/js/42.59f2d0b4.js HTTP/1.1" 404
GET /static/img/*.svg HTTP/1.1" 404
```

Son módulos lazy-loaded de Vue que no están incluidos en el build. Se manejan silenciosamente.

## 🔍 Troubleshooting

### Problema: requirements.txt no encontrado

```bash
# Asegúrate de estar en el directorio correcto
cd ~/gnss-system
ls -la requirements.txt  # Debe existir

# Si no existe, crea uno:
cat > requirements.txt << 'EOF'
Flask>=2.0.0,<3.0.0
Flask-Cors>=3.0.10
Flask-SocketIO>=4.3.0,<5.0.0
python-socketio>=4.6.0,<5.0.0
python-engineio>=3.14.0,<4.0.0
pyserial>=3.5
python-dotenv>=0.19.0
EOF
```

### Problema: Siguen apareciendo errores 400

```bash
# Verifica que estás usando el venv
which python  # Debe mostrar: ~/gnss-system/venv/bin/python

# Si no, activa el venv:
cd ~/gnss-system
source venv/bin/activate

# Verifica versiones instaladas
python -c "import flask_socketio; print(flask_socketio.__version__)"
# Debe mostrar: 4.x.x (NO 5.x.x)
```

### Problema: El venv no se activa

```bash
# Elimina venv viejo y crea uno nuevo
cd ~/gnss-system
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 📚 Información Técnica

### ¿Por qué Flask-SocketIO 4.x?

| Versión | Engine.IO | Compatible con FUNCIONABLE |
|---------|-----------|---------------------------|
| Flask-SocketIO 5.x | Solo EIO=4 | ❌ NO |
| Flask-SocketIO 4.x | EIO=3 y EIO=4 | ✅ SÍ |

El frontend FUNCIONABLE fue compilado con `socket.io-client` v2/v3, que usa Engine.IO v3 (EIO=3). Flask-SocketIO 5.x **eliminó** el soporte para EIO=3.

### Archivos Modificados

- ✅ `requirements.txt` - Versiones correctas de dependencias
- ✅ `gnssai/gps_server.py` - Rutas estáticas para FUNCIONABLE
- ✅ `fix_socketio_pi.sh` - Script de reparación automática
- ✅ `quick_install_pi.sh` - Script de instalación actualizado

### Referencias

- [Flask-SocketIO Versiones](https://flask-socketio.readthedocs.io/)
- [Engine.IO Protocol](https://socket.io/docs/v3/engine-io-protocol/)
- Commit: `31b515e` - Fix Socket.IO compatibility

## 🆘 Ayuda Adicional

Si los problemas persisten:

1. Revisa que tengas Python 3.7+: `python3 --version`
2. Verifica permisos del puerto serie: `groups` (debe incluir `dialout`)
3. Reinicia la sesión después de cambiar grupos: `su - $USER`
4. Comparte el output de:
   ```bash
   source venv/bin/activate
   pip list | grep -E "Flask|socket|serial"
   python --version
   ```

---

**Última actualización**: 2025-11-19
**Probado en**: Raspberry Pi Zero, Raspberry Pi 4
**Python**: 3.7+
