#!/usr/bin/env python3
"""Genera assets/jugador_sheet.png (placeholder de pixel art).

Filas  = indice_8_direcciones (0=dcha, 1=abajo-dcha, 2=abajo, 3=abajo-izq,
        4=izq, 5=arriba-izq, 6=arriba, 7=arriba-dcha)
Columnas = 0: quieto | 1..4: ciclo de caminata
Cada celda mide 64x64 px -> hoja total 320x512.
"""
from PIL import Image, ImageDraw

CELDA = 64
FILAS = 8
COLUMNAS = 5

# Paleta del GDD
SOMBRERO = (242, 160, 61, 255)
SOMBRERO_BORDE = (217, 138, 43, 255)
PIEL = (232, 185, 138, 255)
CABELLO = (74, 55, 40, 255)
REBOZO = (27, 27, 58, 255)
REBOZO_CLARO = (46, 46, 99, 255)
BOTA = (58, 58, 58, 255)
SOMBRA = (0, 0, 0, 70)

# Vector unitario de cada indice de direccion
DIRS = {
    0: (1, 0), 1: (1, 1), 2: (0, 1), 3: (-1, 1),
    4: (-1, 0), 5: (-1, -1), 6: (0, -1), 7: (1, -1),
}

# Desplazamiento de zancada por fotograma (ciclo de 4)
ZANCADA = [7, 0, -7, 0]


def r(img, x0, y0, x1, y1, color):
    img.rectangle([int(x0), int(y0), int(x1) - 1, int(y1) - 1], fill=color)


def celda(indice: int, columna: int) -> Image.Image:
    dx, dy = DIRS[indice]
    caminando = columna > 0
    zancada = ZANCADA[columna - 1] if caminando else 0
    salto = -1 if caminando and columna in (1, 3) else 0   # el cuerpo sube al dar el paso

    img = Image.new("RGBA", (CELDA, CELDA), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Sombra en el suelo (siempre quieta)
    r(d, 21, 57, 43, 62, SOMBRA)

    # --- Piernas (se dibujan antes que el cuerpo para que lo tape) ----------
    ax, ay = 23 + dx * zancada, 49 + dy * zancada * 0.6
    bx, by = 33 - dx * zancada, 49 - dy * zancada * 0.6
    r(d, ax, ay, ax + 8, ay + 12, BOTA)
    r(d, bx, by, bx + 8, by + 12, BOTA)

    # --- Brazos (siguen la zancada) ----------------------------------------
    mx, my = dx * zancada * 0.6, dy * zancada * 0.3
    r(d, 15 + mx, 33 + salto + my, 21 + mx, 45 + salto + my, REBOZO)
    r(d, 43 - mx, 33 + salto - my, 49 - mx, 45 + salto - my, REBOZO)

    # --- Cuerpo / rebozo ---------------------------------------------------
    r(d, 20, 32 + salto, 44, 50 + salto, REBOZO)
    r(d, 20, 34 + salto, 44, 38 + salto, SOMBRERO)          # faja
    r(d, 28, 38 + salto, 36, 50 + salto, REBOZO_CLARO)       # pliegue central

    # --- Cabeza ------------------------------------------------------------
    r(d, 23, 20 + salto, 41, 33 + salto, PIEL)

    # Cara segun la direccion a la que mira
    if dy > 0:                                              # mira al jugador: 2 ojos
        ex = dx * 2
        r(d, 26 + ex, 24 + salto, 30 + ex, 28 + salto, REBOZO)
        r(d, 34 + ex, 24 + salto, 38 + ex, 28 + salto, REBOZO)
    elif dy == 0:                                           # perfil: 1 ojo
        r(d, (34 if dx > 0 else 26), 24 + salto, (38 if dx > 0 else 30), 28 + salto, REBOZO)
    else:                                                   # de espaldas: cabello
        r(d, 23, 20 + salto, 41, 33 + salto, CABELLO)
        r(d, 25, 22 + salto, 39, 26 + salto, (58, 43, 31, 255))

    # --- Sombrero ----------------------------------------------------------
    r(d, 20 + dx * 3, 6 + salto, 44 + dx * 3, 17 + salto, SOMBRERO)      # copa
    r(d, 15 + dx * 4, 17 + salto, 49 + dx * 4, 22 + salto, SOMBRERO_BORDE)  # ala

    return img


def main():
    hoja = Image.new("RGBA", (CELDA * COLUMNAS, CELDA * FILAS), (0, 0, 0, 0))
    for fila in range(FILAS):
        for col in range(COLUMNAS):
            hoja.paste(celda(fila, col), (col * CELDA, fila * CELDA))
    hoja.save("assets/jugador_sheet.png")
    print("assets/jugador_sheet.png", hoja.size)


if __name__ == "__main__":
    main()
