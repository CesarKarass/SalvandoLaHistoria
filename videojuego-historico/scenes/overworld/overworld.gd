extends LevelBase
## Overworld (mapa general): construye la aldea (casas, plaza, pozo, árboles)
## y coloca al jugador en el spawn indicado.

const COLS := 24
const ROWS := 14

func _ready() -> void:
	TileWorld.build_village(self, COLS, ROWS)
	place_player_at_spawn()
	TileWorld.clamp_camera(get_tree().get_first_node_in_group("player"), COLS, ROWS)
