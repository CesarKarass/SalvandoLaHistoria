class_name Player
extends CharacterBody2D
## Jugador: movimiento cenital en 8 direcciones estilo "Moonlighter".
## Capa de colisión: layer 1 (player), mask 2 (walls).
## El sprite se coloca con los "pies" sobre el origen; la forma de colisión es un círculo en los pies.

@export var speed: float = 120.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0

## Permite bloquear el movimiento (diálogos, transiciones, derrota).
@export var can_move: bool = true

## Dirección a la que mira el personaje: "down", "up", "left" o "right".
var facing: String = "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_ensure_placeholder_frames()
	_update_animation()

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
## Cuando exista un SpriteFrames real, se asigna en el editor y esto se omite.
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
