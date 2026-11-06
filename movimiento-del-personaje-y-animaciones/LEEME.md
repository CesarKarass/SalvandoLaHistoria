# Movimiento cenital + colisiones (GDD: Eventos Históricos)

Implementación del módulo de **movimiento del personaje en 4/8 direcciones (estilo Moonlighter)**
con **hitboxes y colisiones contra los bloques del escenario** (muros, edificios, barricadas),
preparada para los 5 eventos del GDD.

Probado con **Godot 4.7.2** (headless): **58/58 comprobaciones automáticas**
(`tests/test_moonlighter.gd` = 42 + `tests/test_movimiento.gd` = 16).

> 📖 Para entender el código: **[GUIA_GDSCRIPT.md](GUIA_GDSCRIPT.md)** (estructura del
> lenguaje, ciclo de vida de los nodos, señales, `@export`, `await`...).

## Estilo Moonlighter (verificado)

| Rasgo | Cómo está implementado | Prueba |
|---|---|---|
| 8 direcciones con velocidad igual en diagonales | `Input.get_vector()` (normalizado) + `esquema_direcciones = 1` | 24 comprobaciones (rumbo + velocidad + animación) |
| Inercia suave (no "a tope" por frame) | `velocity.move_toward()` con `aceleracion` / `desaceleracion` | arranque progresivo: 55 px/s a los 3 fotogramas |
| Animación de caminar en 8 direcciones | `AnimatedSprite2D` + `SpriteFrames` (16 animaciones) elegidas con `indice_8_direcciones()` | [A] y [C] |
| Ciclo más rápido al correr/esquivar | `animation_speed_scale` proporcional a `velocity` | [C] |
| Squash & stretch en la esquiva | escala 1.30 / 0.82 durante el dash | [D] |
| Esquiva (dash) con enfriamiento | 430 px/s, 0.22 s, recarga 0.65 s (acción `esquivar`) | [D] |
| Cámara con anticipación | `camera.offset` hacia la dirección del movimiento | [E] |

---

## Estructura

```
movimiento-del-personaje-y-animaciones/
├── project.godot            # escena principal, Input Map, capas de física
├── GUIA_GDSCRIPT.md         # guía del lenguaje con ejemplos de este proyecto
├── assets/
│   ├── jugador_sheet.png    # hoja: 8 filas (dirección) × 5 columnas (quieto + 4 pasos)
│   └── jugador_sprites.tres # SpriteFrames con las 16 animaciones recortadas
├── scripts/
│   ├── jugador.gd           # movimiento 4/8 dir, animación, esquiva, cámara, interacción
│   ├── escenario.gd         # construye el mapa desde un "plano" ASCII de 64 px
│   ├── zona_interaccion.gd  # áreas de evento (anomalía, palanca, barricada...)
│   ├── joystick.gd          # joystick virtual táctil (móvil) + ratón
│   └── boton_accion.gd      # botones táctiles (esquivar / interactuar)
├── scenes/
│   ├── bloque.tscn          # StaticBody2D + hitbox 64x64 (plantilla reutilizable)
│   ├── jugador.tscn         # CharacterBody2D + AnimatedSprite2D + hitbox + cámara
│   ├── joystick.tscn
│   └── plaza_demo.tscn      # ESCENA PRINCIPAL: plaza de prueba 1024x1024
├── tools/                   # scripts que NO entran al juego
│   ├── generar_sheet.py     # regenera la hoja de sprites (pixel art de prueba)
│   └── crear_spriteframes.gd# regenera el SpriteFrames desde la hoja
└── tests/
    ├── test_moonlighter.gd  # 8 direcciones + Moonlighter + animaciones (42 checks)
    └── test_movimiento.gd   # movimiento, colisiones y joystick (16 checks)
```

## Cómo probar

1. Abrir la carpeta con Godot 4.7+ (se importa la hoja de sprites automáticamente).
2. `F5` → arranca en `scenes/plaza_demo.tscn`.

Controles (también mando y joystick táctil en pantalla):

| Acción | Teclado | Mando | Táctil |
|---|---|---|---|
| Mover (4/8 dir.) | WASD / Flechas | Cruceta + stick izq. | Joystick izquierdo |
| Correr | Shift | LB | — |
| Esquiva (dash) | Espacio | B | Botón ESQUIVAR |
| Interactuar | E | A / Cross | Botón INTERACTUAR |

Pruebas automáticas desde terminal:

```bash
godot --headless --path . --script res://tests/test_moonlighter.gd    # 8 dir. + Moonlighter
godot --headless --path . --script res://tests/test_movimiento.gd     # colisiones + joystick
```

## Cómo funcionan las colisiones

- **Capas de física** (`Proyecto > Ajustes > Física 2D`):
  - `1 escenario` → muros, edificios, barricadas (`bloque.tscn` es un `StaticBody2D` con `RectangleShape2D` de 64×64).
  - `2 personajes` → el jugador (`collision_mask = 1`, solo choca contra el escenario).
  - `3 interaccion` → zonas de evento (`Area2D`), detectadas por el área `Interaccion` del jugador.
- La **hitbox del jugador es un rectángulo de 30×22 px en los pies** (no el sprite completo):
  así "morde" el suelo visual y se comporta bien en vista cenital.
- `move_and_slide()` de `CharacterBody2D` resuelve el choque y **desliza por las paredes**:
  no hay rebotes ni atascos en esquinas. `motion_mode = FLOATING` (top-down, sin gravedad).

## Cómo se dibuja el escenario

`escenario.gd` toma el exportado `plano` (`PackedStringArray`) de `plaza_demo.tscn`:

| Caracter | Significado | ¿Colisión? |
|---|---|---|
| `#` | muro de cantera (Stone Grey) | Sí |
| `B` | edificio de adobe (Terracotta) | Sí |
| `b` | barricada / mobiliario (Olive) | Sí |
| `c` | decoración (Cempasúchil) | No |
| `.` | suelo recorrible | — |

Edita el plano en el Inspector (cada fila = 16 celdas × 64 px = 1024 px) y el mapa se
reconstruye solo. Para otro evento del GDD solo cambia la matriz (Ej. Evento 4: vías y
palancas; Evento 5: barricadas y sacos de arena).

## Cómo se integra con los eventos del GDD

1. Coloca un `Area2D` con el script `zona_interaccion.gd` (capa `interaccion`, grupo
   `interaccion`), escribe su `mensaje` y ya es detectable por el jugador.
2. Al pulsar `interactuar` cerca, el jugador emite la señal `interactuar(zona)` y
   `escenario.gd` muestra el mensaje en el HUD (`$HUD/Aviso`).
3. En ese punto conecta la señal a la lógica del evento (diálogo con Hidalgo, palanca de
   Nacozari, entrega de objetos al Pípila...).

Ejemplo en cualquier script:

```gdscript
$Jugador.interactuar.connect(func(zona): print("Evento: ", zona.mensaje))
```

## Animaciones (8 direcciones)

- **Hoja** `assets/jugador_sheet.png`: 8 filas (una por `indice_8_direcciones`) ×
  5 columnas = [quieto, paso 1, paso 2, paso 3, paso 4], celdas de 64×64.
- **Recurso** `assets/jugador_sprites.tres`: 16 animaciones con `loop`
  (`idle_right`, `walk_down_left`, ...) recortadas con `AtlasTexture`.
- **Nodo** `SpriteJugador` = `AnimatedSprite2D` (filtro *nearest* para píxeles nítidos).
- **Código** en `jugador.gd → _reproducir_animacion()`:

```gdscript
var indice := indice_8_direcciones(_mirada)                 # 0..7
var nombre := ("walk_" if moviendo else "idle_") + NOMBRES_DIRECCIONES[indice]
if nombre != _anim_actual:      # solo cambia si difiere (evita reiniciar el ciclo)
    _anim_actual = nombre
    _anim.play(nombre)
_anim.speed_scale = clampf(velocity.length() / velocidad, 1.0, 3.0)  # correr = más rápido
```

### Cambiar el arte por uno propio

1. Dibuja una hoja con **el mismo orden** (8 filas de dirección × columnas de 64 px)
   y guárdala como `assets/jugador_sheet.png`, o toca el aspecto en
   `tools/generar_sheet.py` (colores del GDD) y ejecútalo.
2. Regenera el `SpriteFrames`:
   ```bash
   godot --headless --path . --script res://tools/crear_spriteframes.gd
   ```
   (O edítalo a mano en el editor: selecciona `jugador_sprites.tres` → pestaña *SpriteFrames*,
   donde puedes añadir fotogramas arrastrando la hoja.)
3. Ejecuta las pruebas para confirmar que las 16 animaciones siguen bien.

### Añadir más animaciones (ej. golpe, daño, hablar)

1. Añade las columnas nuevas a la hoja o un sheet aparte.
2. En `crear_spriteframes.gd` añade una línea:
   `_crear_animacion(sprites, hoja, indice, "ataque", [5, 6, 7], 12.0)`.
3. En `jugador.gd` decide cuándo reproducirla con `_anim.play("ataque_" + ...)`.
