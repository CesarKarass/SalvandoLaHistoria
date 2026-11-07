extends Node2D
class_name LevelMap
## ---------------------------------------------------------------------------
## CONSTRUCTOR DE ESCENARIOS POR CUADRÍCULA
## Replica la matriz 0/1 del GDD: el mapa se define como texto y cada celda
## genera su sprite y, si es sólida, su StaticBody2D con hitbox.
##
## Significado de cada celda:
##   '.' o ' ' → piso transitable
##   '#'       → muro sólido        (capa 1 "mundo")
##   'B'       → edificio sólido    (capa 1 "mundo")
##   'P'       → aparición del jugador
##   'N'       → NPC interactuable   (capa 3 "interactuable")
## ---------------------------------------------------------------------------

const TILE: int = 64

const FLOOR_TEX: Texture2D = preload("res://assets/sprites/tile_floor.png")
const WALL_TEX: Texture2D = preload("res://assets/sprites/tile_wall.png")
const BUILDING_TEX: Texture2D = preload("res://assets/sprites/tile_building.png")
const NPC_SCENE: PackedScene = preload("res://scenes/npc.tscn")

## Capa de física reservada al escenario sólido.
const LAYER_WORLD: int = 1

## Mapa por defecto: plaza de Dolores (16 x 12 baldosas de 64 px).
@export var map: PackedStringArray = [
	"################",
	"#..............#",
	"#.BBBBBB.......#",
	"#.BBBBBB.......#",
	"#....##........#",
	"#....##........#",
	"#..............#",
	"#.......BBBBBB.#",
	"#.......BBBBBB.#",
	"#..............#",
	"#..P.......N...#",
	"################",
]

## Ruta de la capa de piso (hermano de este nodo): sin y-sort, siempre dibujada debajo.
## Se exporta como NodePath plano y se resuelve en _ready() para que nunca
## dependa de la resolución de referencias al instanciar la escena.
@export var floor_layer_path: NodePath = ^"../FloorLayer"

## Posición de aparición del jugador y límites del nivel (para la cámara).
var spawn_position: Vector2 = Vector2(64, 64)
var bounds: Rect2 = Rect2()

@onready var floor_layer: Node2D = get_node_or_null(floor_layer_path) as Node2D


func _ready() -> void:
	_build()


func _build() -> void:
	var width: int = map[0].length()
	var height: int = map.size()
	bounds = Rect2(0, 0, width * TILE, height * TILE)

	for y in height:
		var row: String = map[y]
		for x in row.length():
			var cell: String = row[x]
			if cell == "#" or cell == "B":
				_spawn_wall(x, y, cell)
			else:
				_spawn_floor(x, y)

			if cell == "P":
				spawn_position = _tile_feet(x, y)
			elif cell == "N":
				_spawn_npc(x, y)


# ---------------------------------------------------------------------------
# Bloques del escenario
# ---------------------------------------------------------------------------
func _spawn_wall(x: int, y: int, cell: String) -> void:
	"""Muro/edificio: sprite + StaticBody2D con hitbox de la baldosa completa.

	El origen del nodo queda en la esquina INFERIOR de la baldosa y el
	centro del sprite/hitbox se compensa hacia arriba. Así el y-sort
	compara "pies contra base" y el personaje se dibuja por delante
	cuando está al sur del muro y por detrás cuando está al norte.
	"""
	var body := StaticBody2D.new()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	body.position = _tile_feet(x, y)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(TILE, TILE)   # hitbox = baldosa completa
	shape.shape = rect_shape
	shape.position = Vector2(0, -TILE * 0.5)
	body.add_child(shape)

	var spr := Sprite2D.new()
	spr.texture = WALL_TEX if cell == "#" else BUILDING_TEX
	spr.position = Vector2(0, -TILE * 0.5)
	body.add_child(spr)

	add_child(body)   # hereda el y-sort del nivel


func _spawn_floor(x: int, y: int) -> void:
	"""Piso decorativo: sin hitbox ni colisión, solo dibujo."""
	var spr := Sprite2D.new()
	spr.texture = FLOOR_TEX
	spr.position = Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
	var parent: Node2D = floor_layer if floor_layer != null else self
	parent.add_child(spr)


func _spawn_npc(x: int, y: int) -> void:
	"""Instancia un NPC con su hitbox en la esquina inferior de la baldosa."""
	var npc := NPC_SCENE.instantiate()
	npc.position = _tile_feet(x, y)
	add_child(npc)   # hereda el y-sort del nivel


func _tile_feet(x: int, y: int) -> Vector2:
	"""Centro inferior de la baldosa (x, y): los 'pies' del bloque."""
	return Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)
