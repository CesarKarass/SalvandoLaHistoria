class_name PauseMenu
extends CanvasLayer
## Menú de pausa: se abre/cierra con Esc y pausa el árbol.
## Al abrir Opciones, oculta su propio contenido para que no se solapen.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const OPTIONS := "res://scenes/ui/options_menu.tscn"

## Estilo del menú del juego: plato oscuro + borde dorado + viñetas doradas
## (los mismos assets de resources/menuv0.2 que usa el menú principal).
const COL_ORO := Color(0.788, 0.635, 0.29)
const COL_PLATO := Color(0.06, 0.03, 0.02, 0.86)
const COL_BOTON := Color(0.12, 0.07, 0.04, 0.95)
const COL_BOTON_HOVER := Color(0.17, 0.11, 0.06, 0.95)
const COL_BOTON_PULSADO := Color(0.08, 0.05, 0.03, 0.95)
const COL_BOTON_BORDE := Color(0.55, 0.36, 0.20)
const COL_TEXTO := Color(0.93, 0.86, 0.70)
const COL_TEXTO_ENF := Color(1.0, 0.95, 0.80)
const RUTA_VIN_IZQ := "res://resources/menuv0.2/png/vineta_amarilla_izq.png"
const RUTA_VIN_DER := "res://resources/menuv0.2/png/vineta_amarilla_der.png"

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
	# Si el diálogo acaba de cerrarse con Esc, no abrimos pausa en ese frame.
	if DialogueManager.cancel_consumado_frame == Engine.get_process_frames():
		return
	if not visible:
		# Con el diálogo abierto, Esc lo cierra (lo hace DialogueManager):
		# aquí no abrimos nada para no solapar los dos menús.
		if DialogueManager.state != DialogueManager.State.IDLE:
			return
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
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(dim)

	# Misma viñeta radial del menú principal: bordes oscuros, centro cálido.
	_content.add_child(_crear_vigneta())

	var center := UISkin.center()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(center)

	# Plato centrado: plato oscuro con borde dorado (lenguaje del menú).
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_plato())
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)

	var col := UISkin.vbox(10)
	panel.add_child(col)

	var title := UISkin.title("Pausa")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var linea := ColorRect.new()
	linea.color = COL_ORO
	linea.custom_minimum_size = Vector2(160, 2)
	linea.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(linea)

	col.add_child(UISkin.spacer(6))

	var resume := _boton_menu(col, "Continuar")
	resume.pressed.connect(close)

	var options := _boton_menu(col, "Opciones")
	options.pressed.connect(_open_options)

	var menu := _boton_menu(col, "Menú principal")
	menu.pressed.connect(_to_main_menu)

	resume.grab_focus()


## Botón con el aspecto del menú del juego: plato oscuro, borde dorado y
## viñetas doradas a los lados cuando se enfoca (ratón o teclado), igual que
## los botones del menú principal. Devuelve el Button (la fila se añade al
## contenedor `padre`).
func _boton_menu(padre: Control, texto: String) -> Button:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	padre.add_child(fila)

	var vin_izq := _vineta(RUTA_VIN_IZQ, Rect2(0, 0, 12, 24))
	fila.add_child(vin_izq)

	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(240, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", _estilo_boton(COL_BOTON, COL_BOTON_BORDE))
	b.add_theme_stylebox_override("hover", _estilo_boton(COL_BOTON_HOVER, COL_ORO))
	b.add_theme_stylebox_override("pressed", _estilo_boton(COL_BOTON_PULSADO, COL_ORO))
	b.add_theme_stylebox_override("focus", _estilo_boton(Color(0, 0, 0, 0), COL_ORO))
	b.add_theme_color_override("font_color", COL_TEXTO)
	b.add_theme_color_override("font_hover_color", COL_TEXTO_ENF)
	b.add_theme_color_override("font_pressed_color", COL_ORO)
	b.add_theme_color_override("font_focus_color", COL_TEXTO_ENF)
	fila.add_child(b)

	var vin_der := _vineta(RUTA_VIN_DER, Rect2(48, 0, 12, 24))
	fila.add_child(vin_der)

	# Las viñetas se ven mientras el botón tenga el foco o el ratón encima
	# (reservan su espacio, así el botón no salta al enfocarse).
	var actualizar := func() -> void:
		var ven := b.has_focus() or b.is_hovered()
		vin_izq.self_modulate.a = 1.0 if ven else 0.0
		vin_der.self_modulate.a = 1.0 if ven else 0.0
	b.focus_entered.connect(actualizar)
	b.focus_exited.connect(actualizar)
	b.mouse_entered.connect(actualizar)
	b.mouse_exited.connect(actualizar)
	return b


## Viñeta dorada (flecha del menú) recortada a su triángulo, invisible hasta
## que el botón se enfoca.
func _vineta(ruta: String, region: Rect2) -> TextureRect:
	var t := TextureRect.new()
	var recorte := AtlasTexture.new()
	recorte.atlas = load(ruta)
	recorte.region = region
	t.texture = recorte
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(12, 24)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.self_modulate.a = 0.0
	return t


## Plato del panel: oscuro con borde dorado, como el resto del juego.
func _estilo_plato() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PLATO
	sb.border_color = COL_ORO
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 24
	sb.content_margin_bottom = 26
	return sb


## Plato de los botones de la pausa.
func _estilo_boton(bg: Color, borde: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = borde
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


## Viñeta radial suave (bordes oscuros), igual que la del menú principal.
func _crear_vigneta() -> TextureRect:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gradiente.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.10),
		Color(0.0, 0.0, 0.0, 0.55),
	])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 512
	textura.height = 512
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(0.5, 0.0)
	var v := TextureRect.new()
	v.texture = textura
	v.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

func open() -> void:
	# Nada de input fantasma durante la pausa: si se abrió con el joystick o
	# un botón todavía pulsados (el release no llega con el árbol pausado),
	# los soltamos aquí mismo.
	TouchControls.liberar_entrada()
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
