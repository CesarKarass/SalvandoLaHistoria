extends Node2D
## Cierre del diálogo bajo demanda:
## - el botón "Cerrar" cierra en cualquier momento (sin esperar las líneas);
## - Esc cierra el diálogo y NO abre la pausa en ese mismo frame;
## - Esc sin diálogo sí abre la pausa;
## - abrir un diálogo libera el input táctil (nadie queda "caminando solo").
## Ejecuta: godot --headless --path <proyecto> res://tests/test_cierre_dialogo.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []
	var dlg: Dialogue = load("res://resources/dialogues/viajero_plaza.tres")
	if dlg == null:
		dlg = load("res://resources/dialogues/hidalgo_nivel1.tres")

	var pause: PauseMenu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	pause.name = "PauseMenu"
	add_child(pause)
	await get_tree().process_frame

	# --- 1) El diálogo abre y el botón "Cerrar" existe ---
	DialogueManager.start(dlg)
	await get_tree().process_frame
	results.append("abierto=" + str(DialogueManager.state != DialogueManager.State.IDLE))
	results.append("boton_cerrar=" + str(
			DialogueManager._box._close_label != null
			and DialogueManager._box._close_label.text == "Cerrar"))

	# --- 2) Clic en "Cerrar": cierra al instante ---
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	DialogueManager._box._on_close_input(ev)
	results.append("cerrar_al_instante=" + str(DialogueManager.state == DialogueManager.State.IDLE))
	results.append("caja_oculta=" + str(not DialogueManager._box.visible))
	results.append("pausa_intacta=" + str(not pause.visible))

	# --- 3) Esc cierra el diálogo y consume el cancel (no abre pausa) ---
	DialogueManager.start(dlg)
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_press("cancel")
	await get_tree().process_frame
	results.append("esc_cierra_dialogo=" + str(DialogueManager.state == DialogueManager.State.IDLE))
	results.append("esc_no_abre_pausa=" + str(not pause.visible))
	Input.action_release("cancel")
	await get_tree().process_frame
	await get_tree().process_frame

	# --- 4) Esc sin diálogo sí abre la pausa ---
	Input.action_press("cancel")
	await get_tree().process_frame
	results.append("esc_abre_pausa=" + str(pause.visible and get_tree().paused))
	Input.action_release("cancel")
	pause.close()
	await get_tree().process_frame
	results.append("pausa_cerrada=" + str(not get_tree().paused))

	# --- 5) Abrir un diálogo libera el input (sin fantasma al terminar) ---
	Input.action_press("move_right", 1.0)
	Input.action_press("interact")
	DialogueManager.start(dlg)
	await get_tree().process_frame
	results.append("input_liberado=" + str(
			not Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("interact")))
	DialogueManager.close_now()

	for line: String in results:
		print("TEST: ", line)

	# --- 6) Cambio de escena con estado sucio (Driver en la raíz: el cambio
	# libera esta escena de test, igual que en test_phase3). Comprueba que la
	# interfaz de inicio no recibe el diálogo "encima" ni pausa ni input. ---
	var driver := Driver.new()
	get_tree().root.call_deferred("add_child", driver)
	driver.run.call_deferred()


class Driver:
	extends Node

	func run() -> void:
		var dlg: Dialogue = load("res://resources/dialogues/viajero_plaza.tres")
		DialogueManager.start(dlg)          # diálogo abierto al cambiar
		get_tree().paused = true            # pausa "olvidada" al cambiar
		Input.action_press("move_right", 1.0)  # input fantasma al cambiar
		await SceneTransition.change_scene("res://scenes/overworld/plaza_prueba.tscn", "")
		print("TEST: escena_nueva=" + str(get_tree().current_scene != null))
		print("TEST: dialogo_cerrado_al_cambiar=" + str(
				DialogueManager.state == DialogueManager.State.IDLE
				and not DialogueManager._box.visible))
		print("TEST: sin_pausa_al_cambiar=" + str(not get_tree().paused))
		print("TEST: input_liberado_al_cambiar=" + str(not Input.is_action_pressed("move_right")))
		print("TEST_DONE")
		get_tree().quit()
