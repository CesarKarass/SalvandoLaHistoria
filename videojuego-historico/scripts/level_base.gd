class_name LevelBase
extends Node2D
## Base para escenas de nivel: coloca al jugador en el spawn indicado y limita
## la cámara al tamaño del mapa.
## Convención: los Marker2D de spawn viven bajo "Spawns"; el spawn por defecto
## es "Spawns/SpawnDefault" y GameManager.pending_spawn selecciona otro por nombre.
## El mapa es la escena instanciada como "Mapa" (con un TileMapLayer "Room").

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

## Limita la cámara a los tiles usados del mapa, para no ver el vacío.
## Se calcula desde el TileMapLayer, así que si agrandas el mapa en el editor
## los límites se ajustan solos.
func clamp_camera_to_map() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var room := get_node_or_null("Mapa/Room") as TileMapLayer
	if room == null or room.tile_set == null:
		return
	var used := room.get_used_rect()
	var tile := room.tile_set.tile_size
	cam.limit_left = used.position.x * tile.x
	cam.limit_top = used.position.y * tile.y
	cam.limit_right = used.end.x * tile.x
	cam.limit_bottom = used.end.y * tile.y
