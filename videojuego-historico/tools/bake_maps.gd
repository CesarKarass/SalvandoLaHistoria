extends Node
## Herramienta de "horneado": convierte los mapas generados por código en
## escenas reales (.tscn) con nodos y texturas, para poder editarlos en Godot.
##
## Ejecutar:
##   flatpak run org.godotengine.Godot --headless --path <proyecto> \
##       res://tools/bake_maps.tscn
##
## Genera:
##   resources/tilesets/village_tileset.tres
##   resources/player/player_frames.tres
##   scenes/overworld/overworld_map.tscn
##   scenes/events/event1/event1_map.tscn
##
## OJO: volver a ejecutarla SOBRESCRIBE esas escenas con lo que diga el código
## de scripts/world/tile_world.gd (se pierden los retoques hechos a mano).

const TILESET_PATH := "res://resources/tilesets/village_tileset.tres"
const OVERWORLD_MAP := "res://scenes/overworld/overworld_map.tscn"
const EVENT1_MAP := "res://scenes/events/event1/event1_map.tscn"
const PLAYER_FRAMES := "res://resources/player/player_frames.tres"

const COLS_OW := 24
const ROWS_OW := 14
const COLS_EV := 20
const ROWS_EV := 12

func _ready() -> void:
	_bake_tileset()
	_bake_map(OVERWORLD_MAP, "MapaAldea", true, COLS_OW, ROWS_OW)
	_bake_map(EVENT1_MAP, "MapaEvento1", false, COLS_EV, ROWS_EV)
	_bake_player_frames()
	print("BAKE_DONE")
	get_tree().quit()

func _bake_tileset() -> void:
	var ts := TileWorld.make_tileset()
	_ensure_dir(TILESET_PATH)
	var err := ResourceSaver.save(ts, TILESET_PATH)
	print("tileset=", err, " fuentes=", ts.get_source_count())

func _bake_map(path: String, root_name: String, village: bool, cols: int, rows: int) -> void:
	var root := Node2D.new()
	root.name = root_name
	add_child(root)
	var tml: TileMapLayer
	if village:
		tml = TileWorld.build_village(root, cols, rows)
	else:
		tml = TileWorld.build_event_room(root, cols, rows)
	# El TileSet se referencia como recurso externo (editable aparte).
	var ts: TileSet = load(TILESET_PATH) as TileSet
	if ts != null:
		tml.tile_set = ts
	_own_recursive(root, root)
	var packed := PackedScene.new()
	var perr := packed.pack(root)
	_ensure_dir(path)
	var serr := ResourceSaver.save(packed, path)
	print("mapa=", path, " pack=", perr, " save=", serr,
		" nodos=", _count_nodes(root), " celdas=", tml.get_used_cells().size())
	root.queue_free()
	remove_child(root)
	root.free()

func _bake_player_frames() -> void:
	var idle_tex: Texture2D = load("res://assets/sprites/player_idle.png") as Texture2D
	var walk_tex: Texture2D = load("res://assets/sprites/player_walk.png") as Texture2D
	if idle_tex == null or walk_tex == null:
		print("player_frames=SKIP (faltan hojas)")
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var rows := {"down": 0, "left": 2, "up": 4, "right": 6}
	for facing: String in rows.keys():
		var row: int = int(rows[facing])
		frames.add_animation("idle_" + facing)
		frames.set_animation_speed("idle_" + facing, 3.0)
		for c in 2:
			frames.add_frame("idle_" + facing, _atlas(idle_tex, c, row))
		frames.add_animation("walk_" + facing)
		frames.set_animation_speed("walk_" + facing, 8.0)
		for c in 4:
			frames.add_frame("walk_" + facing, _atlas(walk_tex, c, row))
	_ensure_dir(PLAYER_FRAMES)
	var err := ResourceSaver.save(frames, PLAYER_FRAMES)
	print("player_frames=", err, " anims=", frames.get_animation_names().size())

func _atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col * 64, row * 64, 64, 64)
	return at

func _own_recursive(root: Node, node: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_own_recursive(root, child)

func _count_nodes(node: Node) -> int:
	var n := 1
	for child in node.get_children():
		n += _count_nodes(child)
	return n

func _ensure_dir(res_path: String) -> void:
	var dir := res_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
