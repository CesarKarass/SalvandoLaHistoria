extends Area2D
class_name ZonaInteraccion
## Punto de evento del GDD (anomalía temporal, palanca, barricada, fuente...).
##
## Debe vivir en la capa de física 3 ("interaccion") y agregarse al grupo
## "interaccion" (lo hace automáticamente aquí) para que el jugador la detecte.

@export_multiline var mensaje: String = "Zona de interacción."
@export var pulsar: bool = true

var _tiempo: float = 0.0


func _ready() -> void:
	add_to_group("interaccion")
	_tiempo = randf() * TAU  # que no todos los objetos pulsen en fase


func _process(delta: float) -> void:
	if not pulsar:
		return
	_tiempo += delta * 3.0
	var escala := 1.0 + sin(_tiempo) * 0.07
	scale = Vector2(escala, escala)


func obtener_mensaje() -> String:
	return mensaje
