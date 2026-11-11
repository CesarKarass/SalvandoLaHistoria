class_name OptionsMenu
extends CanvasLayer
## Menú de opciones: volumen (general/música/efectos) y pantalla completa.
## Se muestra como overlay desde el menú principal o la pausa.

signal closed

var _value_labels: Dictionary = {}

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := UISkin.center()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UISkin.panel("MenuPanel")
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var col := UISkin.vbox(14)
	panel.add_child(col)

	col.add_child(UISkin.title("Opciones"))
	col.add_child(UISkin.spacer(8))

	var master := _add_slider(col, "Volumen general", Settings.master_volume)
	_add_slider(col, "Música", Settings.music_volume)
	_add_slider(col, "Efectos", Settings.sfx_volume)

	var fullscreen := CheckButton.new()
	fullscreen.text = "Pantalla completa"
	fullscreen.theme = UISkin.theme()
	fullscreen.button_pressed = Settings.fullscreen
	fullscreen.toggled.connect(_on_fullscreen)
	if _is_mobile():
		fullscreen.visible = false
	col.add_child(fullscreen)

	col.add_child(UISkin.spacer(8))

	var back := UISkin.button("Volver")
	back.pressed.connect(_on_back)
	col.add_child(back)

	master.grab_focus()

func _add_slider(parent: Control, title_text: String, value: int) -> HSlider:
	var row := UISkin.hbox(8)
	parent.add_child(row)

	var lab := UISkin.label(title_text, "BodyLabel")
	lab.custom_minimum_size = Vector2(170, 0)
	row.add_child(lab)

	var slider := HSlider.new()
	slider.theme = UISkin.theme()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size = Vector2(140, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider.bind(title_text))
	row.add_child(slider)

	var val := UISkin.label(str(value), "SmallLabel")
	val.custom_minimum_size = Vector2(36, 0)
	_value_labels[title_text] = val
	row.add_child(val)

	return slider

func _on_slider(v: float, title_text: String) -> void:
	var value := int(v)
	match title_text:
		"Volumen general":
			Settings.set_master_volume(value)
		"Música":
			Settings.set_music_volume(value)
		"Efectos":
			Settings.set_sfx_volume(value)
	if _value_labels.has(title_text):
		var lab: Label = _value_labels[title_text]
		lab.text = str(value)

func _on_fullscreen(pressed: bool) -> void:
	Settings.set_fullscreen(pressed)

func _on_back() -> void:
	closed.emit()
	queue_free()

func _is_mobile() -> bool:
	return DisplayServer.get_name() == "headless" or OS.get_name() == "Android" or OS.get_name() == "iOS"
