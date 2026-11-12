extends CanvasLayer
## Menú de inicio: título + Jugar / Opciones / Salir.

const OVERWORLD := "res://scenes/overworld/overworld.tscn"
const OPTIONS := "res://scenes/ui/options_menu.tscn"

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	if UISkin.data != null and UISkin.data.menu_background != null:
		var bgtex := TextureRect.new()
		bgtex.texture = UISkin.data.menu_background
		bgtex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bgtex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bgtex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bgtex)

	var center := UISkin.center()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := UISkin.vbox(16)
	center.add_child(col)

	if UISkin.data != null and UISkin.data.logo != null:
		var logo := TextureRect.new()
		logo.texture = UISkin.data.logo
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(256, 128)
		col.add_child(logo)

	col.add_child(UISkin.title("ECOS DEL TIEMPO"))
	col.add_child(UISkin.subtitle("Guardianes de la Historia"))
	col.add_child(UISkin.spacer(24))

	var play := UISkin.primary_button("Jugar")
	play.custom_minimum_size = Vector2(240, 0)
	play.pressed.connect(_on_play)
	col.add_child(play)

	var options := UISkin.button("Opciones")
	options.custom_minimum_size = Vector2(240, 0)
	options.pressed.connect(_on_options)
	col.add_child(options)

	var quit := UISkin.button("Salir")
	quit.custom_minimum_size = Vector2(240, 0)
	quit.pressed.connect(_on_quit)
	col.add_child(quit)

	play.grab_focus()

	var version := UISkin.label("prototipo · v0.1", "SmallLabel")
	version.anchor_left = 1.0
	version.anchor_top = 1.0
	version.anchor_right = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -160.0
	version.offset_top = -30.0
	version.offset_right = -12.0
	version.offset_bottom = -10.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

func _on_play() -> void:
	GameManager.reset_progress()
	Inventory.clear()
	SceneTransition.change_scene(OVERWORLD, "")

func _on_options() -> void:
	var opts_scene: PackedScene = load(OPTIONS)
	if opts_scene != null:
		add_child(opts_scene.instantiate())

func _on_quit() -> void:
	get_tree().quit()
