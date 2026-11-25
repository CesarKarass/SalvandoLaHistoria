extends Node2D
## Un nivel nuevo NO debe arrancar con "input fantasma": si la escena anterior
## dejó presionada una acción (joystick soltado a medias, botón mantenido mientras
## cambiaba de escena), el jugador no debe empezar a caminar solo.
##
## Simula ese estado sucio antes de instanciar la escena y comprueba:
## 1) el jugador no deriva al aparecer;
## 2) al salir de la escena se liberan las acciones que queden pulsadas.
##
## Ejecuta: godot --headless --path <proyecto> res://tests/test_nivel_limpio.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []

	# --- Estado sucio: así queda el input cuando una escena se va con el
	# joystick/botón todavía pulsado (el release llega a un nodo ya liberado). ---
	Input.action_press("move_right", 1.0)
	Input.action_press("move_down", 1.0)
	Input.action_press("interact")
	results.append("input_sucio=" + str(Input.is_action_pressed("move_right")))

	var nivel: Node2D = load("res://scenes/overworld/plaza_prueba.tscn").instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Player = nivel.get_node("Player")
	var x0: float = player.global_position.x
	var y0: float = player.global_position.y
	for i: int in 45:
		await get_tree().physics_frame
	var dx: float = player.global_position.x - x0
	var dy: float = player.global_position.y - y0
	results.append("deriva=" + str(Vector2(snappedf(dx, 0.1), snappedf(dy, 0.1))))
	results.append("sin_caminar_solo=" + str(absf(dx) < 1.0 and absf(dy) < 1.0))

	# --- Al salir de la escena no debe quedar nada pulsado ---
	nivel.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	results.append("libera_al_salir=" + str(
			not Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_down")
			and not Input.is_action_pressed("interact")))

	Input.action_release("move_right")
	Input.action_release("move_down")
	Input.action_release("interact")

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
