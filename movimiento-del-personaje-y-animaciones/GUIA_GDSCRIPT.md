# Guía rápida de GDScript (con ejemplos de este proyecto)

GDScript es el lenguaje propio de Godot. Se parece a Python (sangría con tabuladores,
`def` → `func`) pero es **orientado a objetos** y **se ejecuta dentro de un nodo**.
Este proyecto es tu ejemplo vivo: casi todo lo de aquí aparece en `scripts/jugador.gd`.

---

## 1. Un script = una clase que cuelga de un nodo

```gdscript
extends CharacterBody2D   # hereda: este script SE COMPORTA como un cuerpo físico 2D
class_name Jugador        # nombre global: en otro archivo puedo escribir "Jugador"
```

- `extends` dice **de qué tipo hereda** el script. Todo lo que tenga ese tipo
  (por ejemplo `velocity` y `move_and_slide()` de `CharacterBody2D`) lo usamos sin más.
- `class_name` registra la clase en el proyecto → aparece en el editor como tipo
  y se puede usar en otras funciones: `func _algo(j: Jugador) -> void:`.
- Si no pones `extends`, hereda de `RefCounted` (un objeto común).

---

## 2. Tipos de datos

| Tipo | Ejemplo | Para qué |
|---|---|---|
| `float` | `150.0` | decimales (siempre llevan punto: `60.0`, no `60`) |
| `int` | `64` | enteros |
| `bool` | `true` / `false` | banderas |
| `String` | `"hola"` | texto |
| `StringName` | `&"idle_down"` | identificador (más rápido que String; se usa en animaciones) |
| `Vector2` | `Vector2(10, 20)` | posición/velocidad en X e Y |
| `Array` | `[1, 2, 3]` | lista ordenada |
| `Dictionary` | `{"a": 1, "b": 2}` | pares clave→valor |
| `PackedStringArray` | `PackedStringArray("##", "#..#")` | array "compacto" de strings |

**Anotar el tipo es recomendable** (el editor y el motor agradecen):

```gdscript
var velocidad: float = 150.0          # tipado explícito
var velocidad := 150.0                # "inferido": GDScript adivina que es float
const TAM_BLOQUE: int = 64
```

---

## 3. Anotaciones: `@export`, `@onready`, `@export_group`...

Las anotaciones (antes llamadas *keywords*) configuran cómo se comporta lo de abajo:

```gdscript
@export_group("Movimiento")                              # agrupa en el Inspector
@export_range(20.0, 400.0, 5.0) var velocidad: float = 150.0   # número con límites
@export_enum("4 direcciones", "8 direcciones") var esquema_direcciones: int = 1  # desplegable
@export var aceleracion: float = 1100.0                  # variable editable en el editor

@onready var _anim: AnimatedSprite2D = $SpriteJugador    # se resuelve AL ENTRAR A ESCENA
```

- `@export` → **se edita desde el Inspector del editor** (sin tocar código).
  Es la clave de la reutilización: el mismo `bloque.tscn` cambia de color por archivo.
- `@onready` → la variable se asigna **después** de que los nodos hijos existen.
  Por eso NO sirve hacer `var x = $Nodo` a nivel de script: en ese momento aún no hay árbol.

---

## 4. Señales (signal): hablar con otros scripts sin acoplarse

```gdscript
signal interactuar(zona: Node)          # 1) declaro el evento

interactuar.emit(_zona_actual)           # 2) lo emito (desde el jugador)

_jugador.interactuar.connect(_al_interactuar)   # 3) lo escucho (desde el escenario)
```

Es el patrón **eventos > llamadas directas**: el jugador no sabe *qué* pasa cuando
se interactúa; solo avisa. Así puedes conectar un diálogo, una palanca o un portal
al mismo evento sin reescribir `jugador.gd`.

---

## 5. Convención de nombres (no es obligatorio, pero se respeta en todo Godot)

| Forma | Significado |
|---|---|
| `_nombre` | privado: solo lo usa ese script (variables y funciones internas) |
| `MI_CONSTANTE` | constante "tipo enumeración" |
| `nombre_normal` | público: se puede tocar desde fuera |
| `_ready`, `_process` | **callbacks**: las llama el motor, nunca las llames tú |

---

## 6. Funciones

```gdscript
func _mover(delta: float) -> void:            # void = no devuelve nada
    velocity = velocity.move_toward(objetivo, tasa * delta)

static func indice_8_direcciones(v: Vector2) -> int:   # static = sin necesidad de instancia
    return wrapi(roundi(rad_to_deg(atan2(v.y, v.x)) / 45.0), 0, 8)

# Uso:
var i := indice_8_direcciones(dir)      # dentro de la misma clase
var j := Jugador.indice_8_direcciones(dir)   # desde fuera (por ser static)
```

- Los parámetros se tipan en la firma: `(delta: float)`.
- El orden de definición **no importa**: una función puede llamar a otra declarada abajo.

---

## 7. Estructuras de control

```gdscript
# if / elif / else
if _enfriamiento_esquiva > 0.0:
    _enfriamiento_esquiva -= delta
elif puede_esquivar():
    pass
else:
    pass

# ternario (if en una expresión)
var tasa: float = aceleracion if _entrada != Vector2.ZERO else desaceleracion

# match (como switch, y compara varios valores a la vez)
match indice:
    2: _anim.play("idle_down")
    6: _anim.play("idle_up")
    _: _anim.play("idle_side")     # "_" = cualquier otro caso (default)

# bucles
for fila in plano.size():                 # numérico: 0, 1, 2...
    for col in texto.length():            # recorrer un string
        var caracter: String = texto[col]

for nombre in ["move_left", "move_right"]:  # recorrer un array
    Input.action_release(nombre)

while tiempo > 0.0:                       # mientras se cumpla
    tiempo -= delta
```

---

## 8. El ciclo de vida: el motor llama estas funciones

```
    creas la escena  ──►  _ready()  (una vez)      ← conectar señales, preparar estado
                                │
   cada instante  ──►  _physics_process(delta) 60/s ← FÍSICA: input, velocidad, colisiones
                                │                     (delta = tiempo desde el último frame,
                                │                      suele ser 0.0166 s = 1/60)
   cada fotograma ──►  _process(delta)              ← visual puro (cámara extra, partículas)
                                │
                    move_and_slide()                ← resuelve los choques con las hitboxes
```

**Orden dentro de `_physics_process` (el de este proyecto):**

1. cronómetros (`_enfriamiento_esquiva -= delta`)
2. leer input (`_leer_entrada()`)
3. decidir el movimiento (normal o esquiva)
4. `move_and_slide()` → **aquí chocan las hitboxes y se desliza por las paredes**
5. animación/cámara con la velocidad **ya corregida por la colisión**
6. eventos (`interactuar.emit(...)`)

---

## 9. Escenas + scripts: dónde vive cada cosa

```
Escena (plaza_demo.tscn)          = el ÁRBOL de nodos (dónde están las cosas)
Script (jugador.gd)               = el CEREBRO de un nodo concreto (qué hacen)

$SpriteJugador                    = hijo directo del nodo del script
$Camara                           = atajo de get_node("Camara")
$Interaccion/Forma                = ruta concreta dentro del árbol
get_node_or_null("Camara")        = versión segura (devuelve null si no existe)
%NombreUnico                      = nodo marcado como "unique name" en el editor
```

**Nodos vs grupos vs capas de física** (los tres "directorios" de Godot):

| Sirve para | Ejemplo aquí |
|---|---|
| Estructura/posiciones | el árbol de la escena |
| Etiquetas lógicas (¿quién es?) | grupo `"interaccion"` |
| ¿Con quién choca? | capas 1 escenario / 2 personajes / 3 interaccion |

---

## 10. await: esperar sin bloquear

```gdscript
await _esperar(10)          # duerme esta función y sigue cuando se cumpla
await physics_frame         # reanuda en el siguiente paso de física
await get_tree().create_timer(2.0).timeout   # espera 2 segundos
```

`await` **no congela el juego**: deja esa función en pausa y el motor sigue.
Por eso las pruebas (`tests/*.gd`) pueden pulsar, esperar fotogramas y comprobar.

---

## 11. Errores típicos de principiante

| Error | Causa |
|---|---|
| `Identifier not declared` | no existe la variable o falta `extends` |
| `Invalid call. Nonexistent function` | el nodo no tiene ese método: revisa el tipo (`AnimatedSprite2D` vs `Sprite2D`) |
| `Condition is always false` al usar `$Nodo` | falta `@onready` (los nodos aún no existen) |
| El personaje "parpadea" | llamas `play()` cada fotograma: guarda la animación actual y solo cambia si difiere |
| La diagonal va más rápida | no usar `Input.get_vector()` ni normalizar |
| Indentación | GDScript exige **tabuladores** (el editor los pone solo) |

---

## 12. Mapa del proyecto

```
project.godot             → ajustes: escena principal, Input Map, capas de física
scenes/*.tscn             → los árboles de nodos (mundo, jugador, bloque, joystick)
scripts/*.gd              → el comportamiento de esos nodos
assets/jugador_sheet.png  → hoja de sprites (8 filas de dirección × 5 columnas)
assets/jugador_sprites.tres → SpriteFrames: las 16 animaciones recortadas de la hoja
tools/                    → scripts que NO van al juego (regenerar arte/recursos)
tests/                    → pruebas automáticas que simulan partidas
LEEME.md                  → cómo se juega y cómo extenderlo a los eventos del GDD
```
