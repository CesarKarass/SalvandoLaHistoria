extends Node2D
## Smoke test de Fase 2: sistema de diálogos + proximidad a NPC.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_phase2.tscn

func _ready() -> void:
	_run()

func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame
	await get_tree().process_frame

func _run() -> void:
	var results: Array[String] = []

	# --- Diálogo construido en código ---
	var dlg := Dialogue.new()
	dlg.npc_name = "Miguel Hidalgo"
	var l1 := DialogueLine.new()
	l1.text = "Hola, forastero."
	var l2 := DialogueLine.new()
	l2.text = "Debes salvarnos."
	l2.set_flag = "test_flag"
	var l3 := DialogueLine.new()
	l3.text = "Adiós."
	dlg.lines = [l1, l2, l3]

	# --- Player + NPC ---
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var npc_scene: PackedScene = load("res://scenes/npc/npc.tscn")
	var player: CharacterBody2D = player_scene.instantiate()
	var npc: NPC = npc_scene.instantiate()
	add_child(player)
	add_child(npc)
	player.global_position = Vector2(100, 100)
	npc.global_position = Vector2(110, 100)
	npc.dialogue = dlg

	for i in 6:
		await get_tree().physics_frame

	results.append("estado_inicial=" + str(DialogueManager.state))
	results.append("prompt_visible=" + str(npc.get_node("Prompt").visible))

	# --- Interactuar (abre el diálogo) ---
	await _tap("interact")
	results.append("estado_tras_interact=" + str(DialogueManager.state))
	results.append("can_move_bloqueado=" + str(not player.can_move))

	# --- Avanzar 3 líneas (2 pulsaciones por línea: completar + avanzar) ---
	for i in 6:
		await _tap("confirm")

	results.append("estado_final=" + str(DialogueManager.state))
	results.append("can_move_final=" + str(player.can_move))
	results.append("flag=" + str(GameManager.get_flag("test_flag")))

	# --- Cargar el recurso .tres de ejemplo ---
	var tres: Dialogue = load("res://resources/dialogues/hidalgo_intro.tres")
	results.append("tres_npc=" + tres.npc_name + " lineas=" + str(tres.lines.size()))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
