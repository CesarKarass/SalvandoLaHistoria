extends Node2D
## Cierre del diálogo bajo demanda:
## - la opción "Gracias, nos vemos" sale en cualquier momento (sin esperar
##   las líneas) y ya no hay botones "Continuar"/"Cerrar";
## - Esc cierra el diálogo y NO abre la pausa en ese mismo frame;
## - Esc sin diálogo sí abre la pausa;
## - abrir un diálogo libera el input táctil (nadie queda "caminando solo").
## Ejecuta: godot --headless --path <proyecto> res://tests/test_cierre_dialogo.tscn

func _ready() -> void:
	_run()

## ¿Existe algún texto "Continuar"/"Cerrar" colgando de la caja? (ya no debe
## haber botones: la salida es la opción de diálogo "Gracias, nos vemos").
func _hay_texto(nodo: Node, buscado: String) -> bool:
	if nodo is Label and (nodo as Label).text == buscado:
		return true
	for hijo in nodo.get_children():
		if _hay_texto(hijo, buscado):
			return true
	return false

func _run() -> void:
	var results: Array[String] = []
	var dlg: Dialogue = load("res://resources/dialogues/viajero_plaza.tres")
	if dlg == null:
		dlg = load("res://resources/dialogues/hidalgo_nivel1.tres")

	var pause: PauseMenu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	pause.name = "PauseMenu"
	add_child(pause)
	await get_tree().process_frame

	# --- 1) El diálogo abre con la opción de salida y SIN botones ---
	DialogueManager.start(dlg)
	await get_tree().process_frame
	var box := DialogueManager._box
	results.append("abierto=" + str(DialogueManager.state != DialogueManager.State.IDLE))
	results.append("opcion_salir=" + str(
			box._salir_label != null
			and box._salir_label.text == DialogueBox.TEXTO_SALIR))
	results.append("sin_boton_continuar=" + str(not _hay_texto(box, "Continuar")))
	results.append("sin_boton_cerrar=" + str(not _hay_texto(box, "Cerrar")))

	# --- 2) Clic en "Gracias, nos vemos": sale al instante ---
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	box._on_salir_input(ev)
	results.append("salir_al_instante=" + str(DialogueManager.state == DialogueManager.State.IDLE))
	results.append("caja_oculta=" + str(not box.visible))
	results.append("pausa_intacta=" + str(not pause.visible))

	# --- 2b) La opción de salida también va DENTRO de la lista de
	# alternativas (como una opción más, al final) y al tocarla cierra. ---
	DialogueManager.start(dlg)
	await get_tree().process_frame
	box.show_choices(["Primera opción", "Segunda opción"], 0)
	results.append("salir_en_lista=" + str(
			box._salir_index == 2
			and box._choice_labels[2].visible
			and box._choice_labels[2].text == DialogueBox.TEXTO_SALIR))
	results.append("sin_salir_en_franja=" + str(not box._salir_label.visible))
	box._on_choice_gui_input(ev, 2)   # clic sobre "Gracias, nos vemos"
	results.append("salir_por_lista=" + str(DialogueManager.state == DialogueManager.State.IDLE))
	results.append("franja_vuelve=" + str(box._salir_label.visible))

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
