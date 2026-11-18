extends Node
## Prueba automática de la interacción del menú: comprueba el foco inicial,
## la navegación con flechas y la activación con ui_accept.
## Ejecutar: godot --path <proyecto> res://preview/prueba_interaccion.tscn

@onready var menu: Control = $MenuInicio

var _activado := ""


func _ready() -> void:
	for b in menu.botones:
		b.activado.connect(func(id: String): _activado = id)
	await _frames(6)

	var fallos: Array[String] = []

	# 1) foco inicial en CONTINUAR
	var dueno := get_viewport().gui_get_focus_owner()
	print("[Prueba] foco inicial: ", dueno.name if dueno else "ninguno")
	if dueno == null or dueno.name != "BotonContinuar":
		fallos.append("foco inicial")

	# 2) flecha abajo -> NUEVO JUEGO
	await _tecla(KEY_DOWN)
	dueno = get_viewport().gui_get_focus_owner()
	print("[Prueba] tras KEY_DOWN: ", dueno.name if dueno else "ninguno")
	if dueno == null or dueno.name != "BotonNuevoJuego":
		fallos.append("navegacion abajo")

	# 3) Enter -> activa NUEVO JUEGO (con animación de pulsación)
	await _tecla(KEY_ENTER)
	await _frames(8)
	print("[Prueba] activado: ", _activado)
	if _activado != "nuevo_juego":
		fallos.append("activacion ui_accept")

	# 4) flecha arriba -> CONTINUAR, y flecha abajo -> NUEVO JUEGO
	await _tecla(KEY_UP)
	dueno = get_viewport().gui_get_focus_owner()
	print("[Prueba] tras KEY_UP: ", dueno.name if dueno else "ninguno")
	if dueno == null or dueno.name != "BotonContinuar":
		fallos.append("navegacion arriba")

	await _tecla(KEY_DOWN)
	dueno = get_viewport().gui_get_focus_owner()
	print("[Prueba] tras KEY_DOWN: ", dueno.name if dueno else "ninguno")
	if dueno == null or dueno.name != "BotonNuevoJuego":
		fallos.append("navegacion abajo 2")

	# 5) ESCAPE no debe activar nada
	await _tecla(KEY_ESCAPE)
	await _frames(6)
	print("[Prueba] tras ESCAPE, activado: ", _activado if _activado != "" else "(nada)")

	if fallos.is_empty():
		print("[Prueba] TODO OK")
	else:
		print("[Prueba] FALLOS: ", fallos)
	get_tree().quit()


func _tecla(cod: Key) -> void:
	var presionada := InputEventKey.new()
	presionada.keycode = cod
	presionada.physical_keycode = cod
	presionada.pressed = true
	Input.parse_input_event(presionada)
	await _frames(3)

	var soltada := InputEventKey.new()
	soltada.keycode = cod
	soltada.physical_keycode = cod
	soltada.pressed = false
	Input.parse_input_event(soltada)
	await _frames(4)


func _frames(cantidad: int) -> void:
	for i in cantidad:
		await get_tree().process_frame
