class_name HUD
extends CanvasLayer
## HUD del evento: cuenta atrás y mensaje de resultado (estilado por UISkin).

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
	_time_label = UISkin.label("Tiempo: 0s", "HudLabel")
	_time_label.position = Vector2(20, 16)
	add_child(_time_label)

	_result_label = UISkin.label("", "TitleLabel")
	_result_label.anchor_left = 0.0
	_result_label.anchor_right = 1.0
	_result_label.anchor_top = 0.32
	_result_label.anchor_bottom = 0.32
	_result_label.offset_top = -28.0
	_result_label.offset_bottom = 28.0
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)
