class_name Item
extends Resource
## Objeto del inventario. Propiedades básicas + atributos extendidos que
## usarán los Eventos 2–5 (resistencia al fuego, durabilidad, peso...).

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var max_stack: int = 1
## Dónde es útil (ids de eventos), para validaciones futuras.
@export var valid_for: Array[StringName] = []
## Atributos para eventos posteriores (El Pípila, barricadas...).
@export var has_fire_resistance: bool = false
@export var durability: int = 0
@export var weight: float = 0.0
