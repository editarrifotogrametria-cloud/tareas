#!/usr/bin/env python3
"""
Test script para enviar comandos al ComNav K222
Útil para pruebas rápidas sin la interfaz web
"""

import serial
import time
import sys

def send_command(port, command, timeout=2):
    """Envía un comando al módulo ComNav y muestra la respuesta."""
    try:
        with serial.Serial(port, 115200, timeout=timeout) as ser:
            # Enviar comando
            cmd_str = f"{command}\r\n"
            print(f"📤 Enviando: {command}")
            ser.write(cmd_str.encode())

            # Esperar respuesta
            time.sleep(0.5)

            # Leer respuesta
            if ser.in_waiting:
                response = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                print(f"📥 Respuesta:")
                print(response)
            else:
                print("⚠️  Sin respuesta")

            return True

    except serial.SerialException as e:
        print(f"❌ Error de puerto serie: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Función principal."""
    print("=" * 60)
    print("🛰️  ComNav K222 - Test de Comandos")
    print("=" * 60)

    # Puerto serie (ajustar si es necesario)
    port = '/dev/serial0'

    if len(sys.argv) > 1:
        # Modo comando único
        command = ' '.join(sys.argv[1:])
        send_command(port, command)
    else:
        # Modo interactivo
        print("\n💡 Modo interactivo - Escribe comandos para enviar al módulo")
        print("   Ejemplos:")
        print("   - log com1 gpgga ontime 1")
        print("   - log com1 gpnav ontime 1")
        print("   - INSMODE ENABLE 6")
        print("   - saveconfig")
        print("   - unlogall")
        print("\n   Escribe 'exit' para salir\n")

        while True:
            try:
                command = input("ComNav> ").strip()

                if command.lower() in ['exit', 'quit', 'q']:
                    print("\n👋 ¡Hasta luego!")
                    break

                if not command:
                    continue

                send_command(port, command)
                print()

            except KeyboardInterrupt:
                print("\n\n👋 ¡Hasta luego!")
                break
            except Exception as e:
                print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
