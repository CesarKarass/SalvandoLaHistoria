class_name Item
extends Resource
## Atributos existentes del juego + forma espacial del inventario de la carpeta inventario/.

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var max_stack: int = 1
@export var valid_for: Array[StringName] = []
@export var has_fire_resistance: bool = false
@export var durability: int = 0
@export var weight: float = 0.0

@export_group("Inventario espacial")
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var can_rotate: bool = true
@export var grid_color: Color = Color("#60778B")
