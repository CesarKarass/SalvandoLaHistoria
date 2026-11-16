class_name InteractTarget
extends Area2D
## Objetivo interactivo de un evento: al interactuar emite `activated`.
## El jugador lo detecta por su método `interact()` (convención IInteractable).

signal activated

@export var prompt_text: String = "Entregar"
## Textura opcional: si se define, se usa en lugar del cuadrado placeholder.
@export var sprite_texture: Texture2D

@onready var _prompt: Label = $Prompt
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_prompt.text = prompt_text
	_prompt.visible = false
	_build_placeholder_sprite()

func interact() -> void:
	activated.emit()

func set_prompt_visible(v: bool) -> void:
	_prompt.visible = v

func _build_placeholder_sprite() -> void:
	if sprite_texture != null:
		_sprite.texture = sprite_texture
		return
	_sprite.texture = PlaceholderArt.square(28, Color(0.8, 0.2, 0.2))
