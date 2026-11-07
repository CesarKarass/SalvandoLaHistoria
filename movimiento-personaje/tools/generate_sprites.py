#!/usr/bin/env python3
"""
Generador de sprites placeholder (pixel art) para "Salvando la Historia".

Genera:
  - assets/sprites/player_idle.png   (8 direcciones x 2 frames, 64x64 c/u)
  - assets/sprites/player_walk.png   (8 direcciones x 4 frames, 64x64 c/u)
  - assets/sprites/npc_hidalgo.png   (1 frame 64x64)
  - assets/sprites/tile_floor.png    (baldosa 64x64 - plaza terracota)
  - assets/sprites/tile_wall.png     (muro adobe 64x64)
  - assets/sprites/tile_building.png (techo/edificio 64x64)

Uso:  python3 tools/generate_sprites.py
"""
import os
import random

from PIL import Image, ImageDraw

S = 64  # tamaño de frame (GDD: sprites 64x64)

# --------------------------------------------------------------------------
# Paleta (GDD: sepia, terracota, cempasúchil, azul obsidiana)
# --------------------------------------------------------------------------
SKIN = (236, 188, 140, 255)
SKIN_D = (206, 158, 112, 255)
HAIR = (58, 42, 32, 255)
SHIRT = (59, 110, 165, 255)       # azul obsidiana (camisa del estudiante)
SHIRT_D = (43, 84, 130, 255)
PANTS = (74, 78, 95, 255)
PANTS_D = (58, 61, 75, 255)
SHOES = (40, 40, 44, 255)
BAG = (176, 124, 62, 255)         # mochila ocre
BAG_D = (140, 96, 46, 255)

ROBE = (74, 58, 58, 255)          # sotana de Hidalgo
ROBE_D = (58, 45, 45, 255)
COLLAR = (232, 226, 214, 255)
HAIR_G = (168, 162, 156, 255)     # pelo canoso

# Direcciones: 0..4 se dibujan; 5..7 son espejo de 3..2..1
DIRS = ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]
MIRROR = {5: 3, 6: 2, 7: 1}

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sprites")


# --------------------------------------------------------------------------
# Utilidades de dibujo
# --------------------------------------------------------------------------
def new_frame():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rect(d, x0, y0, x1, y1, color):
    """Rectángulo con coordenadas inclusivas (estilo pixel art)."""
    d.rectangle([x0, y0, x1, y1], fill=color)


def ellipse(d, x0, y0, x1, y1, color):
    d.ellipse([x0, y0, x1, y1], fill=color)


# --------------------------------------------------------------------------
# Jugador
# --------------------------------------------------------------------------
# fase de paso por frame (4 frames de caminata)
# los pies tocan y=56 en pose neutral (44 + 13 - 1 = 56)
LEG_EXT = [(13, 11), (12, 12), (11, 13), (12, 12)]   # (pierna izq, pierna der)
BOB = [0, 1, 0, 1]                                  # balanceo del torso
ARM_OFF = [0, 1, 0, 1]


def _legs_down(d, bob, f):
    """Piernas vistas de frente/atrás (direcciones down/up)."""
    ext_l, ext_r = LEG_EXT[f] if f >= 0 else (13, 13)
    top = 44 + bob
    # pierna izquierda
    rect(d, 27, top, 31, top + ext_l - 1, PANTS)
    rect(d, 27, top + ext_l - 3, 31, top + ext_l - 1, SHOES)
    # pierna derecha
    rect(d, 33, top, 37, top + ext_r - 1, PANTS)
    rect(d, 33, top + ext_r - 3, 37, top + ext_r - 1, SHOES)


def _legs_side(d, bob, f):
    """Piernas en perfil (direcciones left/right)."""
    phase = [0, 1, 2, 1][f] if f >= 0 else 1
    ext_a, ext_b = ([13, 12, 11, 12][f], [11, 12, 13, 12][f]) if f >= 0 else (13, 13)
    top = 44 + bob
    ax = 26 - (phase - 1)   # pierna delantera avanza
    bx = 32 + (phase - 1)   # pierna trasera retrocede
    rect(d, ax, top, ax + 4, top + ext_a - 1, PANTS)
    rect(d, ax, top + ext_a - 3, ax + 4, top + ext_a - 1, SHOES)
    rect(d, bx, top, bx + 4, top + ext_b - 1, PANTS_D)
    rect(d, bx, top + ext_b - 3, bx + 4, top + ext_b - 1, SHOES)


def _torso(d, bob, back=False):
    rect(d, 24, 27 + bob, 39, 45 + bob, SHIRT)
    rect(d, 24, 42 + bob, 39, 45 + bob, SHIRT_D)        # sombra inferior
    rect(d, 24, 27 + bob, 26, 45 + bob, SHIRT_D)        # costado
    if back:
        # mochila del estudiante (visible desde atrás)
        rect(d, 26, 30 + bob, 37, 42 + bob, BAG)
        rect(d, 26, 30 + bob, 37, 32 + bob, BAG_D)
        rect(d, 30, 34 + bob, 33, 37 + bob, BAG_D)      # cierre


def _arms(d, bob, f, side=False, back=False):
    off = ARM_OFF[f] if f >= 0 else 0
    if side:
        # un solo brazo visible en perfil (se balancea)
        rect(d, 29, 30 + bob + off, 33, 42 + bob + off, SHIRT_D)
        rect(d, 29, 41 + bob + off, 33, 43 + bob + off, SKIN)
    else:
        rect(d, 20, 30 + bob - off, 23, 42 + bob - off, SHIRT_D)
        rect(d, 20, 41 + bob - off, 23, 43 + bob - off, SKIN)
        rect(d, 40, 30 + bob + off, 43, 42 + bob + off, SHIRT_D)
        rect(d, 40, 41 + bob + off, 43, 43 + bob + off, SKIN)
        if back:
            # tirantes de la mochila
            rect(d, 26, 28 + bob, 28, 40 + bob, BAG_D)
            rect(d, 35, 28 + bob, 37, 40 + bob, BAG_D)


def _head_down(d, bob, eyes=True):
    ellipse(d, 23, 9 + bob, 41, 27 + bob, SKIN)
    # pelo (frente y coronilla)
    rect(d, 23, 12 + bob, 41, 16 + bob, HAIR)
    ellipse(d, 23, 9 + bob, 41, 17 + bob, HAIR)
    rect(d, 23, 15 + bob, 25, 20 + bob, HAIR)
    rect(d, 39, 15 + bob, 41, 20 + bob, HAIR)
    if eyes:
        rect(d, 27, 19 + bob, 28, 21 + bob, (35, 30, 30, 255))
        rect(d, 35, 19 + bob, 36, 21 + bob, (35, 30, 30, 255))
        rect(d, 30, 24 + bob, 33, 24 + bob, SKIN_D)      # boca


def _head_up(d, bob):
    # nuca: pelo cubre toda la cabeza
    ellipse(d, 23, 9 + bob, 41, 27 + bob, HAIR)
    rect(d, 23, 20 + bob, 41, 27 + bob, SKIN)            # cuello
    rect(d, 23, 19 + bob, 41, 21 + bob, HAIR)


def _head_side(d, bob, facing_left=True):
    dx = 0 if facing_left else 0
    ellipse(d, 23 + dx, 9 + bob, 41 + dx, 27 + bob, SKIN)
    # pelo: parte de atrás (lado opuesto a la mirada)
    if facing_left:
        rect(d, 30, 9 + bob, 41, 24 + bob, HAIR)
        ellipse(d, 25, 9 + bob, 41, 17 + bob, HAIR)
        rect(d, 25, 15 + bob, 41, 17 + bob, HAIR)
        rect(d, 25, 26 + bob, 27, 27 + bob, SKIN_D)      # barbilla
        rect(d, 25, 18 + bob, 26, 20 + bob, (35, 30, 30, 255))  # ojo
        rect(d, 23, 21 + bob, 24, 22 + bob, SKIN_D)      # nariz
    else:
        rect(d, 23, 9 + bob, 34, 24 + bob, HAIR)
        ellipse(d, 23, 9 + bob, 39, 17 + bob, HAIR)
        rect(d, 23, 15 + bob, 39, 17 + bob, HAIR)
        rect(d, 37, 26 + bob, 39, 27 + bob, SKIN_D)
        rect(d, 37, 18 + bob, 38, 20 + bob, (35, 30, 30, 255))
        rect(d, 39, 21 + bob, 40, 22 + bob, SKIN_D)


def draw_player(base_dir, frame, idle=False):
    """Dibuja una frame del jugador para la dirección base 0..4."""
    img, d = new_frame()
    bob = (BOB[frame] if not idle else (0 if frame == 0 else 1))
    f = -1 if idle else frame  # -1 = pose neutral (piernas juntas)

    if base_dir in (0, 4):  # down / up
        back = base_dir == 4
        _legs_down(d, bob, f)
        _torso(d, bob, back)
        _arms(d, bob, f, back=back)
        if back:
            _head_up(d, bob)
        else:
            _head_down(d, bob)
    elif base_dir in (2,):  # left (perfil)
        _legs_side(d, bob, f)
        _torso(d, bob)
        _arms(d, bob, f, side=True)
        _head_side(d, bob, facing_left=True)
    elif base_dir == 3:     # up-left (3/4 trasero)
        _legs_down(d, bob, f)
        _torso(d, bob, back=True)
        _arms(d, bob, f, back=True)
        # cabeza girada ligeramente a la izquierda
        ellipse(d, 21, 9 + bob, 39, 27 + bob, SKIN)
        rect(d, 21, 9 + bob, 39, 17 + bob, HAIR)
        rect(d, 21, 20 + bob, 39, 27 + bob, SKIN)
        rect(d, 34, 9 + bob, 39, 24 + bob, HAIR)
        rect(d, 21, 19 + bob, 39, 21 + bob, HAIR)
    else:                    # base_dir == 1: down-left (3/4 frontal)
        _legs_down(d, bob, f)
        _torso(d, bob)
        _arms(d, bob, f)
        ellipse(d, 21, 9 + bob, 39, 27 + bob, SKIN)
        rect(d, 21, 12 + bob, 39, 16 + bob, HAIR)
        ellipse(d, 21, 9 + bob, 39, 17 + bob, HAIR)
        rect(d, 21, 15 + bob, 23, 20 + bob, HAIR)
        rect(d, 25, 19 + bob, 26, 21 + bob, (35, 30, 30, 255))
        rect(d, 32, 19 + bob, 33, 21 + bob, (35, 30, 30, 255))
        rect(d, 21, 22 + bob, 22, 23 + bob, SKIN_D)      # nariz en el borde
        rect(d, 27, 24 + bob, 30 + 1, 24 + bob, SKIN_D)
    return img


def build_player_sheets():
    # ---- hoja de caminata: 8 filas (direcciones) x 4 columnas (frames)
    walk = Image.new("RGBA", (S * 4, S * 8), (0, 0, 0, 0))
    # ---- hoja de idle: 8 filas x 2 columnas
    idle = Image.new("RGBA", (S * 2, S * 8), (0, 0, 0, 0))

    for d_idx, name in enumerate(DIRS):
        base = MIRROR.get(d_idx, d_idx)
        for f in range(4):
            frame_img = draw_player(base, f, idle=False)
            if d_idx in MIRROR:
                frame_img = frame_img.transpose(Image.FLIP_LEFT_RIGHT)
            walk.paste(frame_img, (f * S, d_idx * S))
        for f in range(2):
            frame_img = draw_player(base, f, idle=True)
            if d_idx in MIRROR:
                frame_img = frame_img.transpose(Image.FLIP_LEFT_RIGHT)
            idle.paste(frame_img, (f * S, d_idx * S))

    walk.save(os.path.join(OUT_DIR, "player_walk.png"))
    idle.save(os.path.join(OUT_DIR, "player_idle.png"))
    print("OK  player_walk.png  (4 frames x 8 direcciones)")
    print("OK  player_idle.png  (2 frames x 8 direcciones)")


# --------------------------------------------------------------------------
# NPC: Miguel Hidalgo (placeholder)
# --------------------------------------------------------------------------
def build_npc():
    img, d = new_frame()
    bob = 0
    # sotana (cubre las piernas)
    rect(d, 24, 30 + bob, 39, 55 + bob, ROBE)
    rect(d, 24, 30 + bob, 26, 55 + bob, ROBE_D)
    rect(d, 37, 30 + bob, 39, 55 + bob, ROBE_D)
    rect(d, 24, 53 + bob, 39, 55 + bob, ROBE_D)
    # brazos
    rect(d, 19, 32 + bob, 23, 46 + bob, ROBE)
    rect(d, 40, 32 + bob, 44, 46 + bob, ROBE)
    rect(d, 19, 45 + bob, 23, 47 + bob, SKIN)
    rect(d, 40, 45 + bob, 44, 47 + bob, SKIN)
    # collarín blanco
    rect(d, 26, 29 + bob, 37, 33 + bob, COLLAR)
    rect(d, 31, 33 + bob, 32, 36 + bob, COLLAR)
    # cabeza
    ellipse(d, 23, 9 + bob, 41, 28 + bob, SKIN)
    # canas laterales + entradas
    rect(d, 23, 14 + bob, 26, 24 + bob, HAIR_G)
    rect(d, 38, 14 + bob, 41, 24 + bob, HAIR_G)
    rect(d, 23, 9 + bob, 41, 13 + bob, HAIR_G)
    rect(d, 23, 9 + bob, 27, 15 + bob, HAIR_G)
    rect(d, 37, 9 + bob, 41, 15 + bob, HAIR_G)
    # ojos y boca
    rect(d, 27, 19 + bob, 28, 21 + bob, (35, 30, 30, 255))
    rect(d, 35, 19 + bob, 36, 21 + bob, (35, 30, 30, 255))
    rect(d, 29, 25 + bob, 34, 25 + bob, SKIN_D)
    img.save(os.path.join(OUT_DIR, "npc_hidalgo.png"))
    print("OK  npc_hidalgo.png")


# --------------------------------------------------------------------------
# Baldosas del escenario
# --------------------------------------------------------------------------
def build_tiles():
    rng = random.Random(1810)  # semilla fija: Independencia de México :)

    # ---- piso de plaza (terracota polvorienta)
    floor = Image.new("RGBA", (S, S), (181, 118, 79, 255))
    fd = ImageDraw.Draw(floor)
    for _ in range(260):
        x, y = rng.randrange(S), rng.randrange(S)
        c = rng.choice([(168, 106, 68, 255), (194, 132, 94, 255),
                        (175, 112, 74, 255), (200, 145, 105, 255)])
        fd.point((x, y), fill=c)
    # piedritas
    for _ in range(6):
        x, y = rng.randrange(2, S - 4), rng.randrange(2, S - 4)
        fd.rectangle([x, y, x + 2, y + 1], fill=(150, 95, 62, 255))
    floor.save(os.path.join(OUT_DIR, "tile_floor.png"))

    # ---- muro de adobe (bloque sólido / colisión)
    wall = Image.new("RGBA", (S, S), (169, 113, 63, 255))
    wd = ImageDraw.Draw(wall)
    # ladrillos
    for row in range(4):
        y0 = row * 16
        wd.rectangle([0, y0, S - 1, y0 + 15], outline=(125, 80, 48, 255))
        off = 0 if row % 2 == 0 else 32
        for x in range(off, S + 32, 32):
            wd.line([(x % S, y0), (x % S, y0 + 15)], fill=(125, 80, 48, 255))
    # cara superior iluminada (efecto volumen cenital)
    wd.rectangle([0, 0, S - 1, 5], fill=(196, 142, 92, 255))
    wd.rectangle([0, S - 4, S - 1, S - 1], fill=(110, 72, 44, 255))
    # sombra lateral
    wd.rectangle([S - 5, 0, S - 1, S - 1], fill=(138, 90, 52, 255))
    for _ in range(40):
        x, y = rng.randrange(S), rng.randrange(S)
        wd.point((x, y), fill=(156, 102, 58, 255))
    wall.save(os.path.join(OUT_DIR, "tile_wall.png"))

    # ---- edificio (techo de teja)
    roof = Image.new("RGBA", (S, S), (138, 90, 58, 255))
    rd = ImageDraw.Draw(roof)
    for row in range(8):
        y0 = row * 8
        rd.rectangle([0, y0, S - 1, y0 + 6], fill=(150, 98, 62, 255))
        rd.line([(0, y0 + 7), (S - 1, y0 + 7)], fill=(112, 70, 44, 255))
        for x in range((row % 2) * 8, S + 8, 16):
            rd.line([(x % S, y0), (x % S, y0 + 6)], fill=(112, 70, 44, 255))
    rd.rectangle([0, 0, S - 1, 3], fill=(172, 118, 76, 255))
    rd.rectangle([0, S - 3, S - 1, S - 1], fill=(96, 60, 38, 255))
    roof.save(os.path.join(OUT_DIR, "tile_building.png"))

    print("OK  tile_floor.png / tile_wall.png / tile_building.png")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    build_player_sheets()
    build_npc()
    build_tiles()


if __name__ == "__main__":
    main()
