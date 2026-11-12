class_name Player
extends CharacterBody2D
## Jugador: movimiento cenital en 8 direcciones estilo "Moonlighter" + interacción.
## Usa los sprites reales (player_idle.png / player_walk.png, frames de 64x64) con
## animaciones idle_/walk_ por dirección; si faltan, cae a un placeholder.

const FRAME_SIZE := 64
const ROW_BY_FACING := {
	"down": 0,
	"left": 2,
	"up": 4,
	"right": 6,
}

@export_group("Movimiento")
@export var speed: float = 120.0
## Suavizado exponencial de arranque (1/s). Mayor = más "pegado" al stick.
@export var accel_rate: float = 22.0
## Suavizado exponencial de freno (1/s). Mayor = frena antes.
@export var decel_rate: float = 18.0
## Por debajo de esta velocidad (px/s) se clava a 0 para no "patinar".
@export var stop_threshold: float = 8.0
## Permite bloquear el movimiento (diálogos, transiciones, derrota).
@export var can_move: bool = true

## Dirección a la que mira el personaje: "down", "up", "left" o "right".
var facing: String = "down"

var _nearby: Array[Area2D] = []
var _nearest: Area2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_build_frames()
	_update_animation(false)
	add_to_group("player")
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if can_move:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length(1.0)

	var target: Vector2 = dir * speed
	if dir != Vector2.ZERO:
		# Aceleración exponencial: arranque suave (independiente del frame-rate).
		velocity = velocity.lerp(target, 1.0 - exp(-accel_rate * delta))
	else:
		# Freno exponencial con "ease-out": nunca frena en seco.
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-decel_rate * delta))
		if velocity.length() < stop_threshold:
			velocity = Vector2.ZERO

	_slide_and_move(delta)
	if dir != Vector2.ZERO:
		_update_facing(dir)
	_update_animation(dir != Vector2.ZERO)

## Mueve por eje para que el jugador se deslice por las esquinas en diagonal:
## si un eje choca, se anula y el otro sigue (no se queda atorado).
func _slide_and_move(delta: float) -> void:
	if velocity.x != 0.0:
		if move_and_collide(Vector2(velocity.x * delta, 0.0)) != null:
			velocity.x = 0.0
	if velocity.y != 0.0:
		if move_and_collide(Vector2(0.0, velocity.y * delta)) != null:
			velocity.y = 0.0

func _process(_delta: float) -> void:
	_update_nearest()
	if can_move and Input.is_action_just_pressed("interact"):
		_try_interact()

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.has_method("interact") and not _nearby.has(area):
		_nearby.append(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	_nearby.erase(area)

func _update_nearest() -> void:
	# Limpia referencias a nodos liberados (ej. pickups recogidos).
	for i in range(_nearby.size() - 1, -1, -1):
		if not is_instance_valid(_nearby[i]):
			_nearby.remove_at(i)
	if _nearest != null and not is_instance_valid(_nearest):
		_nearest = null
	var best: Area2D = null
	var best_d := INF
	for n: Area2D in _nearby:
		var d: float = global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != _nearest:
		if _nearest != null and _nearest.has_method("set_prompt_visible"):
			_nearest.call("set_prompt_visible", false)
		_nearest = best
		if _nearest != null and _nearest.has_method("set_prompt_visible"):
			_nearest.call("set_prompt_visible", true)

func _try_interact() -> void:
	if _nearest != null and _nearest.has_method("interact"):
		_nearest.call("interact")

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0.0 else "left"
	else:
		facing = "down" if dir.y > 0.0 else "up"

func _update_animation(is_moving: bool) -> void:
	var prefix := "walk_" if is_moving else "idle_"
	var anim := prefix + facing
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		sprite.animation = anim
	sprite.flip_h = false

func _build_frames() -> void:
	var idle_tex: Texture2D = load("res://assets/sprites/player_idle.png") as Texture2D
	var walk_tex: Texture2D = load("res://assets/sprites/player_walk.png") as Texture2D
	if idle_tex == null or walk_tex == null:
		_build_placeholder_frames()
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for facing_key: String in ROW_BY_FACING.keys():
		var row: int = int(ROW_BY_FACING[facing_key])
		frames.add_animation("idle_" + facing_key)
		frames.set_animation_speed("idle_" + facing_key, 3.0)
		for c in 2:
			frames.add_frame("idle_" + facing_key, _make_atlas(idle_tex, c, row))
		frames.add_animation("walk_" + facing_key)
		frames.set_animation_speed("walk_" + facing_key, 8.0)
		for c in 4:
			frames.add_frame("walk_" + facing_key, _make_atlas(walk_tex, c, row))
	sprite.sprite_frames = frames

func _build_placeholder_frames() -> void:
	var tex := PlaceholderTexture2D.new()
	tex.size = Vector2(FRAME_SIZE, FRAME_SIZE)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for facing_key: String in ROW_BY_FACING.keys():
		frames.add_animation("idle_" + facing_key)
		frames.add_frame("idle_" + facing_key, tex)
		frames.add_animation("walk_" + facing_key)
		frames.add_frame("walk_" + facing_key, tex)
	sprite.sprite_frames = frames

func _make_atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	return at
