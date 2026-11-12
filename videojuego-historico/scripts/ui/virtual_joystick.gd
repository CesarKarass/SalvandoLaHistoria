class_name TouchJoystick
extends Control
## Joystick virtual: alimenta las acciones move_* (analógicas) con toque o ratón.
## (No usar el nombre "VirtualJoystick": es una clase nativa de Godot 4.7.)

@export var deadzone: float = 0.2

var _dragging: bool = false
var _touch_index: int = -1
var _knob: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := _radius()
	draw_circle(c, r, Color(0.05, 0.04, 0.03, 0.45))
	draw_circle(c, r, Color(0.95, 0.82, 0.45, 0.55), false, 2.0)
	draw_circle(c + _knob * r, r * 0.38, Color(1.0, 0.85, 0.4, 0.7))

func _radius() -> float:
	return maxf(minf(size.x, size.y) * 0.5 - 4.0, 8.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_dragging = true
			apply_pos(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_dragging = false
			apply_reset()
		accept_event()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			apply_pos(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			apply_pos(event.position)
		else:
			_dragging = false
			apply_reset()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		apply_pos(event.position)
		accept_event()

func apply_pos(pos: Vector2) -> void:
	var c := size * 0.5
	var r := _radius()
	var offset := pos - c
	var l := offset.length()
	if l > r:
		offset = offset / l * r
	_knob = offset / r
	_emit(_knob)
	queue_redraw()

func apply_reset() -> void:
	_knob = Vector2.ZERO
	_emit(Vector2.ZERO)
	queue_redraw()

func _emit(dir: Vector2) -> void:
	var d := Vector2.ZERO
	if dir.length() >= deadzone:
		d = dir
	_set_action("move_right", maxf(d.x, 0.0))
	_set_action("move_left", maxf(-d.x, 0.0))
	_set_action("move_down", maxf(d.y, 0.0))
	_set_action("move_up", maxf(-d.y, 0.0))

func _set_action(action: String, strength: float) -> void:
	if strength > 0.01:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
