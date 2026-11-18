extends Node2D
## Test de la escena de prueba de la plaza (escena de nivel 1 con mapa, props,
## NPCs y UI montados solo con nodos del .tscn, sin script en la raíz).
## Comprueba:
## - estructura: TileMapLayer completo, colisiones, props, cámaras y spawn
## - que la raíz no lleva script (todo es editable en el editor)
## - colisión con el muro norte del mapa
## - proximidad → prompt del NPC y apertura del diálogo con `interact`
## - diálogo del Hidalgo (6 líneas, 3 alternativas) y del Viajero
## Ejecuta: godot --headless --path <proyecto> res://tests/test_plaza_prueba.tscn

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

func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i: int in frames:
		await get_tree().physics_frame
	Input.action_release(action)
	await get_tree().physics_frame

func _run() -> void:
	var results: Array[String] = []
	var plaza: Node2D = load("res://scenes/overworld/plaza_prueba.tscn").instantiate()
	add_child(plaza)
	await get_tree().process_frame
	await get_tree().process_frame

	# --- 1) Estructura del mapa y de la escena ---
	var room: TileMapLayer = plaza.get_node("Mapa/Room")
	results.append("tiles=" + str(room.get_used_cells().size()))
	results.append("grilla_24x14=" + str(room.get_used_rect() == Rect2i(0, 0, 24, 14)))
	results.append("tile_map_bytes=" + str(room.tile_map_data.size()))
	results.append("sin_script_raiz=" + str(plaza.get_script() == null))
	var colliders: int = plaza.get_node("WallColliders").get_child_count()
	results.append("colisiones=" + str(colliders))
	var props: int = plaza.get_node("Props").get_child_count()
	results.append("props=" + str(props))

	# --- 2) Posición inicial, spawn y límites de cámara en la escena ---
	var player: Player = plaza.get_node("Player")
	results.append("spawn=" + str(player.global_position == Vector2(800, 464)))
	results.append("marker_spawn=" + str(plaza.get_node("Spawns/SpawnDefault").position == Vector2(800, 464)))
	var cam: Camera2D = player.get_node("Camera2D")
	results.append("camara_limitada=" + str(cam.limit_left == 32 and cam.limit_top == 32
			and cam.limit_right == 1504 and cam.limit_bottom == 864))

	# --- 3) Colisión: subir hasta el muro norte no debe atravesarlo ---
	await _hold("move_up", 200)
	var y_al_muro: float = player.global_position.y
	results.append("subio=" + str(y_al_muro < 200.0))
	results.append("muro_norte=" + str(y_al_muro >= 70.0 and y_al_muro < 100.0))
	# Volver al centro para las siguientes pruebas.
	player.global_position = Vector2(800, 464)
	await get_tree().physics_frame

	# --- 4) Hidalgo: prompt por proximidad + diálogo con `interact` ---
	var hidalgo: NPC = plaza.get_node("Hidalgo")
	player.global_position = hidalgo.global_position
	for i: int in 6:
		await get_tree().physics_frame
	await get_tree().process_frame
	results.append("prompt_hidalgo=" + str(hidalgo._prompt.visible))
	results.append("dlg_hidalgo_lineas=" + str(hidalgo.dialogue.lines.size()))
	results.append("dlg_hidalgo_alter=" + str(hidalgo.dialogue.lines[2].choices.size()))
	await _tap("interact")
	results.append("dialogo_abierto=" + str(DialogueManager.state != DialogueManager.State.IDLE))
	results.append("jugador_inmovil=" + str(not player.can_move))
	# Línea 0 (completar + avanzar), línea 1 (completar + avanzar), línea 2 → CHOOSING.
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	await _tap("confirm")
	results.append("eligiendo=" + str(DialogueManager.state == DialogueManager.State.CHOOSING))
	await _tap("quick_1")
	# Avanza hasta que el diálogo termine (máximo 12 pulsaciones de seguridad).
	var guard: int = 0
	while DialogueManager.state != DialogueManager.State.IDLE and guard < 12:
		await _tap("confirm")
		guard += 1
	results.append("dialogo_cerrado=" + str(DialogueManager.state == DialogueManager.State.IDLE))
	results.append("jugador_movable=" + str(player.can_move))

	# --- 5) Viajero: sprite recortado de la hoja M-H y su propio diálogo ---
	var viajero: NPC = plaza.get_node("Viajero")
	results.append("dlg_viajero=" + str(viajero.dialogue != null and viajero.dialogue.npc_name == "Viajero"))
	results.append("sprite_viajero=" + str(viajero.sprite_texture is AtlasTexture))
	player.global_position = viajero.global_position
	for i: int in 6:
		await get_tree().physics_frame
	await get_tree().process_frame
	results.append("prompt_viajero=" + str(viajero._prompt.visible))
	await _tap("interact")
	results.append("viajero_abierto=" + str(DialogueManager.state != DialogueManager.State.IDLE))
	var guard2: int = 0
	while DialogueManager.state != DialogueManager.State.IDLE and guard2 < 8:
		await _tap("confirm")
		guard2 += 1
	results.append("viajero_cerrado=" + str(DialogueManager.state == DialogueManager.State.IDLE))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
