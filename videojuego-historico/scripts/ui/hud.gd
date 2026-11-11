class_name HUD
extends CanvasLayer
## HUD del evento: cuenta atrás y mensaje de resultado.

var _time_label: Label
var _result_label: Label

func _ready() -> void:
	_build_ui()
	_result_label.visible = false

func set_time(remaining: float) -> void:
	_time_label.text = "Tiempo: " + str(ceili(maxf(remaining, 0.0))) + "s"

func show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true

func _build_ui() -> void:
	_time_label = Label.new()
	_time_label.position = Vector2(20, 16)
	_time_label.add_theme_font_size_override("font_size", 26)
	_time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	add_child(_time_label)

	_result_label = Label.new()
	_result_label.anchor_left = 0.0
	_result_label.anchor_right = 1.0
	_result_label.anchor_top = 0.32
	_result_label.anchor_bottom = 0.32
	_result_label.offset_top = -28.0
	_result_label.offset_bottom = 28.0
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 40)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	add_child(_result_label)
