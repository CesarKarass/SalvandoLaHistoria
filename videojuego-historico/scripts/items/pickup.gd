class_name Pickup
extends Area2D
## Objeto recogible en el mapa: al interactuar, se guarda en el inventario.
## Capa 3 (interactables), monitorable para que el jugador lo detecte.

@export var item: Item
@export var qty: int = 1
## Textura visible en el mapa (se puede asignar desde la escena/editor).
@export var sprite_texture: Texture2D

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
	# Prioridad: textura asignada en la escena > icono del item > placeholder.
	if sprite_texture != null:
		_sprite.texture = sprite_texture
	elif item != null and item.icon != null:
		_sprite.texture = item.icon
	else:
		_sprite.texture = PlaceholderArt.circle(12, Color(1.0, 0.85, 0.2))
	if _sprite.texture != null and _sprite.texture.get_height() < 32:
		_sprite.scale = Vector2(1.6, 1.6)
