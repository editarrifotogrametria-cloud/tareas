#!/bin/bash
# Script para arreglar Socket.IO v3 en archivos compilados de FUNCIONABLE
# Convierte EIO=3 a EIO=4 para compatibilidad con Flask-SocketIO v5+

echo "=========================================="
echo "🔧 Arreglando Socket.IO en FUNCIONABLE"
echo "=========================================="
echo ""

FUNCIONABLE_DIR=~/gnss-system/funcionable

if [ ! -d "$FUNCIONABLE_DIR" ]; then
    echo "❌ Error: No se encuentra $FUNCIONABLE_DIR"
    echo "   Primero ejecuta: ./integrar_funcionable.sh"
    exit 1
fi

echo "📁 Directorio FUNCIONABLE: $FUNCIONABLE_DIR"
echo ""

# Buscar archivos JavaScript que usen Socket.IO
echo "🔍 Buscando archivos JavaScript..."
JS_FILES=$(find "$FUNCIONABLE_DIR" -name "*.js" -type f)

if [ -z "$JS_FILES" ]; then
    echo "⚠️  No se encontraron archivos JavaScript"
    exit 1
fi

echo "✅ Archivos encontrados:"
echo "$JS_FILES" | while read file; do
    echo "   - $(basename $file)"
done
echo ""

# Hacer backup
echo "💾 Creando backup..."
BACKUP_DIR="$FUNCIONABLE_DIR/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "$JS_FILES" | while read file; do
    cp "$file" "$BACKUP_DIR/"
done

echo "✅ Backup creado en: $BACKUP_DIR"
echo ""

# Aplicar parches
echo "🔧 Aplicando parches Socket.IO..."

PATCHED=0
echo "$JS_FILES" | while read file; do
    filename=$(basename "$file")

    # Verificar si el archivo contiene Socket.IO v3
    if grep -q "EIO=3" "$file" 2>/dev/null; then
        echo "   📝 Parchando: $filename"

        # Reemplazar EIO=3 por EIO=4
        sed -i 's/EIO=3/EIO=4/g' "$file"

        # Reemplazar otras referencias a Engine.IO v3
        sed -i 's/engineio-client@3/engineio-client@4/g' "$file"
        sed -i 's/socket\.io-client@2/socket.io-client@4/g' "$file"

        PATCHED=$((PATCHED + 1))
    fi
done

echo ""
if [ $PATCHED -gt 0 ]; then
    echo "✅ $PATCHED archivo(s) parcheado(s)"
else
    echo "ℹ️  No se encontraron referencias a EIO=3"
    echo "   Posiblemente FUNCIONABLE ya usa Socket.IO moderno"
fi

echo ""
echo "=========================================="
echo "✅ PARCHE COMPLETADO"
echo "=========================================="
echo ""
echo "📝 Notas:"
echo "  - Los archivos originales están en: $BACKUP_DIR"
echo "  - Si algo falla, puedes restaurarlos desde ahí"
echo ""
echo "🚀 Siguiente paso:"
echo "   cd ~/gnss-system"
echo "   ./start_funcionable.sh"
echo ""
