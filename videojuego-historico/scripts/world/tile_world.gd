class_name TileWorld
extends RefCounted
## Construye salas y aldeas con los tiles reales (suelo, muro, edificio).
## La capa visual es un TileMapLayer; las colisiones de muros son explícitas
## (más fiables que el polígono del tile) en la capa de colisión 2 (walls).
##
## Claves visuales:
## - Cada tipo de tile lleva un `modulate` propio: la paleta original es toda
##   marrón y sin contraste, así que aquí se separan suelo / muro / edificio.
## - El suelo lleva manchas oscuras dispersas (semilla fija) para que no se vea
##   como un color plano repitiéndose.
## - `build_village()` añade plaza, casas con puerta, pozo y árboles.

const TILE := 64

# --- Ids de origen dentro del TileSet -------------------------------------
const FLOOR := 0
const WALL := 1
const BUILDING := 2
const PLAZA := 3
const FLOOR_DARK := 4
const DOOR := 5
const ROOF := 6
const PLAZA_DARK := 7

# --- Tintes (multiplican la textura original) -----------------------------
const TINT_FLOOR := Color(1.0, 1.0, 1.0)
const TINT_WALL := Color(0.74, 0.76, 0.86)     # piedra más fría y oscura
const TINT_BUILDING := Color(1.0, 0.96, 0.92)
const TINT_PLAZA := Color(1.0, 1.0, 1.0)       # el gris lo da la textura
const TINT_FLOOR_DARK := Color(0.92, 0.91, 0.95)
const TINT_DOOR := Color(0.32, 0.22, 0.17)     # hueco oscuro de la puerta
const TINT_ROOF := Color(0.72, 0.66, 0.66)     # alero/tejado de las casas
const TINT_PLAZA_DARK := Color(0.97, 0.97, 1.02)  # borde de la plaza

const WALL_LAYER := 2

# ---------------------------------------------------------------------------
# TileSet
# ---------------------------------------------------------------------------

static func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var floor_tex: Texture2D = load("res://assets/sprites/tile_floor.png") as Texture2D
	var wall_tex: Texture2D = load("res://assets/sprites/tile_wall.png") as Texture2D
	var building_tex: Texture2D = load("res://assets/sprites/tile_building.png") as Texture2D
	_add_source(ts, FLOOR, floor_tex, TINT_FLOOR)
	_add_source(ts, WALL, _desaturate(wall_tex, 0.25, 0.9), TINT_WALL)
	_add_source(ts, BUILDING, building_tex, TINT_BUILDING)
	_add_source(ts, PLAZA, _desaturate(floor_tex, 0.20, 0.98), TINT_PLAZA)
	_add_source(ts, FLOOR_DARK, floor_tex, TINT_FLOOR_DARK)
	_add_source(ts, DOOR, building_tex, TINT_DOOR)
	_add_source(ts, ROOF, building_tex, TINT_ROOF)
	_add_source(ts, PLAZA_DARK, _desaturate(floor_tex, 0.20, 0.93), TINT_PLAZA_DARK)
	return ts

## Copia la textura con menos saturación / más brillo (piedra en vez de tierra).
static func _desaturate(tex: Texture2D, saturation: float, brightness: float) -> Texture2D:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return tex
	var copy := img.duplicate() as Image
	copy.adjust_bcs(brightness, 1.0, saturation)
	return ImageTexture.create_from_image(copy)

static func _add_source(ts: TileSet, id: int, tex: Texture2D, tint: Color) -> void:
	if tex == null:
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
# Sala básica (usada por el Evento 1)
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

## Sala del evento: mismo tratamiento que la aldea (plaza + árboles + cajas)
## para que la escena no se vea como un cuarto marrón vacío.
static func build_event_room(parent: Node2D, cols: int, rows: int) -> TileMapLayer:
	var tml := build_room(parent, cols, rows)
	_scatter_floor(tml, cols, rows)
	var px := int(cols / 2) - 4
	var py := int(rows / 2) - 2
	_fill(tml, px, py, 8, 4, PLAZA)
	_tree(parent, Vector2(4.0 * TILE, 2.6 * TILE), 1.0)
	_tree(parent, Vector2(float(cols - 4) * TILE, 2.6 * TILE), 1.0)
	_tree(parent, Vector2(4.0 * TILE, float(rows - 2.4) * TILE), 1.0)
	_tree(parent, Vector2(float(cols - 4) * TILE, float(rows - 2.4) * TILE), 1.0)
	_crate(parent, Vector2(6.6 * TILE, 9.4 * TILE), 1.0)
	_crate(parent, Vector2(7.2 * TILE, 9.7 * TILE), 0.8)
	_crate(parent, Vector2(float(cols - 5.4) * TILE, 9.4 * TILE), 1.0)
	_rock(parent, Vector2(3.4 * TILE, 6.4 * TILE))
	_rock(parent, Vector2(float(cols - 3.4) * TILE, 9.4 * TILE))
	_bench(parent, Vector2(12.0 * TILE, 4.2 * TILE))
	return tml

# ---------------------------------------------------------------------------
# Aldea (overworld)
# ---------------------------------------------------------------------------

## Sala + contenido: plaza adoquinada, cuatro casas, pozo y árboles.
static func build_village(parent: Node2D, cols: int, rows: int) -> TileMapLayer:
	var tml := build_room(parent, cols, rows)
	_scatter_floor(tml, cols, rows)

	# Plaza central y camino hacia la casa del evento (este).
	_fill(tml, 9, 5, 6, 4, PLAZA)
	# Borde de piedra más oscura: la plaza se lee como algo intencionado.
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

	# Casas (x, y, ancho, alto, columna de la puerta).
	_house(parent, obstacles, tml, 3, 2, 4, 3, 4)
	_house(parent, obstacles, tml, 17, 2, 4, 3, 18)
	_house(parent, obstacles, tml, 3, 8, 4, 3, 4)
	_house(parent, obstacles, tml, 17, 7, 4, 3, 18)

	# Pozo en la plaza.
	_well(parent, obstacles, Vector2(10.5 * TILE, 6.0 * TILE))
	# Banco y cajas: mobiliario de plaza.
	_bench(parent, Vector2(14.2 * TILE, 7.2 * TILE))
	_crate(parent, Vector2(15.4 * TILE, 5.4 * TILE), 0.9)
	_crate(parent, Vector2(6.0 * TILE, 5.6 * TILE), 1.0)
	_crate(parent, Vector2(6.6 * TILE, 6.2 * TILE), 0.8)
	_crate(parent, Vector2(20.4 * TILE, 5.6 * TILE), 0.9)

	# Árboles: bordean el pueblo sin tapar los caminos.
	var trees: Array[Vector2i] = [
		Vector2i(1, 5), Vector2i(1, 7), Vector2i(1, 10),
		Vector2i(22, 5), Vector2i(22, 7), Vector2i(22, 10),
		Vector2i(7, 6), Vector2i(16, 3), Vector2i(9, 12), Vector2i(14, 12),
	]
	for t: Vector2i in trees:
		_tree(parent, Vector2((t.x + 0.5) * TILE, (t.y + 0.5) * TILE), 1.0)

	# Rocas de decoración.
	_rock(parent, Vector2(6.5 * TILE, 12.5 * TILE))
	_rock(parent, Vector2(19.5 * TILE, 12.5 * TILE))

	# Matas de hierba: rompen la monotonía del suelo.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77123
	for i in 30:
		var gx := rng.randf_range(2.0, float(cols - 2))
		var gy := rng.randf_range(2.0, float(rows - 2))
		if gx > 7.4 and gx < 16.6 and gy > 3.4 and gy < 10.6:
			continue
		_grass(parent, Vector2(gx * TILE, gy * TILE), rng.randf_range(0.8, 1.25))

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

static func _house(parent: Node2D, obstacles: StaticBody2D, tml: TileMapLayer,
		x: int, y: int, w: int, h: int, door_x: int) -> void:
	_fill(tml, x, y, w, h, BUILDING)
	# Alero: la fila superior más oscura da sensación de tejado.
	_fill(tml, x, y, w, 1, ROOF)
	var door_pos := Vector2((door_x + 0.5) * TILE, (y + h) * TILE)
	_door(parent, door_pos)
	# Un escalón delante de la puerta.
	tml.set_cell(Vector2i(door_x, y + h), FLOOR_DARK, Vector2i(0, 0))

	var rect := Rect2(x * TILE, y * TILE, w * TILE, h * TILE)
	_shadow(parent, rect, 0.20)
	_add_box_collider(obstacles, rect.position + rect.size * 0.5, rect.size)

## Puerta dibujada con polígonos: marco claro + hueco oscuro.
static func _door(parent: Node2D, pos: Vector2) -> void:
	var frame := Polygon2D.new()
	frame.color = Color(0.62, 0.51, 0.40)
	frame.polygon = PackedVector2Array([
		pos + Vector2(-22, 0), pos + Vector2(22, 0),
		pos + Vector2(22, -54), pos + Vector2(-22, -54),
	])
	frame.z_index = -6
	parent.add_child(frame)

	var hole := Polygon2D.new()
	hole.color = Color(0.17, 0.12, 0.10)
	hole.polygon = PackedVector2Array([
		pos + Vector2(-16, 0), pos + Vector2(16, 0),
		pos + Vector2(16, -46), pos + Vector2(-16, -46),
	])
	hole.z_index = -5
	parent.add_child(hole)

## Sombra proyectada bajo una estructura: le da volumen al mapa.
static func _shadow(parent: Node2D, rect: Rect2, alpha: float) -> void:
	var poly := Polygon2D.new()
	poly.color = Color(0, 0, 0, alpha)
	var off := Vector2(5, 4)
	poly.polygon = PackedVector2Array([
		rect.position + off + Vector2(0, rect.size.y - 6),
		rect.position + off + Vector2(rect.size.x, rect.size.y - 6),
		rect.position + off + Vector2(rect.size.x, rect.size.y + 12),
		rect.position + off + Vector2(0, rect.size.y + 12),
	])
	poly.z_index = -9
	parent.add_child(poly)

static func _tree(parent: Node2D, pos: Vector2, s: float) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderArt.circle(16, Color(0, 0, 0, 0.22))
	shadow.position = pos + Vector2(0, 4 * s)
	shadow.scale = Vector2(1.5 * s, 0.55 * s)
	shadow.z_index = -8
	parent.add_child(shadow)

	var trunk := Sprite2D.new()
	trunk.texture = PlaceholderArt.square(10, Color(0.33, 0.22, 0.15))
	trunk.position = pos + Vector2(0, -12 * s)
	trunk.scale = Vector2(s, 2.4 * s)
	trunk.z_index = -7
	parent.add_child(trunk)

	var canopy_back := Sprite2D.new()
	canopy_back.texture = PlaceholderArt.circle(20, Color(0.14, 0.34, 0.18))
	canopy_back.position = pos + Vector2(0, -38 * s)
	canopy_back.scale = Vector2(1.35 * s, s)
	canopy_back.z_index = -6
	parent.add_child(canopy_back)

	var leaf_l := Sprite2D.new()
	leaf_l.texture = PlaceholderArt.circle(14, Color(0.20, 0.44, 0.22))
	leaf_l.position = pos + Vector2(-13 * s, -30 * s)
	leaf_l.scale = Vector2(s, s)
	leaf_l.z_index = -5
	parent.add_child(leaf_l)

	var leaf_r := Sprite2D.new()
	leaf_r.texture = PlaceholderArt.circle(14, Color(0.20, 0.44, 0.22))
	leaf_r.position = pos + Vector2(13 * s, -30 * s)
	leaf_r.scale = Vector2(s, s)
	leaf_r.z_index = -5
	parent.add_child(leaf_r)

	var leaf_top := Sprite2D.new()
	leaf_top.texture = PlaceholderArt.circle(13, Color(0.27, 0.53, 0.27))
	leaf_top.position = pos + Vector2(0, -44 * s)
	leaf_top.z_index = -5
	parent.add_child(leaf_top)

static func _bench(parent: Node2D, pos: Vector2) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderArt.circle(14, Color(0, 0, 0, 0.18))
	shadow.position = pos + Vector2(0, 6)
	shadow.scale = Vector2(2.4, 0.5)
	shadow.z_index = -8
	parent.add_child(shadow)

	var legs := Sprite2D.new()
	legs.texture = PlaceholderArt.square(10, Color(0.26, 0.18, 0.12))
	legs.position = pos + Vector2(0, 2)
	legs.scale = Vector2(6.4, 0.6)
	legs.z_index = -6
	parent.add_child(legs)

	var seat := Sprite2D.new()
	seat.texture = PlaceholderArt.square(10, Color(0.52, 0.35, 0.20))
	seat.position = pos + Vector2(0, -4)
	seat.scale = Vector2(6.8, 0.9)
	seat.z_index = -5
	parent.add_child(seat)

static func _crate(parent: Node2D, pos: Vector2, s: float) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderArt.circle(11, Color(0, 0, 0, 0.18))
	shadow.position = pos + Vector2(0, 3 * s)
	shadow.scale = Vector2(1.4 * s, 0.5 * s)
	shadow.z_index = -8
	parent.add_child(shadow)

	var box := Sprite2D.new()
	box.texture = PlaceholderArt.square(24, Color(0.45, 0.30, 0.17))
	box.position = pos + Vector2(0, -6 * s)
	box.scale = Vector2(s, s)
	box.z_index = -6
	parent.add_child(box)

	var lid := Sprite2D.new()
	lid.texture = PlaceholderArt.square(20, Color(0.58, 0.40, 0.23))
	lid.position = pos + Vector2(0, -17 * s)
	lid.scale = Vector2(s, s)
	lid.z_index = -5
	parent.add_child(lid)

static func _grass(parent: Node2D, pos: Vector2, s: float) -> void:
	for i in 3:
		var blade := Sprite2D.new()
		blade.texture = PlaceholderArt.circle(3, Color(0.22, 0.42, 0.20))
		var angle := TAU * float(i) / 3.0
		blade.position = pos + Vector2(cos(angle) * 4.0, sin(angle) * 3.0)
		blade.scale = Vector2(s, s * 1.3)
		blade.z_index = -7
		parent.add_child(blade)

static func _rock(parent: Node2D, pos: Vector2) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderArt.circle(12, Color(0, 0, 0, 0.20))
	shadow.position = pos + Vector2(0, 3)
	shadow.scale = Vector2(1.3, 0.5)
	shadow.z_index = -8
	parent.add_child(shadow)

	var body := Sprite2D.new()
	body.texture = PlaceholderArt.circle(11, Color(0.46, 0.45, 0.50))
	body.position = pos + Vector2(0, -4)
	body.z_index = -6
	parent.add_child(body)

static func _well(parent: Node2D, obstacles: StaticBody2D, pos: Vector2) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderArt.circle(18, Color(0, 0, 0, 0.20))
	shadow.position = pos + Vector2(0, 6)
	shadow.scale = Vector2(1.5, 0.5)
	shadow.z_index = -8
	parent.add_child(shadow)

	var base := Sprite2D.new()
	base.texture = PlaceholderArt.circle(28, Color(0.42, 0.41, 0.46))
	base.position = pos
	base.z_index = -7
	parent.add_child(base)

	var rim := Sprite2D.new()
	rim.texture = PlaceholderArt.circle(21, Color(0.56, 0.55, 0.60))
	rim.position = pos + Vector2(0, -4)
	rim.z_index = -6
	parent.add_child(rim)

	var water := Sprite2D.new()
	water.texture = PlaceholderArt.circle(14, Color(0.09, 0.13, 0.19))
	water.position = pos + Vector2(0, -5)
	water.z_index = -5
	parent.add_child(water)

	_add_box_collider(obstacles, pos + Vector2(0, -4), Vector2(40, 26))

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
	_add_rect(body, Vector2(TILE / 2.0, h / 2.0), Vector2(TILE, h))
	_add_rect(body, Vector2(w - TILE / 2.0, h / 2.0), Vector2(TILE, h))
	_add_rect(body, Vector2(w / 2.0, TILE / 2.0), Vector2(w, TILE))
	_add_rect(body, Vector2(w / 2.0, h - TILE / 2.0), Vector2(w, TILE))

static func _add_box_collider(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	body.add_child(shape)

static func _add_rect(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	_add_box_collider(body, center, size)

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
