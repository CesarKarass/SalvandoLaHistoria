class_name TouchButton
extends Control
## Botón táctil con "juice": encoge al pulsar, rebota al soltar y emite un anillo
## de pulso. `action` vacía = solo `tapped` (para la pausa). Todo @export.

signal tapped

@export_group("Apariencia")
@export var label: String = "A"
@export var action: String = ""
@export var base_color: Color = Color(0.09, 0.07, 0.05, 0.55)
@export var pressed_color: Color = Color(1.0, 0.85, 0.4, 0.35)
@export var ring_color: Color = Color(0.95, 0.82, 0.45, 0.7)
@export var label_color: Color = Color(1.0, 0.95, 0.85)

@export_group("Juice")
## Escala a la que encoge al pulsar (1.0 = sin encoger).
@export var press_scale: float = 0.88
@export var press_time: float = 0.07
@export var release_time: float = 0.18
## Rebote elástico al soltar.
@export var bounce: bool = true
## Tamaño máximo del anillo de pulso (× radio).
@export var pulse_radius: float = 1.6

var _pressed: bool = false
var _touch_index: int = -1
var _pulse: float = -1.0
var _tween: Tween
var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	resized.connect(_on_resized)
	_build_label()
	queue_redraw()

func _process(delta: float) -> void:
	if _pulse >= 0.0:
		_pulse += delta / maxf(release_time * 2.0, 0.01)
		if _pulse >= 1.0:
			_pulse = -1.0
		queue_redraw()

func _on_resized() -> void:
	pivot_offset = size * 0.5
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
	_label.add_theme_color_override("font_color", label_color)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _draw() -> void:
	var c := size * 0.5
	var r := maxf(minf(size.x, size.y) * 0.5 - 3.0, 8.0)
	draw_circle(c, r, pressed_color if _pressed else base_color)
	draw_circle(c, r, ring_color, false, 2.0)
	if _pulse >= 0.0:
		var pr := r * lerpf(1.0, pulse_radius, _pulse)
		draw_circle(c, pr, Color(ring_color.r, ring_color.g, ring_color.b, (1.0 - _pulse) * 0.6), false, 2.0)

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
	if _pressed:
		return
	_pressed = true
	if action != "":
		Input.action_press(action)
	tapped.emit()
	_juice_press()

func _release() -> void:
	if not _pressed:
		return
	_pressed = false
	if action != "":
		Input.action_release(action)
	_juice_release()

func _juice_press() -> void:
	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * press_scale, press_time)
	_pulse = 0.0

func _juice_release() -> void:
	_kill_tween()
	_tween = create_tween()
	if bounce:
		_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", Vector2.ONE, release_time)
	else:
		_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", Vector2.ONE, release_time)
	queue_redraw()

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
