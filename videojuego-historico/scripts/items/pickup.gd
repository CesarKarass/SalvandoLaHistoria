class_name Pickup
extends Area2D
## Objeto recogible en el mapa: al interactuar, se guarda en el inventario.
## Capa 3 (interactables), monitorable para que el jugador lo detecte.

@export var item: Item
@export var qty: int = 1

@onready var _prompt: Label = $Prompt
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_prompt.text = "Recoger"
	_prompt.visible = false
	_build_placeholder_sprite()

func interact() -> void:
	if item == null:
		return
	if Inventory.add_item(item, qty):
		queue_free()
	else:
		_prompt.text = "Sin espacio en mochila"

func set_prompt_visible(v: bool) -> void:
	_prompt.visible = v

func _build_placeholder_sprite() -> void:
	_sprite.texture = PlaceholderArt.circle(12, Color(1.0, 0.85, 0.2))
