class_name EventEntry
extends Area2D
## Zona de entrada a un evento/escena. Cuando el jugador la toca, transiciona.

@export var scene_path: String = ""
@export var spawn_id: String = ""

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1  # detecta al jugador (capa 1)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneTransition.change_scene(scene_path, spawn_id)
