extends CanvasLayer
## Maleta de viaje pixel art: presentación del inventario espacial compartido.
## La animación sólo afecta a la interfaz; los objetos viven en Inventory (autoload).

@export_range(0.1, 3.0, 0.1)
var animation_speed: float = 1.0

const CASE_SIZE := Vector2(820, 560)
const LID_SIZE := Vector2(820, 190)
const COVER_SIZE := Vector2(820, 340)
const TRAY_IMAGE: Texture2D = preload("res://inventario/art/suitcase_tray.png")
const LID_IMAGE: Texture2D = preload("res://inventario/art/suitcase_open_lid.png")
const COVER_IMAGE: Texture2D = preload("res://inventario/art/suitcase_closed_cover.png")
const GOLD := Color("#f1c986")
const CREAM := Color("#f7ddac")
const MUTED := Color("#d4ac76")

var _overlay: Control
var _dim: ColorRect
var _case: Control
var _lid: TextureRect
var _closed_cover: TextureRect
var _contents: Control
var _grid: InventoryGrid
var _selection_label: Label
var _description_label: Label
var _capacity_label: Label
var _hint_label: Label
var _rotate_button: Button
var _close_button: Button
var _player: Player
var _previous_can_move: bool = true
var _opened: bool = false
var _animation: Tween


func _ready() -> void:
	layer = 15
	_build_ui()
	_overlay.visible = false
	_overlay.resized.connect(_position_case)
	_position_case()
	Inventory.inventory_changed.connect(_update_selection)
	Inventory.selection_changed.connect(_update_selection)
	_update_selection()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle()
	for i in range(4):
		if Input.is_action_just_pressed("quick_" + str(i + 1)):
			Inventory.select(i)


func is_open() -> bool:
	# Refleja el estado lógico incluso mientras la maleta termina de cerrarse.
	return _opened


func toggle() -> void:
	if is_open():
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
	# Soltar el joystick virtual para evitar movimiento detrás de la maleta.
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	_update_selection()
	_animate_open()


func close() -> void:
	if not _opened:
		return
	_opened = false
	if is_instance_valid(_player):
		_player.can_move = _previous_can_move
	_player = null
	_set_buttons_enabled(false)
	_animate_close()


func _animate_open() -> void:
	_stop_animation()
	# Primero se ve una maleta cerrada; después la tapa se pliega hacia arriba.
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
	if _opened:
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
		_selection_label.text = "NINGUN OBJETO"
		_description_label.text = "Recoge objetos del mundo y organízalos dentro de la maleta."
	else:
		_selection_label.text = selected.display_name.to_upper() if selected.display_name != "" else str(selected.id).to_upper()
		_description_label.text = selected.description if selected.description != "" else "Selecciona, mueve o gira el objeto para organizar tu equipaje."
	var occupied: int = 0
	for entry: Dictionary in Inventory.items:
		var item_size: Vector2i = entry["size"]
		occupied += item_size.x * item_size.y
	_capacity_label.text = "ESPACIO   %02d / %02d" % [occupied, Inventory.MAX_SLOTS]
	_hint_label.text = "ARRASTRAR: MOVER\nR: GIRAR    1-4: ELEGIR"


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

	var tray := _make_art("TrayArt", TRAY_IMAGE, Vector2.ZERO, CASE_SIZE)
	_case.add_child(tray)

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

	_make_label("OBJETO SELECCIONADO", Vector2(502, 224), Vector2(236, 23), 15, GOLD, "SelectedHeading")
	_selection_label = _make_label("", Vector2(502, 248), Vector2(236, 22), 17, CREAM, "SelectedItem")
	_description_label = _make_label("", Vector2(502, 297), Vector2(236, 83), 15, MUTED, "Description")
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capacity_label = _make_label("", Vector2(502, 398), Vector2(235, 20), 16, GOLD, "Capacity")
	_hint_label = _make_label("", Vector2(502, 419), Vector2(233, 45), 12, MUTED, "Help")

	_rotate_button = _make_button("ROTAR [R]", Vector2(504, 466), Vector2(110, 32))
	_rotate_button.name = "RotateButton"
	_rotate_button.pressed.connect(_rotate_selected)
	_close_button = _make_button("CERRAR [I]", Vector2(624, 466), Vector2(112, 32))
	_close_button.name = "CloseButton"
	_close_button.pressed.connect(close)

	# Se pinta por encima de toda la bandeja y los objetos durante el cierre.
	_closed_cover = _make_art("ClosedCover", COVER_IMAGE, Vector2(0, 188), COVER_SIZE)
	_closed_cover.pivot_offset = Vector2(COVER_SIZE.x * 0.5, 0)
	_case.add_child(_closed_cover)


func _make_art(name: String, texture: Texture2D, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.name = name
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
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.add_child(label)
	return label


func _make_button(value: String, pos: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = pos
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 14)
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
		box.set_corner_radius_all(2)
		box.content_margin_left = 3
		box.content_margin_right = 3
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_contents.add_child(button)
	return button


func _rotate_selected() -> void:
	_grid.rotate_item()
