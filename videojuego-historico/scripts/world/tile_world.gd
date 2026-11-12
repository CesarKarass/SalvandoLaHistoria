class_name TileWorld
extends RefCounted
## Generador de los mapas (aldea del overworld y plaza del Evento 1).
##
## IMPORTANTE: el juego ya NO construye el mapa en tiempo de ejecución; las
## escenas `overworld_map.tscn` y `event1_map.tscn` se generan con este código
## mediante la herramienta `tools/bake_maps.tscn` y luego se editan a mano en
## el editor. Este archivo se conserva para poder re-generarlas.
##
## Los props (árbol, pozo, caja...) son Sprite2D con texturas reales de
## `assets/sprites/props/`, y los tiles llevan un TileSet guardado en
## `resources/tilesets/village_tileset.tres`.

const TILE := 64

# --- Ids de origen dentro del TileSet -------------------------------------
const FLOOR := 0
const WALL := 1
const BUILDING := 2
const ROOF := 3
const PLAZA := 4
const PLAZA_DARK := 5
const FLOOR_DARK := 6

# --- Tintes (multiplican la textura original) -----------------------------
const TINT_ROOF := Color(0.72, 0.66, 0.66)
const TINT_PLAZA_DARK := Color(0.90, 0.90, 0.95)
const TINT_FLOOR_DARK := Color(0.92, 0.91, 0.95)

const WALL_LAYER := 2

## Nombre legible de cada prop en el árbol del editor.
const PROP_NAMES := {
	"tree": "Arbol", "well": "Pozo", "crate": "Caja", "rock": "Roca",
	"bench": "Banco", "grass": "Hierba", "door": "Puerta",
}

# --- Texturas de props ----------------------------------------------------
const PROP_TREE := "res://assets/sprites/props/tree.png"
const PROP_WELL := "res://assets/sprites/props/well.png"
const PROP_CRATE := "res://assets/sprites/props/crate.png"
const PROP_ROCK := "res://assets/sprites/props/rock.png"
const PROP_BENCH := "res://assets/sprites/props/bench.png"
const PROP_GRASS := "res://assets/sprites/props/grass.png"
const PROP_DOOR := "res://assets/sprites/props/door.png"
const PROP_SHADOW := "res://assets/sprites/props/shadow.png"

# ---------------------------------------------------------------------------
# TileSet
# ---------------------------------------------------------------------------

static func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	_add_source(ts, FLOOR, "res://assets/sprites/tile_floor.png", Color.WHITE)
	_add_source(ts, WALL, "res://assets/sprites/tile_wall_stone.png", Color.WHITE)
	_add_source(ts, BUILDING, "res://assets/sprites/tile_building.png", Color.WHITE)
	_add_source(ts, ROOF, "res://assets/sprites/tile_building.png", TINT_ROOF)
	_add_source(ts, PLAZA, "res://assets/sprites/tile_floor_stone.png", Color.WHITE)
	_add_source(ts, PLAZA_DARK, "res://assets/sprites/tile_floor_stone.png", TINT_PLAZA_DARK)
	_add_source(ts, FLOOR_DARK, "res://assets/sprites/tile_floor.png", TINT_FLOOR_DARK)
	return ts

static func _add_source(ts: TileSet, id: int, path: String, tint: Color) -> void:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_warning("TileWorld: falta la textura " + path)
		return
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	src.create_tile(Vector2i(0, 0))
	var data: TileData = src.get_tile_data(Vector2i(0, 0), 0)
	if data != null:
		data.modulate = tint
	ts.add_source(src, id)

# ---------------------------------------------------------------------------
# Sala básica
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Sala del evento
# ---------------------------------------------------------------------------

static func build_event_room(parent: Node2D, cols: int, rows: int) -> TileMapLayer:
	var tml := build_room(parent, cols, rows)
	_scatter_floor(tml, cols, rows)
	var px := int(cols / 2) - 4
	var py := int(rows / 2) - 2
	_fill(tml, px, py, 8, 4, PLAZA)
	var props := _props_group(parent, "Props")
	_prop(props, PROP_TREE, Vector2(4.0 * TILE, 3.4 * TILE), 1.0)
	_prop(props, PROP_TREE, Vector2(float(cols - 4) * TILE, 3.4 * TILE), 1.0)
	_prop(props, PROP_TREE, Vector2(4.0 * TILE, float(rows - 2.2) * TILE), 1.0)
	_prop(props, PROP_TREE, Vector2(float(cols - 4) * TILE, float(rows - 2.2) * TILE), 1.0)
	_prop(props, PROP_CRATE, Vector2(6.6 * TILE, 9.7 * TILE), 1.0)
	_prop(props, PROP_CRATE, Vector2(7.2 * TILE, 9.9 * TILE), 0.8)
	_prop(props, PROP_CRATE, Vector2(float(cols - 5.4) * TILE, 9.7 * TILE), 1.0)
	_prop(props, PROP_ROCK, Vector2(3.4 * TILE, 6.9 * TILE), 0.9)
	_prop(props, PROP_ROCK, Vector2(float(cols - 3.4) * TILE, 9.9 * TILE), 0.8)
	_prop(props, PROP_BENCH, Vector2(12.0 * TILE, 4.8 * TILE), 1.0)
	return tml

# ---------------------------------------------------------------------------
# Aldea (overworld)
# ---------------------------------------------------------------------------

static func build_village(parent: Node2D, cols: int, rows: int) -> TileMapLayer:
	var tml := build_room(parent, cols, rows)
	_scatter_floor(tml, cols, rows)

	_fill(tml, 9, 5, 6, 4, PLAZA)
	for x in range(9, 15):
		tml.set_cell(Vector2i(x, 5), PLAZA_DARK, Vector2i(0, 0))
		tml.set_cell(Vector2i(x, 8), PLAZA_DARK, Vector2i(0, 0))
	for y in range(5, 9):
		tml.set_cell(Vector2i(9, y), PLAZA_DARK, Vector2i(0, 0))
		tml.set_cell(Vector2i(14, y), PLAZA_DARK, Vector2i(0, 0))
	# Camino de la plaza a la puerta de la casa del evento.
	for step: Vector2i in [
		Vector2i(15, 7), Vector2i(16, 7), Vector2i(16, 8),
		Vector2i(16, 9), Vector2i(16, 10), Vector2i(17, 10),
		Vector2i(18, 10),
	]:
		tml.set_cell(step, PLAZA, Vector2i(0, 0))

	var obstacles := StaticBody2D.new()
	obstacles.name = "Obstacles"
	obstacles.collision_layer = WALL_LAYER
	obstacles.collision_mask = 0
	parent.add_child(obstacles)
	var props := _props_group(parent, "Props")

	_house(parent, props, obstacles, tml, 3, 2, 4, 3, 4, "Casa1")
	_house(parent, props, obstacles, tml, 17, 2, 4, 3, 18, "Casa2")
	_house(parent, props, obstacles, tml, 3, 8, 4, 3, 4, "Casa3")
	_house(parent, props, obstacles, tml, 17, 7, 4, 3, 18, "Casa4")

	_prop(props, PROP_WELL, Vector2(10.5 * TILE, 6.7 * TILE), 1.0)
	_add_box_collider(obstacles, Vector2(10.5 * TILE, 6.7 * TILE - 12.0), Vector2(44, 28), "Pozo")
	_prop(props, PROP_BENCH, Vector2(14.0 * TILE, 7.4 * TILE), 1.0)
	_prop(props, PROP_CRATE, Vector2(15.4 * TILE, 5.9 * TILE), 0.9)
	_prop(props, PROP_CRATE, Vector2(6.0 * TILE, 6.1 * TILE), 1.0)
	_prop(props, PROP_CRATE, Vector2(6.6 * TILE, 6.6 * TILE), 0.8)
	_prop(props, PROP_CRATE, Vector2(20.4 * TILE, 6.1 * TILE), 0.9)

	var trees: Array[Vector2] = [
		Vector2(1.5 * TILE, 5.9 * TILE), Vector2(1.5 * TILE, 7.9 * TILE),
		Vector2(1.5 * TILE, 10.2 * TILE), Vector2(22.5 * TILE, 5.9 * TILE),
		Vector2(22.5 * TILE, 7.9 * TILE), Vector2(22.5 * TILE, 10.2 * TILE),
		Vector2(7.5 * TILE, 6.9 * TILE), Vector2(16.5 * TILE, 3.4 * TILE),
		Vector2(9.5 * TILE, 12.4 * TILE), Vector2(14.5 * TILE, 12.4 * TILE),
	]
	for t: Vector2 in trees:
		_prop(props, PROP_TREE, t, 1.0)

	_prop(props, PROP_ROCK, Vector2(6.5 * TILE, 12.7 * TILE), 1.0)
	_prop(props, PROP_ROCK, Vector2(19.5 * TILE, 12.7 * TILE), 0.9)

	var rng := RandomNumberGenerator.new()
	rng.seed = 77123
	for i in 26:
		var gx := rng.randf_range(2.0, float(cols - 2))
		var gy := rng.randf_range(2.0, float(rows - 2))
		if gx > 7.4 and gx < 16.6 and gy > 3.4 and gy < 10.6:
			continue
		_prop(props, PROP_GRASS, Vector2(gx * TILE, gy * TILE), rng.randf_range(0.9, 1.3))

	return tml

static func _fill(tml: TileMapLayer, x0: int, y0: int, w: int, h: int, source: int) -> void:
	for x in range(x0, x0 + w):
		for y in range(y0, y0 + h):
			tml.set_cell(Vector2i(x, y), source, Vector2i(0, 0))

## Manchas de suelo más oscuro (semilla fija: el mapa siempre se ve igual).
static func _scatter_floor(tml: TileMapLayer, cols: int, rows: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20251112
	for x in range(1, cols - 1):
		for y in range(1, rows - 1):
			if rng.randf() < 0.05:
				tml.set_cell(Vector2i(x, y), FLOOR_DARK, Vector2i(0, 0))

static func _house(parent: Node2D, props: Node2D, obstacles: StaticBody2D,
		tml: TileMapLayer, x: int, y: int, w: int, h: int, door_x: int,
		house_name: String = "Casa") -> void:
	_fill(tml, x, y, w, h, BUILDING)
	_fill(tml, x, y, w, 1, ROOF)

	var rect := Rect2(x * TILE, y * TILE, w * TILE, h * TILE)
	_house_shadow(parent, rect)
	_add_box_collider(obstacles, rect.position + rect.size * 0.5, rect.size, house_name)

	# Puerta como nodo (se puede mover/editar en el editor).
	var door := _prop(props, PROP_DOOR, Vector2((door_x + 0.5) * TILE, (y + h) * TILE), 1.0)
	door.z_index = -2

## Sombra alargada bajo una casa: le da volumen al mapa.
static func _house_shadow(parent: Node2D, rect: Rect2) -> void:
	var tex: Texture2D = load(PROP_SHADOW) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y)
	spr.offset = Vector2(0, -tex.get_height() * 0.5)
	spr.scale = Vector2(rect.size.x / float(tex.get_width()), 0.9)
	spr.z_index = -3
	spr.name = "Sombra"
	parent.add_child(spr)

static func _props_group(parent: Node2D, group_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = group_name
	parent.add_child(node)
	return node

## Prop genérico: Sprite2D con textura real, anclado por la base (los pies).
static func _prop(parent: Node2D, path: String, pos: Vector2, s: float = 1.0) -> Sprite2D:
	var tex: Texture2D = load(path) as Texture2D
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	if tex != null:
		spr.offset = Vector2(0, -tex.get_height() * 0.5)
	spr.scale = Vector2(s, s)
	spr.z_index = -1
	var base := path.get_file().get_basename()
	spr.name = PROP_NAMES.get(base, "Prop")
	parent.add_child(spr)
	return spr

# ---------------------------------------------------------------------------
# Colisiones
# ---------------------------------------------------------------------------

static func _add_wall_colliders(parent: Node2D, cols: int, rows: int) -> void:
	var w := float(cols * TILE)
	var h := float(rows * TILE)
	var body := StaticBody2D.new()
	body.name = "WallColliders"
	body.collision_layer = WALL_LAYER
	body.collision_mask = 0
	parent.add_child(body)
	_add_rect(body, Vector2(TILE / 2.0, h / 2.0), Vector2(TILE, h), "MuroIzquierda")
	_add_rect(body, Vector2(w - TILE / 2.0, h / 2.0), Vector2(TILE, h), "MuroDerecha")
	_add_rect(body, Vector2(w / 2.0, TILE / 2.0), Vector2(w, TILE), "MuroArriba")
	_add_rect(body, Vector2(w / 2.0, h - TILE / 2.0), Vector2(w, TILE), "MuroAbajo")

static func _add_box_collider(body: StaticBody2D, center: Vector2, size: Vector2,
		shape_name: String = "Colision") -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	shape.name = shape_name
	body.add_child(shape)

static func _add_rect(body: StaticBody2D, center: Vector2, size: Vector2,
		shape_name: String = "Colision") -> void:
	_add_box_collider(body, center, size, shape_name)

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
