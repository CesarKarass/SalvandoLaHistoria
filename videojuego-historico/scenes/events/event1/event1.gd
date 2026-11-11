extends Node2D
## Evento 1 (mapa de acción): coloca al jugador en el spawn indicado.
## El temporizador, HUD y lógica del evento se añaden en la Fase 4.

func _ready() -> void:
	_place_player()

func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var spawn_name: String = GameManager.pending_spawn
	var marker: Marker2D = null
	if spawn_name != "":
		marker = get_node_or_null("Spawns/" + spawn_name) as Marker2D
	if marker == null:
		marker = get_node_or_null("Spawns/SpawnDefault") as Marker2D
	if marker != null:
		player.global_position = marker.global_position
	GameManager.pending_spawn = ""
