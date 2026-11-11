class_name Player
extends CharacterBody2D
## Jugador: movimiento cenital en 8 direcciones estilo "Moonlighter" + interacción.
## Capa de colisión: layer 1 (player), mask 2 (walls). Interactúa con la capa 3 (interactables).

@export var speed: float = 120.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0

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
	_ensure_placeholder_frames()
	_update_animation()
	add_to_group("player")
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if can_move:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target: Vector2 = dir * speed
	var rate: float = acceleration if dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()
	if dir != Vector2.ZERO:
		_update_facing(dir)
	_update_animation()

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

func _update_animation() -> void:
	if facing == "left" or facing == "right":
		sprite.animation = "side"
		sprite.flip_h = facing == "left"
	else:
		sprite.animation = facing
		sprite.flip_h = false

## Crea frames placeholder (1 cuadro por dirección) cuando no hay arte.
func _ensure_placeholder_frames() -> void:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames != null and not frames.get_animation_names().is_empty():
		return
	var tex := PlaceholderTexture2D.new()
	tex.size = Vector2(16, 24)
	frames = SpriteFrames.new()
	for anim: StringName in ["down", "up", "side"]:
		frames.add_animation(anim)
		frames.add_frame(anim, tex)
	sprite.sprite_frames = frames
