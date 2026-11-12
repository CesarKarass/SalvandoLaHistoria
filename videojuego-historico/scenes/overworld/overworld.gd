extends LevelBase
## Overworld (mapa general).
## La aldea es la escena `overworld_map.tscn` (TileMapLayer + props + colisiones),
## instanciada como "Mapa" y editable en el editor. Aquí solo se coloca al
## jugador en el spawn indicado y se limita la cámara.

func _ready() -> void:
	place_player_at_spawn()
	clamp_camera_to_map()
