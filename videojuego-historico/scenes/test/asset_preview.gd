extends Node2D
## Escena de prueba de assets: una sala con tiles reales (suelo, muro, edificio),
## el jugador con sprites reales e Hidalgo. Ábrela en Godot y pulsa F5 para verla.

const TILE := 64
const HALF := 4

func _ready() -> void:
	_build_room()
	_spawn_actors()

func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var paths: Array[String] = [
		"res://assets/sprites/tile_floor.png",
		"res://assets/sprites/tile_wall.png",
		"res://assets/sprites/tile_building.png",
	]
	for i in paths.size():
		var tex: Texture2D = load(paths[i]) as Texture2D
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i(0, 0))
		ts.add_source(src, i)
	# Los muros (source 1) bloquean al jugador (capa 2).
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 2)
	var wall_src := ts.get_source(1) as TileSetAtlasSource
	if wall_src != null:
		var td := wall_src.get_tile_data(Vector2i(0, 0), 0)
		var h := float(TILE) / 2.0
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
	return ts

func _build_room() -> void:
	var tml := TileMapLayer.new()
	tml.name = "Room"
	tml.tile_set = _make_tileset()
	tml.collision_enabled = true
	add_child(tml)
	for x in range(-HALF, HALF + 1):
		for y in range(-HALF, HALF + 1):
			var border := x == -HALF or x == HALF or y == -HALF or y == HALF
			tml.set_cell(Vector2i(x, y), 1 if border else 0, Vector2i(0, 0))

func _spawn_actors() -> void:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	add_child(player)
	player.global_position = Vector2(-TILE * 2, 0)

	var npc: NPC = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as NPC
	add_child(npc)
	npc.global_position = Vector2(TILE * 2, 0)
	npc.dialogue = load("res://resources/dialogues/hidalgo_intro.tres") as Dialogue
