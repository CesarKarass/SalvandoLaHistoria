extends Control
## Joystick virtual táctil (móvil) que "patea" las mismas acciones de input
## que el teclado: move_left / move_right / move_up / move_down.
##
## Así el resto del juego (Input.get_vector) no necesita saber si el jugador
## usa teclado, mando o dedo.
##
## En escritorio también funciona con el ratón (el proyecto tiene activada la
## opción "emulate_touch_from_mouse" para probar la versión móvil).

@export var radio_base: float = 56.0        # radio máximo de desplazamiento
@export var zona_muerta: float = 0.18       # % del radio sin respuesta
@export var ocultar_en_escritorio: bool = false

var _vector: Vector2 = Vector2.ZERO         # vector que se dibuja
var _presionando: bool = false
var _acciones_activas: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	var en_movil := DisplayServer.get_name() in ["android", "iOS"]
	if ocultar_en_escritorio and not en_movil:
		visible = false
	if not visible:
		_liberar_todo()


func _exit_tree() -> void:
	_liberar_todo()


# --------------------------------------------------------------------------- #
# Entrada táctil / ratón
# --------------------------------------------------------------------------- #
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_gestionar_presion(event.pressed, event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		if _presionando:
			_gestionar_arrastre(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_gestionar_presion(event.pressed, event.position)
		accept_event()
	elif event is InputEventMouseMotion and _presionando:
		_gestionar_arrastre(event.position)
		accept_event()


func _gestionar_presion(presionado: bool, posicion: Vector2) -> void:
	_presionando = presionado
	if presionado:
		_actualizar(posicion)
	else:
		_publicar(Vector2.ZERO)


func _gestionar_arrastre(posicion: Vector2) -> void:
	_actualizar(posicion)


func _actualizar(posicion_local: Vector2) -> void:
	var delta := posicion_local - size * 0.5
	var distancia := delta.length()

	# Vector de dibujo: se limita al radio y "cae" a cero muy cerca del centro.
	_vector = (delta.normalized() * clampf(distancia / radio_base, 0.0, 1.0)) if distancia > 1.0 else Vector2.ZERO

	# Vector de entrada: zona muerta + rampa hasta el 100 %.
	var entrada := _vector
	if entrada.length() < zona_muerta:
		entrada = Vector2.ZERO
	else:
		entrada = entrada.normalized() * inverse_lerp(zona_muerta, 1.0, minf(entrada.length(), 1.0))

	_publicar(entrada)
	queue_redraw()


func _publicar(v: Vector2) -> void:
	_poner_accion("move_right", v.x > 0.0)
	_poner_accion("move_left", v.x < 0.0)
	_poner_accion("move_down", v.y > 0.0)
	_poner_accion("move_up", v.y < 0.0)


func _poner_accion(nombre: StringName, activa: bool) -> void:
	if bool(_acciones_activas.get(nombre, false)) == activa:
		return
	_acciones_activas[nombre] = activa
	if activa:
		Input.action_press(nombre, 1.0)
	else:
		Input.action_release(nombre)


func _liberar_todo() -> void:
	for nombre in _acciones_activas.keys():
		if _acciones_activas[nombre]:
			Input.action_release(nombre)
	_acciones_activas.clear()
	_vector = Vector2.ZERO


# --------------------------------------------------------------------------- #
# Dibujo del joystick
# --------------------------------------------------------------------------- #
func _draw() -> void:
	var centro := size * 0.5
	draw_circle(centro, radio_base + 10.0, Color(1, 1, 1, 0.10))
	draw_arc(centro, radio_base + 10.0, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0)
	draw_circle(centro + _vector * radio_base * 0.8, radio_base * 0.42, Color(1, 1, 1, 0.45))
