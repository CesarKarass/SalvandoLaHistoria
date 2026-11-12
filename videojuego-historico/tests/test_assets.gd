extends Node2D
## Smoke test: los assets (sprites y tiles) cargan y se usan correctamente.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_assets.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []

	var names: Array[String] = [
		"player_idle", "player_walk",
		"tile_floor", "tile_wall", "tile_building",
	]
	for n: String in names:
		var tex: Texture2D = load("res://assets/sprites/" + n + ".png") as Texture2D
		if tex != null:
			results.append(n + "=" + str(tex.get_size()))
		else:
			results.append(n + "=NULL")

	# Jugador: animaciones construidas desde las hojas de sprites.
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	var sf: SpriteFrames = player.sprite.sprite_frames
	results.append("animaciones=" + str(sf.get_animation_names()))
	results.append("walk_down_frames=" + str(sf.get_frame_count("walk_down")))
	results.append("idle_left_frames=" + str(sf.get_frame_count("idle_left")))

	var hidalgo_tex: Texture2D = load("res://assets/sprites/NPC'S/npc_hidalgo.png") as Texture2D
	results.append("npc_hidalgo=" + ("NULL" if hidalgo_tex == null else str(hidalgo_tex.get_size())))

	# NPC: usa la textura real de Hidalgo.
	var npc: NPC = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as NPC
	add_child(npc)
	await get_tree().process_frame
	var npc_sprite := npc.get_node("Sprite2D") as Sprite2D
	results.append("npc_sprite_ok=" + str(npc_sprite.texture != null))

	# Sala del overworld: tiles + colisiones de muros.
	var ow: Node2D = (load("res://scenes/overworld/overworld.tscn") as PackedScene).instantiate() as Node2D
	add_child(ow)
	await get_tree().process_frame
	var room := ow.get_node_or_null("Room") as TileMapLayer
	var cells := 0
	if room != null:
		cells = room.get_used_cells().size()
	results.append("overworld_room_cells=" + str(cells))
	results.append("overworld_wall_colliders=" + str(ow.get_node_or_null("WallColliders") != null))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
