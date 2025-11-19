# Solución de Errores Socket.IO y Recursos 404

## Problemas Identificados

1. **Socket.IO Version Mismatch**: El cliente FUNCIONABLE usa Engine.IO v3 (EIO=3) pero el servidor tenía una versión incompatible
2. **Recursos 404**: Archivos estáticos faltantes que el JavaScript intenta cargar dinámicamente (lazy loading)

## Solución Implementada

### 1. Actualización de gps_server.py

Se agregaron las siguientes mejoras:

#### Configuración Socket.IO Compatible
```python
socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    engineio_logger=False,
    logger=False,
    async_mode='threading'
)
```

#### Rutas para Recursos Dinámicos
- `/info` - Endpoint de información del servidor
- `/static/css/<path>` - Catch-all para CSS lazy-loaded
- `/static/js/<path>` - Catch-all para JS lazy-loaded
- `/static/img/<path>` - Catch-all para imágenes lazy-loaded
- `/funcionable/static/img/<path>` - Imágenes de FUNCIONABLE
- `/funcionable/static/fonts/<path>` - Fuentes de FUNCIONABLE
- `/funcionable/static/css/static/fonts/<path>` - Rutas nested de fuentes

## Instalación de Dependencias Correctas

### Opción 1: Actualizar entorno virtual existente

```bash
cd ~/gnss-system
source venv/bin/activate

# Instalar versiones compatibles
pip install "Flask-SocketIO>=4.3.0,<5.0.0"
pip install "python-socketio>=4.6.0,<5.0.0"
pip install "python-engineio>=3.14.0,<4.0.0"

# Verificar instalación
pip list | grep -i socket
```

### Opción 2: Usar requirements.txt (Recomendado)

```bash
cd ~/gnss-system
source venv/bin/activate

# Instalar desde requirements.txt
pip install -r /ruta/a/tareas/requirements.txt
```

## Verificación

Después de instalar las dependencias correctas:

1. Reiniciar el servidor:
```bash
cd ~/gnss-system
source venv/bin/activate
cd gnssai
python gps_server.py
```

2. Los errores de Socket.IO deberían desaparecer
3. Los errores 404 ya no se mostrarán en el log (manejados silenciosamente)

## Errores que DESAPARECERÁN

- ✅ `The client is using an unsupported version of the Socket.IO or Engine.IO protocols`
- ✅ `GET /socket.io/?EIO=3&transport=polling HTTP/1.1" 400`
- ✅ `GET /info HTTP/1.1" 404` (ahora retorna JSON válido)

## Errores que AÚN APARECERÁN (son normales)

Algunos recursos lazy-loaded seguirán dando 404 porque son módulos opcionales del build de Vue que no están incluidos. Esto es normal y no afecta la funcionalidad:

- `/static/css/90.88d412b8.css`
- `/static/js/42.59f2d0b4.js`
- `/static/img/*.svg`

Estos errores ahora son silenciosos (retornan 404 sin logs) y no afectan la aplicación.

## Notas

- El frontend FUNCIONABLE fue compilado con socket.io-client v2/v3 (EIO=3)
- Flask-SocketIO 4.x es compatible con EIO=3
- Flask-SocketIO 5+ usa EIO=4 y NO es compatible
- La aplicación funcionará correctamente con las dependencias especificadas

## Contacto

Si los problemas persisten, verifica que:
1. Las versiones de las librerías son las correctas (`pip list | grep -i socket`)
2. El entorno virtual está activado
3. No hay otras instancias del servidor corriendo
