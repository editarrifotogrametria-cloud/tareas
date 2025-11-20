#!/usr/bin/env python3
"""
Generador simple de iconos para PWA
Crea iconos de 192x192 y 512x512 con emoji de pin
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("⚠️  Pillow no instalado. Los iconos se generarán manualmente.")
    print("   Para generar iconos automáticamente: pip3 install Pillow")

import os

def create_icon_manual():
    """Crear iconos SVG que pueden convertirse a PNG"""
    svg_template = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="{size}" height="{size}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#22c55e;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#16a34a;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="{size}" height="{size}" fill="url(#grad1)" rx="20"/>
  <text x="50%" y="55%" font-family="Arial" font-size="{font_size}" fill="white"
        text-anchor="middle" dominant-baseline="middle">📍</text>
</svg>"""

    sizes = [192, 512]

    for size in sizes:
        font_size = int(size * 0.6)
        svg_content = svg_template.format(size=size, font_size=font_size)

        filename = f"static/icon-{size}.svg"
        os.makedirs('static', exist_ok=True)

        with open(filename, 'w') as f:
            f.write(svg_content)

        print(f"✅ Creado: {filename}")

    print("\n📝 Nota: Para mejor compatibilidad, convierte los SVG a PNG:")
    print("   Usa herramientas online como: https://svgtopng.com/")
    print("   O instala ImageMagick: convert icon-192.svg icon-192.png")

def create_icon_with_pil():
    """Crear iconos PNG con Pillow"""
    sizes = [192, 512]

    for size in sizes:
        # Crear imagen con gradiente
        img = Image.new('RGB', (size, size), color='#22c55e')
        draw = ImageDraw.Draw(img)

        # Fondo con gradiente simple (simulado)
        for i in range(size):
            color_value = int(0x22 - (i / size) * 0x0C)
            color = f'#{color_value:02x}c55e'
            draw.line([(0, i), (size, i)], fill=color, width=1)

        # Esquinas redondeadas
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=20, fill=255)

        # Aplicar máscara
        output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        output.paste(img, (0, 0))
        output.putalpha(mask)

        # Agregar emoji (nota: emoji requiere fuente especial)
        try:
            font_size = int(size * 0.5)
            # Intentar cargar fuente con emoji
            font = ImageFont.truetype("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf", font_size)
            text = "📍"
        except:
            # Fallback: usar texto
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(size * 0.4))
            text = "📍"

        # Centrar texto
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size - text_width) // 2
        y = (size - text_height) // 2

        img_draw = ImageDraw.Draw(output)
        img_draw.text((x, y), text, font=font, fill='white')

        # Guardar
        filename = f"static/icon-{size}.png"
        os.makedirs('static', exist_ok=True)
        output.save(filename, 'PNG')

        print(f"✅ Creado: {filename}")

if __name__ == '__main__':
    print("🎨 Generador de Iconos PWA - GNSS.AI Point Collector")
    print("=" * 60)

    if PIL_AVAILABLE:
        try:
            create_icon_with_pil()
            print("\n✅ Iconos PNG generados exitosamente")
        except Exception as e:
            print(f"\n⚠️  Error generando PNG: {e}")
            print("Generando SVG en su lugar...")
            create_icon_manual()
    else:
        create_icon_manual()

    print("\n" + "=" * 60)
