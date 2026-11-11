class_name LevelBase
extends Node2D
## Base para escenas de nivel: coloca al jugador en el spawn indicado.
## Convención: los Marker2D de spawn viven bajo "Spawns"; el spawn por defecto
## es "Spawns/SpawnDefault" y GameManager.pending_spawn selecciona otro por nombre.

func place_player_at_spawn() -> void:
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
