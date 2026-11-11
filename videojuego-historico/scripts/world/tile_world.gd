class_name TileWorld
extends RefCounted
## Construye salas con los tiles reales (suelo, muro, edificio) y colisiones.
## La capa visual es un TileMapLayer; las colisiones de los muros son explícitas
## (más fiables que el polígono del tile) en la capa 2 (walls).

const TILE := 64
const FLOOR := 0
const WALL := 1
const BUILDING := 2

static func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var paths: Array[String] = [
		"res://assets/sprites/tile_floor.png",
		"res://assets/sprites/tile_wall.png",
		"res://assets/sprites/tile_building.png",
	]
	for i in paths.size():
		var tex: Texture2D = load(paths[i]) as Texture2D
		if tex == null:
			continue
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i(0, 0))
		ts.add_source(src, i)
	return ts

static func build_room(parent: Node2D, cols: int, rows: int) -> TileMapLayer:
	var tml := TileMapLayer.new()
	tml.name = "Room"
	tml.tile_set = make_tileset()
	tml.z_index = -10
	parent.add_child(tml)
	for x in range(cols):
		for y in range(rows):
			var border := x == 0 or x == cols - 1 or y == 0 or y == rows - 1
			tml.set_cell(Vector2i(x, y), WALL if border else FLOOR, Vector2i(0, 0))
	_add_wall_colliders(parent, cols, rows)
	return tml

static func _add_wall_colliders(parent: Node2D, cols: int, rows: int) -> void:
	var w := float(cols * TILE)
	var h := float(rows * TILE)
	var body := StaticBody2D.new()
	body.name = "WallColliders"
	body.collision_layer = 2
	body.collision_mask = 0
	parent.add_child(body)
	_add_rect(body, Vector2(TILE / 2.0, h / 2.0), Vector2(TILE, h))
	_add_rect(body, Vector2(w - TILE / 2.0, h / 2.0), Vector2(TILE, h))
	_add_rect(body, Vector2(w / 2.0, TILE / 2.0), Vector2(w, TILE))
	_add_rect(body, Vector2(w / 2.0, h - TILE / 2.0), Vector2(w, TILE))

static func _add_rect(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	body.add_child(shape)

## Limita la cámara a los límites de la sala (para no ver el vacío).
static func clamp_camera(player: Node, cols: int, rows: int) -> void:
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = cols * TILE
	cam.limit_bottom = rows * TILE
