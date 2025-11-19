# ⚡ Quick Start - Pi Zero Installation

## 🚀 Instalación en 2 Pasos

### 1️⃣ Conectarse a la Pi Zero

```bash
ssh pi@raspberrypi.local
# Password: raspberry
```

### 2️⃣ Ejecutar Script de Instalación

```bash
curl -sSL https://raw.githubusercontent.com/editarrifotogrametria-cloud/tareas/claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D/quick_install_pi.sh | bash
```

**O descargarlo y ejecutar:**

```bash
wget https://raw.githubusercontent.com/editarrifotogrametria-cloud/tareas/claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D/quick_install_pi.sh

chmod +x quick_install_pi.sh
./quick_install_pi.sh
```

---

## 🎯 Instalación Manual (Si prefieres control total)

### Opción Simple:

```bash
# 1. Clonar repositorio
cd ~
git clone -b claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D \
  https://github.com/editarrifotogrametria-cloud/tareas.git gnss-system

# 2. Instalar dependencias del sistema
cd gnss-system
sudo apt-get update
sudo apt-get install -y python3-pip python3-serial python3-venv

# 3. Crear entorno virtual e instalar dependencias Python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Iniciar servidor
cd gnssai
python gps_server.py
```

---

## 📱 Acceder a las Aplicaciones

Una vez iniciado el servidor, abre tu navegador:

```
http://<IP_DE_TU_PI>:5000
```

**Aplicaciones disponibles:**

- 🌟 **FUNCIONABLE** → `/funcionable` (Principal)
- ⚙️ **ComNav Control** → `/comnav` (TILT avanzado)
- 🎯 **GPS Professional** → `/professional`
- 📍 **Point Collector** → `/collector`
- 📊 **Dashboard** → `/dashboard`

### Encontrar la IP de tu Pi:

```bash
hostname -I
# Ejemplo: 192.168.1.100
```

---

## ✅ ¡Eso es todo!

Tu sistema GPS profesional está listo con:
- ✅ FUNCIONABLE completo
- ✅ TILT/INS avanzado
- ✅ Control ComNav K222
- ✅ 5 interfaces GPS diferentes

Para más detalles: [INSTALL_PI_ZERO.md](INSTALL_PI_ZERO.md)
