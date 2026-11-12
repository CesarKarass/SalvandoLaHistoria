class_name NPC
extends Area2D
## NPC interactivo: detecta la proximidad del jugador (vía el InteractionArea del
## jugador) y muestra un prompt; al interactuar abre su diálogo.
## Capa de colisión: layer 3 (interactables), monitorable (es detectado por el jugador).

@export var dialogue: Dialogue
@export var sprite_texture: Texture2D
@export var prompt_text: String = "Hablar"

@onready var _prompt: Label = $Prompt
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_prompt.text = prompt_text
	_prompt.visible = false
	_apply_sprite()

## Punto de entrada de interacción (convención "IInteractable").
func interact() -> void:
	if dialogue != null:
		DialogueManager.start(dialogue)

func set_prompt_visible(v: bool) -> void:
	_prompt.visible = v

func _apply_sprite() -> void:
	if sprite_texture != null:
		_sprite.texture = sprite_texture
	else:
		var tex := PlaceholderTexture2D.new()
		tex.size = Vector2(64, 64)
		_sprite.texture = tex
