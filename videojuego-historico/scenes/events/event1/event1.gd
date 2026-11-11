class_name Event1
extends EventBase
## Evento 1: "El Duelo en la Plaza de Dolores" (1810).
## Victoria: interactuar con el objetivo "Antagonista" antes de que acabe el tiempo.
## (En la Fase 5 se validará que el jugador porte el ítem correcto.)

func _ready() -> void:
	super._ready()
	var target := get_node_or_null("Antagonista") as InteractTarget
	if target != null:
		target.activated.connect(_on_target_activated)

func _on_target_activated() -> void:
	win()

func _on_win() -> void:
	GameManager.set_flag("is_hidalgo_saved", true)
	if _hud != null:
		_hud.show_result("¡Victoria! Hidalgo está a salvo.")
	_set_player_movable(false)
	await get_tree().create_timer(1.2).timeout
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "SpawnFromEvent1")

func _on_lose() -> void:
	GameManager.set_flag("is_hidalgo_saved", false)
	if _hud != null:
		_hud.show_result("Derrota... el tiempo se agotó.")
	_set_player_movable(false)
	await get_tree().create_timer(1.5).timeout
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "SpawnFromEvent1")
