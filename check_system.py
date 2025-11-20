#!/usr/bin/env python3
"""
Sistema de verificación para GNSS.AI
Verifica dependencias, configuración y funcionamiento del sistema
"""

import sys
import os
import subprocess

def check_python_version():
    """Verificar versión de Python"""
    print("🔍 Verificando Python...")
    version = sys.version_info
    if version.major == 3 and version.minor >= 7:
        print(f"   ✅ Python {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print(f"   ❌ Python {version.major}.{version.minor}.{version.micro} (se requiere 3.7+)")
        return False

def check_module(module_name, package_name=None):
    """Verificar si un módulo Python está instalado"""
    if package_name is None:
        package_name = module_name

    try:
        __import__(module_name)
        print(f"   ✅ {package_name}")
        return True
    except ImportError:
        print(f"   ❌ {package_name} - pip3 install {package_name}")
        return False

def check_python_modules():
    """Verificar módulos Python requeridos"""
    print("\n🔍 Verificando módulos Python...")

    modules = {
        'serial': 'pyserial',
        'flask': 'flask',
        'flask_socketio': 'flask-socketio',
        'simple_websocket': 'simple-websocket',
    }

    all_ok = True
    for module, package in modules.items():
        if not check_module(module, package):
            all_ok = False

    # Módulos opcionales
    print("\n🔍 Módulos opcionales:")
    optional = {
        'bluetooth': 'pybluez',
        'numpy': 'numpy',
        'pandas': 'pandas',
        'sklearn': 'scikit-learn',
    }

    for module, package in optional.items():
        check_module(module, package)

    return all_ok

def check_serial_port():
    """Verificar puerto serial"""
    print("\n🔍 Verificando puerto serial...")
    port = "/dev/serial0"

    if os.path.exists(port):
        print(f"   ✅ {port} existe")

        # Verificar permisos
        if os.access(port, os.R_OK | os.W_OK):
            print(f"   ✅ Permisos OK")
            return True
        else:
            print(f"   ⚠️  Sin permisos - ejecutar: sudo usermod -a -G dialout $USER")
            return False
    else:
        print(f"   ❌ {port} no existe")
        print("      Verificar que UART esté habilitado en /boot/config.txt")
        return False

def check_directories():
    """Verificar estructura de directorios"""
    print("\n🔍 Verificando directorios...")

    dirs = ['point_data', 'ml_training_data', 'ml_models', 'templates', 'static']
    all_ok = True

    for dirname in dirs:
        if os.path.isdir(dirname):
            print(f"   ✅ {dirname}/")
        else:
            print(f"   ⚠️  {dirname}/ no existe - se creará automáticamente")
            try:
                os.makedirs(dirname, exist_ok=True)
                print(f"      ✅ {dirname}/ creado")
            except:
                all_ok = False

    return all_ok

def check_services():
    """Verificar servicios systemd"""
    print("\n🔍 Verificando servicios systemd...")

    services = ['gnssai-processor', 'gnssai-collector']

    for service in services:
        try:
            result = subprocess.run(
                ['systemctl', 'is-active', f'{service}.service'],
                capture_output=True,
                text=True
            )

            if result.stdout.strip() == 'active':
                print(f"   ✅ {service}.service está activo")
            else:
                print(f"   ⚠️  {service}.service no está activo")
                print(f"      Iniciar con: sudo systemctl start {service}.service")
        except FileNotFoundError:
            print(f"   ℹ️  systemctl no disponible (¿no es Raspberry Pi?)")
            break
        except:
            print(f"   ⚠️  No se pudo verificar {service}.service")

def check_files():
    """Verificar archivos principales"""
    print("\n🔍 Verificando archivos principales...")

    files = [
        'smart_processor.py',
        'point_collector_app.py',
        'dashboard_server.py',
        'ml_classifier.py',
        'requirements.txt',
        'install_pi_zero.sh',
    ]

    all_ok = True
    for filename in files:
        if os.path.isfile(filename):
            print(f"   ✅ {filename}")
        else:
            print(f"   ❌ {filename} no encontrado")
            all_ok = False

    return all_ok

def main():
    """Ejecutar todas las verificaciones"""
    print("=" * 70)
    print("🛰️  GNSS.AI - Verificación del Sistema")
    print("=" * 70)

    checks = [
        check_python_version(),
        check_python_modules(),
        check_serial_port(),
        check_directories(),
        check_files(),
    ]

    check_services()

    print("\n" + "=" * 70)

    if all(checks):
        print("✅ SISTEMA VERIFICADO - Todo OK")
        print("\nPróximos pasos:")
        print("  1. Conectar módulo K222 al UART")
        print("  2. Ejecutar: python3 point_collector_app.py")
        print("  3. Abrir navegador: http://localhost:8080")
        return 0
    else:
        print("⚠️  VERIFICACIÓN INCOMPLETA - Revisar errores arriba")
        print("\nPara instalar dependencias faltantes:")
        print("  pip3 install -r requirements.txt")
        return 1

if __name__ == "__main__":
    sys.exit(main())
