class_name TouchButton
extends Control
## Botón táctil: al pulsar emite `tapped` y, si tiene `action`, también la acción
## de input (interact/inventory). `action` vacía = solo `tapped` (para la pausa).

signal tapped

@export var label: String = "A"
@export var action: String = ""

var _pressed: bool = false
var _touch_index: int = -1
var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	_build_label()
	queue_redraw()

func _build_label() -> void:
	_label = Label.new()
	_label.text = label
	_label.theme = UISkin.theme()
	_label.anchor_left = 0.0
	_label.anchor_top = 0.0
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _draw() -> void:
	var c := size * 0.5
	var r := maxf(minf(size.x, size.y) * 0.5 - 3.0, 8.0)
	draw_circle(c, r, Color(0.09, 0.07, 0.05, 0.55))
	draw_circle(c, r, Color(0.95, 0.82, 0.45, 0.7), false, 2.0)
	if _pressed:
		draw_circle(c, r, Color(1, 0.85, 0.4, 0.22))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_press()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_release()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press()
		else:
			_release()
		accept_event()

func _press() -> void:
	_pressed = true
	if action != "":
		Input.action_press(action)
	tapped.emit()
	queue_redraw()

func _release() -> void:
	if not _pressed:
		return
	_pressed = false
	if action != "":
		Input.action_release(action)
	queue_redraw()
