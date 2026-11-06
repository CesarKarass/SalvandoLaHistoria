extends CharacterBody2D
class_name Jugador
## ==========================================================================
##  JUGADOR · controlador cenital estilo Moonlighter
## ==========================================================================
## ESTRUCTURA DE UN SCRIPT GDScript (de arriba hacia abajo):
##
##   1) extends    -> de qué tipo "hereda" el script. Aquí CharacterBody2D:
##                     ya tenemos velocity, move_and_slide() y colisiones.
##   2) class_name  -> nombre global de la clase: en cualquier otro script
##                     puedo escribir `Jugador` (tipo) y `Jugador.MI_CONSTANTE`.
##   3) signal      -> eventos que OTROS scripts pueden escuchar.
##   4) const       -> valores fijos que NUNCA cambian (se escriben en MAYÚSCULAS
##                     cuando son "tipo enum" como NOMBRES_DIRECCIONES).
##   5) @export     -> variables visibles en el Inspector del editor.
##                     @export_group agrupa; @export_enum da un desplegable.
##   6) @onready    -> referencia a un nodo hijo, resuelta al entrar en escena
##                     (antes de _ready() no existen los nodos: por eso _ready).
##   7) var         -> estado interno. Las que empiezan por "_" son privadas:
##                     solo las usa este script (convención, no regla de oro).
##   8) func        -> comportamiento. Las que empiezan por "_" son internas.
##
## CICLO DE VIDA (el motor llama estas funciones solo):
##   _ready()           una vez, al entrar el nodo a la escena.
##   _physics_process() 60 veces/segundo: se usa TODO lo que toque física
##                      (input de movimiento, velocidad, colisiones).
##   _process()         cada fotograma: cosas visuales no físicas (no aquí).
## ==========================================================================

## El jugador avisa: "pulsa interactuar dentro de esta zona".
## Otro script la escucha:  nodo.interactuar.connect(mi_funcion)
signal interactuar(zona: Node)


# ==========================================================================
# 1) CONFIGURACIÓN  (editable desde el Inspector del editor)
# ==========================================================================
@export_group("Movimiento")
@export_range(20.0, 400.0, 5.0) var velocidad: float = 150.0   # px/segundo
@export var multiplicador_correr: float = 1.75                 # al mantener Shift
## 0 = solo cruz (estilo Zelda) · 1 = cruz + diagonales (Moonlighter)
@export_enum("4 direcciones", "8 direcciones") var esquema_direcciones: int = 1

@export_group("Respuesta / inercia")
@export var aceleracion: float = 1100.0        # px/s² al arrancar
@export var desaceleracion: float = 1500.0     # px/s² al soltar

@export_group("Esquiva estilo Moonlighter")
@export var velocidad_esquiva: float = 430.0   # px/s durante el dash
@export var duracion_esquiva: float = 0.22     # segundos que dura
@export var enfriamiento_esquiva: float = 0.65 # segundos de recarga

@export_group("Cámara")
@export var anticipacion_camara: float = 12.0  # px que se adelanta la cámara


# ==========================================================================
# 2) CONSTANTES
# ==========================================================================
## Nombres de las 8 direcciones EN EL MISMO ORDEN que indice_8_direcciones():
##   0:right   1:down_right  2:down   3:down_left
##   4:left    5:up_left     6:up     7:up_right
## Las animaciones del SpriteFrames se llaman "idle_<nombre>" y "walk_<nombre>".
const NOMBRES_DIRECCIONES: Array[String] = [
	"right", "down_right", "down", "down_left",
	"left", "up_left", "up", "up_right",
]


# ==========================================================================
# 3) NODOS HIJOS  (se resuelven al entrar en escena)
# ==========================================================================
@onready var _anim: AnimatedSprite2D = $SpriteJugador
@onready var _zona: Area2D = $Interaccion
@onready var _camara: Camera2D = $Camara


# ==========================================================================
# 4) ESTADO INTERNO  (variables de instancia)
# ==========================================================================
var _entrada: Vector2 = Vector2.ZERO       # dirección que pide el jugador
var _mirada: Vector2 = Vector2.DOWN        # a dónde mira el sprite (última dirección usada)
var _anim_actual: String = ""              # evita reiniciar la animación en cada frame

var _tiempo_esquiva: float = 0.0           # segundos que queda de dash activo
var _enfriamiento_esquiva: float = 0.0     # segundos que falta para poder esquivar
var _direccion_esquiva: Vector2 = Vector2.ZERO

var _zona_actual: Area2D = null            # zona de evento más cercana (si hay)


# ==========================================================================
# 5) CICLO DE VIDA
# ==========================================================================
func _ready() -> void:
	# connect(señal, receptor): cuando el motor emita area_entered, llamamos a...
	_zona.area_entered.connect(_al_entrar_zona)
	_zona.area_exited.connect(_al_salir_zona)
	_reproducir_animacion()   # arranca con la animación de reposo (mirada inicial: abajo)


func _physics_process(delta: float) -> void:
	# Orden pensado como un "fotograma de juego":
	#
	#  1) cronómetros -> 2) leer input -> 3) decidir el movimiento
	#  -> 4) aplicar física (¡aquí chocan las hitboxes!) -> 5) actualizar vista
	#  -> 6) eventos de interacción

	# --- 1) Cronómetros -------------------------------------------------------
	if _enfriamiento_esquiva > 0.0:
		_enfriamiento_esquiva -= delta

	# --- 2) Entrada del jugador (teclado / mando / joystick) -----------------
	_leer_entrada()

	# --- 3) Lógica de movimiento ---------------------------------------------
	if _tiempo_esquiva > 0.0:
		_avanzar_esquiva(delta)      # durante el dash se ignora el teclado
	else:
		_mover(delta)                # movimiento normal con inercia
		if Input.is_action_just_pressed("esquivar"):
			_iniciar_esquiva()

	# --- 4) FÍSICA: esto es lo que choca y desliza por los muros -------------
	# move_and_slide() recorre `velocity` y LA MODIFICA según las colisiones:
	# si hay pared, la velocidad se desvía (deslizamiento) o se anula.
	move_and_slide()

	# --- 5) Apariencia con la velocidad YA corregida por la colisión ---------
	_reproducir_animacion()
	_actualizar_escala_esquiva(delta)
	_actualizar_camara(delta)

	# --- 6) Interacción con zonas de evento del GDD --------------------------
	if Input.is_action_just_pressed("interactuar") and is_instance_valid(_zona_actual):
		interactuar.emit(_zona_actual)


# ==========================================================================
# 6) ENTRADA
# ==========================================================================
func _leer_entrada() -> void:
	# Input.get_vector(izq, der, arriba, abajo) devuelve un vector NORMALIZADO:
	# su longitud es siempre <= 1, por eso la diagonal no va más rápida.
	_entrada = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Modo 4 direcciones: redondeamos la diagonal a un solo eje.
	if esquema_direcciones == 0 and _entrada != Vector2.ZERO:
		_entrada = cuantizar_4_direcciones(_entrada)


## Convierte cualquier vector a los ejes cardinales conservando el eje dominante.
## Es `static`: se llama SIN instancia -> Jugador.cuantizar_4_direcciones(v).
static func cuantizar_4_direcciones(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2(signf(v.x), 0.0)   # horizontal gana los empates
	return Vector2(0.0, signf(v.y))


## Índice de las 8 direcciones girando en sentido horario desde la derecha:
##   0 = derecha · 1 = abajo-dcha · 2 = abajo · 3 = abajo-izq
##   4 = izquierda · 5 = arriba-izq · 6 = arriba · 7 = arriba-dcha
## Calcula el ÁNGULO del vector (atan2) y lo divide en sectores de 45°.
static func indice_8_direcciones(v: Vector2) -> int:
	if v == Vector2.ZERO:
		return -1
	return wrapi(roundi(rad_to_deg(atan2(v.y, v.x)) / 45.0), 0, 8)


# ==========================================================================
# 7) MOVIMIENTO FÍSICO
# ==========================================================================
func _mover(delta: float) -> void:
	# Velocidad OBJETIVO = dirección pedida × velocidad máxima.
	var objetivo: Vector2 = _entrada * velocidad
	if Input.is_action_pressed("correr"):
		objetivo *= multiplicador_correr

	# move_toward(actual, objetivo, paso): avanza "paso" px/s hacia el objetivo.
	# Así aparece la inercia: no saltamos de 0 a 150 de golpe.
	var tasa: float = aceleracion if _entrada != Vector2.ZERO else desaceleracion
	velocity = velocity.move_toward(objetivo, tasa * delta)


# ==========================================================================
# 8) ESQUIVA (dash)
# ==========================================================================
func _iniciar_esquiva() -> void:
	if _enfriamiento_esquiva > 0.0:
		return                                 # aún no recarga
	# Esquiva hacia donde se mueve; si no hay input, hacia donde se mira.
	_direccion_esquiva = (_entrada if _entrada != Vector2.ZERO else _mirada).normalized()
	_tiempo_esquiva = duracion_esquiva
	_enfriamiento_esquiva = enfriamiento_esquiva + duracion_esquiva


func _avanzar_esquiva(delta: float) -> void:
	_tiempo_esquiva -= delta
	# Velocidad fija de dash: si choca una pared, move_and_slide() la desvía.
	velocity = _direccion_esquiva * velocidad_esquiva


func puede_esquivar() -> bool:
	return _enfriamiento_esquiva <= 0.0 and _tiempo_esquiva <= 0.0


# ==========================================================================
# 9) ANIMACIONES  (SpriteFrames con 8 direcciones)
# ==========================================================================
func _reproducir_animacion() -> void:
	# La mirada sigue a la última dirección con valor (para girar el sprite).
	if _entrada != Vector2.ZERO:
		_mirada = _entrada

	# ¿Hay que caminar? Si se pide input, si queda dash, o si aún tiene inercia.
	var moviendo := (
		_tiempo_esquiva > 0.0
		or _entrada != Vector2.ZERO
		or velocity.length_squared() > 4.0
	)

	# indice_8_direcciones() -> NOMBRES_DIRECCIONES[indice] -> "walk_down_left"
	var indice := indice_8_direcciones(_mirada)
	var nombre := ("walk_" if moviendo else "idle_") + NOMBRES_DIRECCIONES[indice]

	# play() SOLO al cambiar de animación: si lo llamáramos cada frame,
	# el ciclo se reiniciaría y el personaje "parpadearía" sin avanzar.
	if nombre != _anim_actual:
		_anim_actual = nombre
		_anim.play(nombre)

	# El ciclo corre más rápido cuanto más rápido se mueve (correr/esquiva).
	if moviendo:
		_anim.speed_scale = clampf(velocity.length() / maxf(velocidad, 1.0), 1.0, 3.0)
	else:
		_anim.speed_scale = 1.0


## Squash & stretch: el sprite se estira en la dirección de la esquiva
## y vuelve a su forma normal al terminar (escala en X e Y del nodo).
func _actualizar_escala_esquiva(delta: float) -> void:
	var escala_objetivo := Vector2.ONE
	if _tiempo_esquiva > 0.0:
		if absf(_direccion_esquiva.x) >= absf(_direccion_esquiva.y):
			escala_objetivo = Vector2(1.3, 0.82)   # esquiva horizontal
		else:
			escala_objetivo = Vector2(0.82, 1.3)   # esquiva vertical
	# lerp(a, b, t) = interpolación: t=0 te quedas en a, t=1 llegas a b.
	_anim.scale = _anim.scale.lerp(escala_objetivo, minf(16.0 * delta, 1.0))


# ==========================================================================
# 10) CÁMARA CON ANTICIPACIÓN
# ==========================================================================
func _actualizar_camara(delta: float) -> void:
	var objetivo := Vector2.ZERO
	if velocity.length() > 1.0:
		# Mientras más rápido, más se adelanta la cámara en esa dirección.
		var intensidad := clampf(velocity.length() / maxf(velocidad, 1.0), 0.0, 1.4)
		objetivo = velocity.normalized() * anticipacion_camara * intensidad
	_camara.offset = _camara.offset.lerp(objetivo, minf(6.0 * delta, 1.0))


# ==========================================================================
# 11) INTERACCIÓN CON ZONAS DE EVENTO (GDD)
# ==========================================================================
func _al_entrar_zona(zona: Area2D) -> void:
	# Solo nos fijamos en las zonas del grupo "interaccion" (capa 3).
	if zona.is_in_group("interaccion"):
		_zona_actual = zona


func _al_salir_zona(zona: Area2D) -> void:
	if zona == _zona_actual:
		_zona_actual = null


func zona_en_rango() -> Area2D:
	return _zona_actual
