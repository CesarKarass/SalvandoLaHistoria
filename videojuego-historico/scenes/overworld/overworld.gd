extends LevelBase
## Overworld (mapa general): coloca al jugador en el spawn indicado.
## El contenido visual/tilemap definitivo se añade en fases posteriores.

func _ready() -> void:
	place_player_at_spawn()
