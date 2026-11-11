extends Node2D
## Smoke test de controles táctiles: joystick, botones y pausa.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_touch.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []

	var pause: PauseMenu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	pause.name = "PauseMenu"
	add_child(pause)

	var tc: TouchControls = (load("res://scenes/ui/touch_controls.tscn") as PackedScene).instantiate() as TouchControls
	tc.name = "TouchControls"
	add_child(tc)
	await get_tree().process_frame

	var joystick: TouchJoystick = null
	var buttons: Array[TouchButton] = []
	for c in tc.get_children():
		if c is TouchJoystick:
			joystick = c as TouchJoystick
		elif c is TouchButton:
			buttons.append(c as TouchButton)

	results.append("joystick=" + str(joystick != null))
	results.append("botones=" + str(buttons.size()))

	# Joystick hacia la derecha
	if joystick != null:
		joystick.apply_pos(joystick.size * 0.5 + Vector2(joystick.size.x * 0.45, 0.0))
		results.append("joy_derecha=" + str(Input.get_action_strength("move_right") > 0.5))
		joystick.apply_reset()
		results.append("joy_suelta=" + str(Input.get_action_strength("move_right") < 0.01))

	# Botón interactuar
	var interact_btn: TouchButton = null
	for b in buttons:
		if b.action == "interact":
			interact_btn = b
	if interact_btn != null:
		interact_btn._press()
		results.append("btn_interact=" + str(Input.is_action_pressed("interact")))
		interact_btn._release()
		results.append("btn_interact_suelta=" + str(not Input.is_action_pressed("interact")))

	# Botón pausa (tapped -> abre la pausa directamente)
	var pause_btn: TouchButton = null
	for b in buttons:
		if b.action == "":
			pause_btn = b
	if pause_btn != null:
		pause_btn._press()
		results.append("pausa_por_boton=" + str(pause.visible and get_tree().paused))
		pause_btn._release()
		pause.close()
		results.append("pausa_cerrada=" + str(not get_tree().paused))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
