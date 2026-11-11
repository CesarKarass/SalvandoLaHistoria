extends Node2D
## Smoke test del sistema de diálogos con opciones múltiples:
## - estado CHOOSING y navegación de alternativas (quick_1..4)
## - 3 alternativas con su propia rama (salto con `next_line` y bucle)
## - alternativas usadas marcadas en gris al volver a mostrarlas
## - pausa del temporizador del evento mientras hay diálogo abierto
## Ejecuta: godot --headless --path <proyecto> res://tests/test_dialogue_choices.tscn

func _ready() -> void:
	_run()

func _tap(action: String) -> void:
	# Alinea el press con el inicio de un frame (si se presiona justo después
	# de un `create_timer`, el borde just_pressed no lo llegaría a ver _process).
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame
	await get_tree().process_frame

## Abre el diálogo y espera a que el frame de guardia (`_start_frame`) pase.
func _start_dialogue(dlg: Dialogue) -> void:
	DialogueManager.start(dlg)
	await get_tree().process_frame
	await get_tree().process_frame

## Lleva el diálogo hasta la línea con alternativas (líneas 0, 1 y 2).
func _reach_choices() -> void:
	# Línea 0 (intro): completar + avanzar.
	await _tap("confirm")
	await _tap("confirm")
	# Línea 1 (pregunta): completar + avanzar.
	await _tap("confirm")
	await _tap("confirm")
	# Línea 2 (alternativas): completar → estado CHOOSING.
	await _tap("confirm")

func _run() -> void:
	var results: Array[String] = []

	# --- 1) Recurso del Nivel 1: 6 líneas y 3 alternativas en la línea 2 ---
	var dlg: Dialogue = load("res://resources/dialogues/hidalgo_nivel1.tres")
	results.append("lineas=" + str(dlg.lines.size()))
	results.append("alternativas=" + str(dlg.lines[2].choices.size()))

	# --- 2) Rama correcta: quick_1 (bolsa) → línea 3 → fin ---
	await _start_dialogue(dlg)
	await _reach_choices()
	results.append("eligiendo=" + str(DialogueManager.state == DialogueManager.State.CHOOSING))
	var box := DialogueManager._box
	results.append("panel_en_bocadillo=" + str(box._choices_box.get_parent() == box._bg))
	results.append("panel_visible=" + str(box._choices_box.visible))
	# Diseño tipo Sally Face: misma forma del cuadro y solo se ven las opciones.
	results.append("texto_oculto=" + str(not box._text_label.visible))
	results.append("misma_forma=" + str(box._bg.offset_top == -150.0))
	await _tap("quick_1")
	results.append("texto_visible_tras_elegir=" + str(box._text_label.visible))
	results.append("rama_correcta_linea=" + str(DialogueManager._line_index))
	results.append("bandera_bolsa=" + str(GameManager.get_flag("consejo_bolsa")))
	results.append("bandera_hidalgo=" + str(GameManager.get_flag("met_hidalgo")))
	results.append("usada_bolsa=" + str(DialogueManager._used_choices.has(dlg.resource_path + ":2:0")))
	# Línea 3 (respuesta correcta): completar + avanzar (next_line = -2 → fin).
	await _tap("confirm")
	await _tap("confirm")
	results.append("estado_final=" + str(DialogueManager.state == DialogueManager.State.IDLE))

	# --- 3) Rama incorrecta: quick_3 (discurso) → línea 5 → vuelve a la pregunta ---
	await _start_dialogue(dlg)
	await _reach_choices()
	await _tap("quick_3")
	results.append("rama_incorrecta_linea=" + str(DialogueManager._line_index))
	results.append("bandera_discurso=" + str(GameManager.get_flag("consejo_discurso")))
	# Línea 5 (rebuke): completar + avanzar → next_line = 1 (vuelve a preguntar).
	await _tap("confirm")
	await _tap("confirm")
	results.append("vuelve_a_pregunta=" + str(DialogueManager._line_index))
	# Vuelve a mostrar las alternativas: las ya usadas deben quedar en gris.
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	results.append("re_eligiendo=" + str(DialogueManager.state == DialogueManager.State.CHOOSING))
	var used: Array[bool] = DialogueManager._box._choice_used
	results.append("gris_bolsa=" + str(used.size() > 0 and used[0]))
	results.append("gris_mapa_falsa=" + str(used.size() > 1 and not used[1]))
	results.append("gris_discurso=" + str(used.size() > 2 and used[2]))
	# Eligimos la opción 1 (ya usada → gris) y la respuesta cierra el diálogo.
	await _tap("quick_1")
	await _tap("confirm")
	await _tap("confirm")
	results.append("estado_cerrado=" + str(DialogueManager.state == DialogueManager.State.IDLE))

	# --- 4) El temporizador del evento se pausa mientras hay diálogo ---
	var e1: Event1 = load("res://scenes/events/event1/event1.tscn").instantiate()
	add_child(e1)
	await get_tree().process_frame
	var t0: float = e1.time_remaining
	await _start_dialogue(dlg)
	await get_tree().create_timer(0.5).timeout
	results.append("pausado=" + str(e1.time_remaining == t0))
	# Termina el diálogo (completar/avanzar las 3 líneas y elegir quick_1).
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	await _tap("quick_1")
	await _tap("confirm")
	await _tap("confirm")
	await get_tree().create_timer(0.4).timeout
	results.append("reanudado=" + str(e1.time_remaining < t0))
	results.append("tiempo_restante=" + str(snappedf(e1.time_remaining, 0.1)))
	e1.free()

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
