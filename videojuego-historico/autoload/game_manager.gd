extends Node
## GameManager — estado global del juego (autoload).
## Guarda banderas de progreso, el evento activo y el spawn pendiente.
## Se amplía en la Fase 4 (eventos) y se usa desde la Fase 3.

## Banderas de progreso (ej. "is_hidalgo_saved").
var flags: Dictionary = {}

## Identificador del spawn pendiente al cambiar de escena (Fase 3).
var pending_spawn: String = ""

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func get_flag(key: String, default: bool = false) -> bool:
	return bool(flags.get(key, default))

func has_flag(key: String) -> bool:
	return flags.has(key)
