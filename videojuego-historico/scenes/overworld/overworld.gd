extends LevelBase
## Overworld (mapa general).
## La aldea es la escena `overworld_map.tscn` (TileMapLayer + props + colisiones),
## instanciada como "Mapa" y editable en el editor. Aquí solo se coloca al
## jugador en el spawn indicado y se limita la cámara.

const COLS := 24
const ROWS := 14

func _ready() -> void:
	place_player_at_spawn()
	TileWorld.clamp_camera(get_tree().get_first_node_in_group("player"), COLS, ROWS)
