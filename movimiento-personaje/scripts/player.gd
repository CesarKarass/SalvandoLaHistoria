extends CharacterBody2D
## ---------------------------------------------------------------------------
## PROTAGONISTA — Movimiento cenital de 8 direcciones (estilo Moonlighter)
## y colisiones contra los bloques del escenario.
##
## Hitbox y capas de física (configuradas en player.tscn):
##   Capa 1 "mundo"         → paredes y edificios (sólidos, StaticBody2D)
##   Capa 2 "jugador"       → este nodo (CharacterBody2D)
##   Capa 3 "interactuable" → NPCs con los que se puede hablar
##   collision_mask = 5 (mundo + interactuable): el jugador choca con
##   paredes/edificios y con los NPCs (no se atraviesan nada).
##
## La hitbox es un rectángulo pequeño a los pies (26x16) y NO toda la
## imagen de 64x64: así el sprite puede "pisar" por delante de un muro
## sin que el personaje se pegue a él, igual que en Moonlighter/Zelda.
## ---------------------------------------------------------------------------

## Velocidad máxima de caminar (px/s).
@export var max_speed: float = 190.0
## Aceleración al recibir input: respuesta rápida ("snappy") al empezar.
@export var acceleration: float = 1600.0
## Fricción al soltar los controles: el personaje frena en seco.
@export var friction: float = 2200.0
## false = movimiento en 4 direcciones (sin diagonales), true = 8 direcciones.
@export var allow_diagonals: bool = true

## Tamaño de cada frame de las hojas de sprites (GDD: 64x64).
const FRAME: int = 64
const SHEET_IDLE: Texture2D = preload("res://assets/sprites/player_idle.png")
const SHEET_WALK: Texture2D = preload("res://assets/sprites/player_walk.png")

## Nombres de las 8 animaciones, en el mismo orden que las filas de las hojas.
const DIR_NAMES: Array[String] = [
	"down", "down_left", "left", "up_left",
	"up", "up_right", "right", "down_right",
]

## Vectores canónicos de las 8 direcciones (mismo orden que DIR_NAMES).
const DIR_VECTORS: Array[Vector2] = [
	Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1),
	Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1),
]

## Dirección a la que mira el personaje (se conserva al detenerse).
var facing: int = 0
## NPCs/objetos que actualmente están dentro del área de interacción.
var nearby_bodies: Array[Node2D] = []

## Se emite cuando el jugador presiona "Interact" junto a un NPC.
signal interacted(target: Node2D)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	_build_sprite_frames()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_move(delta)
	_update_animation()
	_try_interact()


# ---------------------------------------------------------------------------
# Movimiento
# ---------------------------------------------------------------------------
func _move(delta: float) -> void:
	# get_vector ya normaliza las diagonales: no se mueve más rápido en diagonal.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not allow_diagonals:
		input_dir = _snap_to_cardinal(input_dir)

	var target_velocity := input_dir * max_speed
	var rate := acceleration if input_dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(target_velocity, rate * delta)

	# move_and_slide() resuelve TODAS las colisiones del escenario:
	# desliza a lo largo de paredes/edificios sin quedarse pegado en esquinas.
	move_and_slide()


func _snap_to_cardinal(dir: Vector2) -> Vector2:
	"""Modo 4 direcciones: se queda con el eje dominante."""
	if absf(dir.x) > absf(dir.y):
		return Vector2(signf(dir.x), 0.0)
	return Vector2(0.0, signf(dir.y))


# ---------------------------------------------------------------------------
# Animaciones (estilo Moonlighter: una animación por dirección)
# ---------------------------------------------------------------------------
func _build_sprite_frames() -> void:
	"""Crea las animaciones idle_* y walk_* a partir de las hojas de sprites."""
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	for i in DIR_NAMES.size():
		# idle: 2 frames de respiración a 3 fps
		_add_animation(frames, "idle_" + DIR_NAMES[i], SHEET_IDLE, i, 2, 3.0)
		# walk: 4 frames de paso a 9 fps
		_add_animation(frames, "walk_" + DIR_NAMES[i], SHEET_WALK, i, 4, 9.0)

	sprite.sprite_frames = frames
	sprite.play("idle_down")


func _add_animation(
	frames: SpriteFrames,
	anim_name: String,
	sheet: Texture2D,
	row: int,
	frame_count: int,
	fps: float
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, true)
	for f in frame_count:
		var frame_tex := AtlasTexture.new()
		frame_tex.atlas = sheet
		# Cada dirección es una fila; cada frame una columna de 64x64.
		frame_tex.region = Rect2(f * FRAME, row * FRAME, FRAME, FRAME)
		frames.add_frame(anim_name, frame_tex)


func _update_animation() -> void:
	if velocity.length_squared() > 4.0:
		# En movimiento: elegir la dirección más cercana a la velocidad real.
		facing = _closest_direction(velocity)
		_play_if_changed("walk_" + DIR_NAMES[facing])
	else:
		# Quieto: mantener la última dirección mirada (como en Moonlighter).
		_play_if_changed("idle_" + DIR_NAMES[facing])


func _play_if_changed(anim_name: String) -> void:
	if sprite.animation != StringName(anim_name):
		sprite.play(anim_name)


func _closest_direction(dir: Vector2) -> int:
	"""Devuelve el índice de las 8 direcciones más cercano al vector dado."""
	var normalized := dir.normalized()
	var best_index := 0
	var best_dot := -2.0
	for i in DIR_VECTORS.size():
		var dot := normalized.dot(DIR_VECTORS[i].normalized())
		if dot > best_dot:
			best_dot = dot
			best_index = i
	return best_index


# ---------------------------------------------------------------------------
# Interacción (hitbox Area2D que detecta NPCs en la capa 3)
# ---------------------------------------------------------------------------
func _try_interact() -> void:
	if Input.is_action_just_pressed("interact") and not nearby_bodies.is_empty():
		var target: Node2D = nearby_bodies.back()
		interacted.emit(target)
		if target.has_method("interact"):
			target.call("interact")


func _on_body_entered(body: Node2D) -> void:
	if body != self and not nearby_bodies.has(body):
		nearby_bodies.append(body)


func _on_body_exited(body: Node2D) -> void:
	nearby_bodies.erase(body)
