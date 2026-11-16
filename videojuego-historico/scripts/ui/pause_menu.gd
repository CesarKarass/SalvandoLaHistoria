class_name PauseMenu
extends CanvasLayer
## Menú de pausa: se abre/cierra con Esc y pausa el árbol.
## Al abrir Opciones, oculta su propio contenido para que no se solapen.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const OPTIONS := "res://scenes/ui/options_menu.tscn"

var _options_node: OptionsMenu = null
var _content: Control

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("cancel"):
		return
	if not visible:
		# Esc cierra primero la mochila, sin abrir dos menús a la vez.
		var inventory_ui := get_parent().get_node_or_null("InventoryUI")
		if inventory_ui != null and inventory_ui.has_method("is_open") and inventory_ui.call("is_open"):
			inventory_ui.call("close")
			return
		open()
	elif _options_node != null:
		_close_options()
	else:
		close()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _build() -> void:
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(dim)

	var center := UISkin.center()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(center)

	var panel := UISkin.panel_container("MenuPanel")
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var col := UISkin.vbox(12)
	panel.add_child(col)

	col.add_child(UISkin.title("Pausa"))
	col.add_child(UISkin.spacer(8))

	var resume := UISkin.primary_button("Continuar")
	resume.custom_minimum_size = Vector2(240, 0)
	resume.pressed.connect(close)
	col.add_child(resume)

	var options := UISkin.button("Opciones")
	options.custom_minimum_size = Vector2(240, 0)
	options.pressed.connect(_open_options)
	col.add_child(options)

	var menu := UISkin.button("Menú principal")
	menu.custom_minimum_size = Vector2(240, 0)
	menu.pressed.connect(_to_main_menu)
	col.add_child(menu)

	resume.grab_focus()

func open() -> void:
	visible = true
	_content.visible = true
	get_tree().paused = true

func close() -> void:
	_close_options()
	visible = false
	get_tree().paused = false

func _open_options() -> void:
	if _options_node != null:
		return
	var opts_scene: PackedScene = load(OPTIONS)
	if opts_scene == null:
		return
	_options_node = opts_scene.instantiate() as OptionsMenu
	_options_node.closed.connect(_on_options_closed)
	_content.visible = false
	add_child(_options_node)

func _close_options() -> void:
	if _options_node != null:
		_options_node.queue_free()
		_options_node = null
	if _content != null:
		_content.visible = true

func _on_options_closed() -> void:
	_options_node = null
	if _content != null:
		_content.visible = true

func _to_main_menu() -> void:
	close()
	SceneTransition.change_scene(MAIN_MENU, "")
