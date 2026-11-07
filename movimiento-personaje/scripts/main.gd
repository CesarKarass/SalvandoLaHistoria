extends Node2D
## ---------------------------------------------------------------------------
## ESCENA PRINCIPAL (prueba de movimiento cenital y colisiones)
## Construye el nivel, ubica al jugador en su punto de aparición y ajusta
## la cámara a los límites del mapa.
## ---------------------------------------------------------------------------

@onready var level: LevelMap = $Level
@onready var player: CharacterBody2D = $Level/Player
@onready var camera: Camera2D = $Level/Player/Camera2D


func _ready() -> void:
	# Colocar al jugador donde la matriz marcó la 'P'.
	player.position = level.spawn_position

	# La cámara suave no debe "viajar" desde el origen hasta el spawn:
	var b := level.bounds
	camera.limit_left = int(b.position.x)
	camera.limit_top = int(b.position.y)
	camera.limit_right = int(b.end.x)
	camera.limit_bottom = int(b.end.y)
	camera.reset_smoothing()
