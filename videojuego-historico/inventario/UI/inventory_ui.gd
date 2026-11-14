extends CanvasLayer
## Maleta pixel art: UI de los datos persistentes del autoload Inventory.
## Los textos se distribuyen en dos paneles; la ayuda aparece una vez por instalación.

const CASE_SIZE := Vector2(820, 560)
const LID_SIZE := Vector2(820, 190)
const COVER_SIZE := Vector2(820, 340)
const TRAY_IMAGE: Texture2D = preload("res://inventario/art/suitcase_tray.png")
const LID_IMAGE: Texture2D = preload("res://inventario/art/suitcase_open_lid.png")
const COVER_IMAGE: Texture2D = preload("res://inventario/art/suitcase_closed_cover.png")
const TUTORIAL_SAVE_PATH := "user://inventario_ayuda.cfg"
const GOLD := Color("#f1c986")
const CREAM := Color("#f7ddac")
const MUTED := Color("#d4ac76")
const DANGER := Color("#ff9a83")

@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export var show_first_open_tutorial: bool = true
@export var tutorial_save_path: String = TUTORIAL_SAVE_PATH

var _overlay: Control
var _dim: ColorRect
var _case: Control
var _lid: TextureRect
var _closed_cover: TextureRect
var _contents: Control
var _grid: InventoryGrid
var _selection_label: Label
var _description_label: RichTextLabel
var _item_stats_label: Label
var _capacity_label: Label
var _free_label: Label
var _capacity_bar: ProgressBar
var _rotate_button: Button
var _close_button: Button
var _help_button: Button
var _tutorial_layer: Control
var _tutorial_panel: PanelContainer
var _tutorial_button: Button
var _tutorial_active: bool = false
var _error_panel: Panel
var _error_label: Label
var _player: Player
var _previous_can_move: bool = true
var _opened: bool = false
var _animation: Tween
var _shake_tween: Tween
var _message_tween: Tween


func _ready() -> void:
	layer = 15
	_build_ui()
	_overlay.visible = false
	_overlay.resized.connect(_position_case)
	_position_case()
	Inventory.inventory_changed.connect(_update_selection)
	Inventory.selection_changed.connect(_update_selection)
	_grid.rotation_rejected.connect(_show_rotation_error)
	_update_selection()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if _tutorial_active:
			_acknowledge_tutorial()
		else:
			toggle()
	if _opened and not _tutorial_active:
		for i in range(4):
			if Input.is_action_just_pressed("quick_" + str(i + 1)):
				Inventory.select(i)


func is_open() -> bool:
	return _opened


func toggle() -> void:
	if _opened:
		close()
	else:
		open()


func open() -> void:
	if _opened or get_tree().paused:
		return
	_opened = true
	_overlay.visible = true
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player != null:
		_previous_can_move = _player.can_move
		_player.can_move = false
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	_update_selection()
	_animate_open()


func close() -> void:
	if not _opened:
		return
	_opened = false
	# Si se cierra sin aceptar la guía, se volverá a ofrecer la próxima vez.
	_hide_tutorial()
	if is_instance_valid(_player):
		_player.can_move = _previous_can_move
	_player = null
	_set_buttons_enabled(false)
	_stop_feedback()
	_animate_close()


func _animate_open() -> void:
	_stop_animation()
	_dim.modulate.a = 0.0
	_lid.scale = Vector2(1.0, 0.025)
	_closed_cover.scale = Vector2.ONE
	_contents.modulate.a = 0.0
	_set_buttons_enabled(false)
	_animation = create_tween().set_parallel(true)
	_animation.set_speed_scale(animation_speed)
	_animation.set_trans(Tween.TRANS_SINE)
	_animation.set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(_dim, "modulate:a", 1.0, 0.28)
	_animation.tween_property(_closed_cover, "scale:y", 0.025, 0.35)
	_animation.tween_property(_lid, "scale:y", 1.0, 0.45).set_delay(0.12)
	_animation.tween_property(_contents, "modulate:a", 1.0, 0.20).set_delay(0.38)
	_animation.finished.connect(_on_open_finished)


func _animate_close() -> void:
	_stop_animation()
	_animation = create_tween().set_parallel(true)
	_animation.set_speed_scale(animation_speed)
	_animation.set_trans(Tween.TRANS_SINE)
	_animation.set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(_contents, "modulate:a", 0.0, 0.13)
	_animation.tween_property(_lid, "scale:y", 0.025, 0.30).set_delay(0.07)
	_animation.tween_property(_closed_cover, "scale:y", 1.0, 0.31).set_delay(0.16)
	_animation.tween_property(_dim, "modulate:a", 0.0, 0.23).set_delay(0.24)
	_animation.finished.connect(_on_close_finished)


func _on_open_finished() -> void:
	if not _opened:
		return
	if show_first_open_tutorial and not _tutorial_was_accepted():
		_show_tutorial()
	else:
		_set_buttons_enabled(true)


func _on_close_finished() -> void:
	if not _opened:
		_overlay.visible = false


func _stop_animation() -> void:
	if _animation != null and _animation.is_running():
		_animation.kill()


func _set_buttons_enabled(enabled: bool) -> void:
	_grid.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_rotate_button.disabled = not enabled
	_close_button.disabled = not enabled
	_help_button.disabled = not enabled


func _position_case() -> void:
	if _case == null or _overlay == null:
		return
	var screen_size: Vector2 = _overlay.size
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return
	var factor: float = minf(screen_size.x / CASE_SIZE.x, screen_size.y / CASE_SIZE.y) * 0.95
	_case.scale = Vector2.ONE * factor
	_case.position = (screen_size - CASE_SIZE * factor) * 0.5


func _update_selection() -> void:
	if _selection_label == null:
		return
	var selected: Item = Inventory.get_selected()
	if selected == null:
		_selection_label.text = "NINGÚN OBJETO"
		_description_label.text = "Recoge objetos del mundo y organízalos dentro de la maleta."
		_item_stats_label.text = "SIN SELECCIÓN"
	else:
		var name_text: String = selected.display_name if selected.display_name != "" else str(selected.id)
		_selection_label.text = name_text.to_upper()
		_selection_label.add_theme_font_size_override("font_size", 15 if name_text.length() > 21 else 17)
		_description_label.text = selected.description if selected.description != "" else "Objeto disponible para utilizar durante la aventura."
		var selected_entry: Dictionary = Inventory.items[Inventory.selected_index]
		var item_size: Vector2i = selected_entry["size"]
		_item_stats_label.text = "TAMAÑO: %d × %d    CANT.: %d" % [item_size.x, item_size.y, int(selected_entry["count"])]
	var occupied: int = 0
	var quantity: int = 0
	for entry: Dictionary in Inventory.items:
		var item_size: Vector2i = entry["size"]
		occupied += item_size.x * item_size.y
		quantity += int(entry["count"])
	_capacity_label.text = "ESPACIO   %02d / %02d" % [occupied, Inventory.MAX_SLOTS]
	_free_label.text = "LIBRES: %d  |  OBJETOS: %d" % [Inventory.MAX_SLOTS - occupied, quantity]
	_capacity_bar.value = occupied


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_dim = ColorRect.new()
	_dim.name = "Backdrop"
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.025, 0.016, 0.018, 0.83)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_dim)

	_case = Control.new()
	_case.name = "Suitcase"
	_case.size = CASE_SIZE
	_case.mouse_filter = Control.MOUSE_FILTER_PASS
	_overlay.add_child(_case)

	_case.add_child(_make_art("TrayArt", TRAY_IMAGE, Vector2.ZERO, CASE_SIZE))
	_lid = _make_art("OpenLid", LID_IMAGE, Vector2.ZERO, LID_SIZE)
	_lid.pivot_offset = Vector2(CASE_SIZE.x * 0.5, LID_SIZE.y)
	_case.add_child(_lid)

	_contents = Control.new()
	_contents.name = "Contents"
	_contents.size = CASE_SIZE
	_contents.mouse_filter = Control.MOUSE_FILTER_PASS
	_case.add_child(_contents)

	_grid = InventoryGrid.new()
	_grid.name = "InventoryGrid"
	_grid.position = Vector2(74, 210)
	_grid.size = Vector2(InventoryGrid.COLUMNS * InventoryGrid.CELL_SIZE, InventoryGrid.ROWS * InventoryGrid.CELL_SIZE)
	_contents.add_child(_grid)

	# Panel superior: título, objeto, descripción desplazable y datos físicos.
	_make_label("OBJETO SELECCIONADO", Vector2(508, 232), Vector2(222, 18), 12, GOLD, "SelectedHeading")
	_selection_label = _make_label("", Vector2(508, 254), Vector2(225, 38), 17, CREAM, "SelectedItem")
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_selection_label.clip_text = true
	var line := ColorRect.new()
	line.name = "TextDivider"
	line.position = Vector2(508, 297)
	line.size = Vector2(221, 2)
	line.color = Color("#815137")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.add_child(line)

	_description_label = RichTextLabel.new()
	_description_label.name = "Description"
	_description_label.position = Vector2(507, 307)
	_description_label.size = Vector2(224, 52)
	_description_label.bbcode_enabled = false
	_description_label.fit_content = false
	_description_label.scroll_active = true
	_description_label.scroll_following = false
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("normal_font_size", 13)
	_description_label.add_theme_color_override("default_color", MUTED)
	_description_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_description_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_contents.add_child(_description_label)
	_item_stats_label = _make_label("", Vector2(508, 369), Vector2(221, 17), 12, GOLD, "ItemStats")

	# Panel inferior: capacidad, barra visual y acciones. Sin instrucciones permanentes.
	_capacity_label = _make_label("", Vector2(508, 404), Vector2(220, 18), 14, GOLD, "Capacity")
	_capacity_bar = ProgressBar.new()
	_capacity_bar.name = "CapacityBar"
	_capacity_bar.position = Vector2(509, 426)
	_capacity_bar.size = Vector2(221, 8)
	_capacity_bar.min_value = 0
	_capacity_bar.max_value = Inventory.MAX_SLOTS
	_capacity_bar.show_percentage = false
	_capacity_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("#171521")
	bar_bg.set_border_width_all(1)
	bar_bg.border_color = Color("#8f603e")
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("#d49a58")
	_capacity_bar.add_theme_stylebox_override("background", bar_bg)
	_capacity_bar.add_theme_stylebox_override("fill", bar_fill)
	_contents.add_child(_capacity_bar)
	_free_label = _make_label("", Vector2(514, 428), Vector2(210, 18), 11, MUTED, "AvailableSpace")
	_free_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_free_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_free_label.clip_text = true
	
	_rotate_button = _make_button("GIRAR [R]", Vector2(505, 462), Vector2(92, 31))
	_rotate_button.name = "RotateButton"
	_rotate_button.pressed.connect(_rotate_selected)
	_close_button = _make_button("CERRAR [I]", Vector2(603, 462), Vector2(90, 31))
	_close_button.name = "CloseButton"
	_close_button.pressed.connect(close)
	_help_button = _make_button("?", Vector2(700, 462), Vector2(31, 31))
	_help_button.name = "HelpButton"
	_help_button.tooltip_text = "Volver a ver las instrucciones"
	_help_button.pressed.connect(_show_tutorial)

	_error_panel = Panel.new()
	_error_panel.name = "RotationError"
	_error_panel.position = Vector2(128, 193)
	_error_panel.size = Vector2(290, 33)
	_error_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var error_style := StyleBoxFlat.new()
	error_style.bg_color = Color("#30171c")
	error_style.border_color = Color("#ef7f65")
	error_style.set_border_width_all(2)
	_error_panel.add_theme_stylebox_override("panel", error_style)
	_contents.add_child(_error_panel)
	_error_label = Label.new()
	_error_label.text = "NO HAY ESPACIO PARA GIRAR"
	_error_label.size = _error_panel.size
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_error_label.add_theme_font_size_override("font_size", 13)
	_error_label.add_theme_color_override("font_color", DANGER)
	_error_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_error_panel.add_child(_error_label)
	_error_panel.visible = false

	_closed_cover = _make_art("ClosedCover", COVER_IMAGE, Vector2(0, 188), COVER_SIZE)
	_closed_cover.pivot_offset = Vector2(COVER_SIZE.x * 0.5, 0)
	_case.add_child(_closed_cover)
	_build_tutorial()


func _build_tutorial() -> void:
	_tutorial_layer = Control.new()
	_tutorial_layer.name = "TutorialLayer"
	_tutorial_layer.size = CASE_SIZE
	_tutorial_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_case.add_child(_tutorial_layer)
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.size = CASE_SIZE
	shade.color = Color(0.02, 0.01, 0.02, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_layer.add_child(shade)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "HelpCard"
	_tutorial_panel.position = Vector2(162, 181)
	_tutorial_panel.size = Vector2(496, 294)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#2b1d1c")
	card_style.border_color = Color("#ce9353")
	card_style.set_border_width_all(4)
	card_style.set_content_margin_all(19)
	_tutorial_panel.add_theme_stylebox_override("panel", card_style)
	_tutorial_layer.add_child(_tutorial_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_tutorial_panel.add_child(content)

	var title := Label.new()
	title.text = "CÓMO USAR TU MALETA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", GOLD)
	content.add_child(title)

	var separator := HSeparator.new()
	content.add_child(separator)
	var instructions := Label.new()
	instructions.text = "• Clic o toque: selecciona un objeto.\n• Arrastra: muévelo entre las casillas.\n• R o GIRAR: rota el objeto 90 grados.\n• Si no cabe, buscará otro espacio disponible.\n• Las teclas 1–4 seleccionan objetos; I cierra la maleta."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", CREAM)
	content.add_child(instructions)

	var note := Label.new()
	note.text = "Esta guía solo aparecerá automáticamente una vez.\nPuedes abrirla otra vez con el botón ?"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", MUTED)
	content.add_child(note)

	_tutorial_button = Button.new()
	_tutorial_button.name = "UnderstoodButton"
	_tutorial_button.text = "ENTENDIDO"
	_tutorial_button.custom_minimum_size = Vector2(0, 34)
	_style_button(_tutorial_button)
	_tutorial_button.pressed.connect(_acknowledge_tutorial)
	content.add_child(_tutorial_button)
	_tutorial_layer.visible = false


func _tutorial_was_accepted() -> bool:
	var config := ConfigFile.new()
	if config.load(tutorial_save_path) != OK:
		return false
	return bool(config.get_value("inventario", "ayuda_aceptada", false))


func _show_tutorial() -> void:
	if not _opened or _tutorial_active:
		return
	_tutorial_active = true
	_tutorial_layer.visible = true
	_tutorial_layer.modulate.a = 0.0
	_set_buttons_enabled(false)
	var entrance := create_tween()
	entrance.tween_property(_tutorial_layer, "modulate:a", 1.0, 0.18)
	_tutorial_button.grab_focus()


func _acknowledge_tutorial() -> void:
	if not _tutorial_active:
		return
	var config := ConfigFile.new()
	config.set_value("inventario", "ayuda_aceptada", true)
	var error := config.save(tutorial_save_path)
	if error != OK:
		push_warning("No fue posible guardar el estado de la ayuda del inventario.")
	_hide_tutorial()
	if _opened:
		_set_buttons_enabled(true)


func _hide_tutorial() -> void:
	_tutorial_active = false
	_tutorial_layer.visible = false
	if is_instance_valid(_tutorial_button):
		_tutorial_button.release_focus()


func _show_rotation_error() -> void:
	if not _opened or _tutorial_active:
		return
	_stop_feedback()
	_error_panel.visible = true
	_error_panel.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(0.45)
	_message_tween.tween_property(_error_panel, "modulate:a", 0.0, 0.25)
	_message_tween.finished.connect(_hide_rotation_error)
	var center: Vector2 = _case.position
	_shake_tween = create_tween()
	for dx in [7.0, -7.0, 5.0, -5.0, 2.0, -2.0, 0.0]:
		_shake_tween.tween_property(_case, "position", center + Vector2(dx, 0), 0.035)


func _hide_rotation_error() -> void:
	_error_panel.visible = false


func _stop_feedback() -> void:
	if _shake_tween != null and _shake_tween.is_running():
		_shake_tween.kill()
	if _message_tween != null and _message_tween.is_running():
		_message_tween.kill()
	_error_panel.visible = false
	_position_case()


func _make_art(node_name: String, texture: Texture2D, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.position = pos
	image.size = dimensions
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _make_label(value: String, pos: Vector2, dimensions: Vector2, font_size: int, text_color: Color, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_shadow_color", Color("#120d14"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.add_child(label)
	return label


func _style_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", CREAM)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#4c291d") if state != "hover" else Color("#794326")
		if state == "pressed":
			box.bg_color = Color("#291a18")
		box.border_color = Color("#bd8041") if state != "hover" else GOLD
		box.set_border_width_all(2)
		box.content_margin_left = 3
		box.content_margin_right = 3
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_button(value: String, pos: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = pos
	button.size = dimensions
	_style_button(button)
	_contents.add_child(button)
	return button


func _rotate_selected() -> void:
	_grid.rotate_item()
