@tool
extends LevelBase
## Overworld (mapa general): construye la aldea (casas, plaza, pozo, árboles)
## y coloca al jugador en el spawn indicado.
##
## Es `@tool` para que el mapa también se construya en el EDITOR: la aldea se
## genera en código, así que sin esto la escena se veía vacía en Godot.
## En el editor los nodos generados no tienen `owner`, por lo que son solo una
## vista previa y no se guardan dentro de overworld.tscn.

const COLS := 24
const ROWS := 14

func _ready() -> void:
	TileWorld.build_village(self, COLS, ROWS)
	if Engine.is_editor_hint():
		return
	place_player_at_spawn()
	TileWorld.clamp_camera(get_tree().get_first_node_in_group("player"), COLS, ROWS)
