class_name NPC
extends Area2D
## NPC interactivo: detecta la proximidad del jugador (vía el InteractionArea del
## jugador) y muestra un prompt; al interactuar abre su diálogo.
## Capa de colisión: layer 3 (interactables), monitorable (es detectado por el jugador).

@export var dialogue: Dialogue
@export var prompt_text: String = "Hablar"

@onready var _prompt: Label = $Prompt
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_prompt.text = prompt_text
	_prompt.visible = false
	_build_placeholder_sprite()

## Punto de entrada de interacción (convención "IInteractable").
func interact() -> void:
	if dialogue != null:
		DialogueManager.start(dialogue)

func set_prompt_visible(v: bool) -> void:
	_prompt.visible = v

func _build_placeholder_sprite() -> void:
	var tex := PlaceholderTexture2D.new()
	tex.size = Vector2(16, 24)
	_sprite.texture = tex
