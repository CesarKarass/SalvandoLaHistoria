class_name FloatingJoystick
extends Control
## Joystick flotante: aparece donde el jugador toca (dentro de su zona) y re-centra
## la base si el dedo se aleja. Emite move_* con magnitud analógica y deadzone suave.
## Todo @export para ajustarlo en el Inspector.

@export_group("Joystick")
## Radio de recorrido del knob (px). Define cuánto hay que arrastrar para el máximo.
@export var radius: float = 70.0
## Zona muerta (0..1). Se re-mapea para que el arranque sea progresivo, sin salto.
@export var deadzone: float = 0.15
## Si el dedo excede el radio, la base se desplaza para que no se "escape".
@export var follow_finger: bool = true

@export_group("Apariencia")
@export var base_color: Color = Color(0.05, 0.04, 0.03, 0.35)
@export var knob_color: Color = Color(1.0, 0.85, 0.4, 0.6)
@export var ring_color: Color = Color(0.95, 0.82, 0.45, 0.4)
@export var fade_time: float = 0.12

var _active: bool = false
var _touch_index: int = -1
var _base_pos: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _alpha: float = 0.0
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(_delta: float) -> void:
	if _active or _alpha > 0.001:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			start_touch(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			end_touch()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_touch(event.position)
		else:
			end_touch()
		accept_event()
	elif event is InputEventMouseMotion and _active:
		drag(event.position)
		accept_event()

## Inicia el toque: el joystick aparece en `pos` (coordenadas locales del control).
func start_touch(pos: Vector2) -> void:
	_active = true
	_base_pos = pos
	_knob = Vector2.ZERO
	_fade(1.0)
	_emit(Vector2.ZERO)
	queue_redraw()

## Arrastra el knob hacia `pos` (con re-centrado opcional de la base).
func drag(pos: Vector2) -> void:
	if not _active:
		return
	var raw := pos - _base_pos
	var l := raw.length()
	if l > radius:
		raw = raw / l * radius
		if follow_finger:
			_base_pos = pos - raw
	_knob = raw
	_emit(raw / radius)
	queue_redraw()

## Suelta: el knob vuelve al centro y el joystick se desvanece.
func end_touch() -> void:
	_active = false
	_knob = Vector2.ZERO
	_fade(0.0)
	_emit(Vector2.ZERO)
	queue_redraw()

func _emit(dir: Vector2) -> void:
	var l := dir.length()
	var out := Vector2.ZERO
	if l > deadzone:
		out = dir.normalized() * ((l - deadzone) / (1.0 - deadzone))
	_set_action("move_right", maxf(out.x, 0.0))
	_set_action("move_left", maxf(-out.x, 0.0))
	_set_action("move_down", maxf(out.y, 0.0))
	_set_action("move_up", maxf(-out.y, 0.0))

func _set_action(action: String, strength: float) -> void:
	if strength > 0.01:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _fade(target: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_alpha", target, fade_time)

func _draw() -> void:
	if _alpha <= 0.001:
		return
	var a := _alpha
	draw_circle(_base_pos, radius, Color(base_color.r, base_color.g, base_color.b, base_color.a * a))
	draw_circle(_base_pos, radius, Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * a), false, 2.0)
	draw_circle(_base_pos + _knob, radius * 0.38, Color(knob_color.r, knob_color.g, knob_color.b, knob_color.a * a))
