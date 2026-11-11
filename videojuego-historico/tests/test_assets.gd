extends Node2D
## Smoke test: los assets (sprites y tiles) cargan y se usan correctamente.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_assets.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []

	var names: Array[String] = [
		"player_idle", "player_walk", "npc_hidalgo",
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

	# NPC: usa la textura real de Hidalgo.
	var npc: NPC = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as NPC
	add_child(npc)
	await get_tree().process_frame
	var npc_sprite := npc.get_node("Sprite2D") as Sprite2D
	results.append("npc_sprite_ok=" + str(npc_sprite.texture != null))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
