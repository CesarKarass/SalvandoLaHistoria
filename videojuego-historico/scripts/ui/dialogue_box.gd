class_name DialogueBox
extends CanvasLayer
## Bocadillo de diálogo construido con el asset
## `assets/Accest_Dialago_Prueba1/png/caja_dialogo_512x139.png`.
##
## El asset ya dibuja el marco del retrato (izquierda) y el panel de texto
## (derecha); aquí solo se colocan encima el retrato, el nombre, el texto con
## máquina de escribir, las alternativas y la opción de salida
## "Gracias, nos vemos" (que sustituye a los botones "Continuar" y "Cerrar").
## Todo se dimensiona a partir del ancho de la caja con la proporción
## 512x139 del asset, así que la caja se adapta a cualquier pantalla sin
## deformarse (móvil incluido).
##
## Sin flechas, sin números ni ayuda de teclado: las alternativas se muestran
## solo con su texto (la marcada en rojo y las ya usadas en gris), y
## "Gracias, nos vemos" aparece como una alternativa más al final de la lista
## para salir del cuadro cuando queramos (en las líneas sin alternativas se
## ve en la franja inferior). Tocar cualquier parte de la caja avanza la
## línea. Mantiene la API de siempre (show_line / show_choices /
## hide_choices / open / close y la señal line_typed), así que
## DialogueManager no cambia.

signal line_typed

const RUTA_CAJA := "res://assets/Accest_Dialago_Prueba1/png/caja_dialogo_512x139.png"

## Tamaño natural del asset.
const ANCHO_ASSET := 512.0
const ALTO_ASSET := 139.0

## Regiones medidas sobre el PNG de 512x139 (píxeles del asset):
## marco del retrato (interior), zona del nombre, zona del texto y franja
## inferior para la opción de salida "Gracias, nos vemos".
const MARCO_RETRATO := Rect2(33, 27, 85, 86)
const ZONA_NOMBRE := Rect2(136, 19, 348, 17)
const ZONA_TEXTO := Rect2(136, 37, 348, 70)
const ZONA_PISTA := Rect2(136, 107, 348, 14)

## Colores sobre el panel crema del asset.
const COL_TEXT := Color(0.27, 0.15, 0.10)         # texto marrón
const COL_NOMBRE := Color(0.44, 0.23, 0.13)       # nombre marrón cálido
const COL_SELECTED := Color(0.62, 0.24, 0.10)     # alternativa marcada (rojo)
const COL_USED := Color(0.47, 0.38, 0.34)         # alternativa ya usada (gris)

## Texto de la opción que sale del cuadro de diálogo.
const TEXTO_SALIR := "Gracias, nos vemos"

## Ocupación de la pantalla (la caja casi toca los bordes laterales).
const ANCHO_PANTALLA := 0.94
const ALTO_PANTALLA := 0.46
const MARGEN_ABAJO := 0.045

## Máximo de alternativas mostradas (coincide con quick_1..quick_4).
const MAX_CHOICES := 4

var _typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0
## Velocidad del efecto máquina de escribir (caracteres por segundo).
var _type_speed: float = 60.0

var _bg: Panel
var _textura: TextureRect
var _portrait_frame: Panel
var _portrait: TextureRect
var _name_label: Label
var _text_label: RichTextLabel
## Opción de salida "Gracias, nos vemos" en la franja inferior (abajo a la
## derecha): se ve en las líneas SIN alternativas. Durante la elección la
## opción de salida va como una alternativa más al final de la lista
## (`_choice_labels`). Se coloca DESPUÉS del captador para quedar encima y
## recibir el toque (no avanza el diálogo, lo cierra).
var _salir_label: Label
var _choices_box: VBoxContainer
var _choice_labels: Array[Label] = []
var _choice_texts: Array[String] = []
var _choice_used: Array[bool] = []
var _selected_choice: int = 0
## Captador de toques a pantalla completa (avanzar diálogo); se oculta mientras
## se elige una alternativa para no tapar los clics/touches sobre las opciones.
var _catcher: Control
## Escala actual del asset (1 px de asset = _e px de pantalla).
var _e := 1.0
## Índice (dentro de `_choice_labels`) de la opción de salida cuando se
## muestra una lista: es el último elemento visible, tras las alternativas
## reales. -1 si no hay lista visible.
var _salir_index := -1


func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false
	get_viewport().size_changed.connect(_ajustar_layout)
	_ajustar_layout()


func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_chars = mini(_full_text.length(), _visible_chars + int(_type_speed * delta))
	_text_label.visible_characters = _visible_chars
	if _visible_chars >= _full_text.length():
		_typing = false
		line_typed.emit()


func show_line(speaker: String, portrait: Texture2D, text: String) -> void:
	_name_label.text = speaker
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_portrait_frame.visible = portrait != null
	_full_text = text
	_text_label.text = text
	_text_label.visible = true
	_text_label.visible_characters = 0
	_visible_chars = 0
	_typing = true
	hide_choices()


func is_typing() -> bool:
	return _typing


func complete_line() -> void:
	_visible_chars = _full_text.length()
	_text_label.visible_characters = _visible_chars
	_typing = false


## Muestra las alternativas DENTRO del bocadillo (misma forma siempre):
## se oculta el texto anterior y solo se ven las opciones de respuesta (más
## "Gracias, nos vemos" como última opción para salir), con la opción
## `selected` en rojo y las ya usadas en gris. Sin flechas, sin números ni
## ayuda de teclado: solo el texto de cada alternativa.
func show_choices(texts: Array[String], selected: int, used: Array[bool] = []) -> void:
	_choice_texts = texts.duplicate()
	_choice_used.resize(texts.size())
	_choice_used.fill(false)
	for i: int in mini(texts.size(), used.size()):
		_choice_used[i] = used[i]
	# Se ven las alternativas reales + la opción de salida al final.
	_salir_index = texts.size()
	for i: int in _choice_labels.size():
		_choice_labels[i].visible = i <= _salir_index
	# Solo se ven las alternativas: el texto de la línea anterior se oculta
	# (el bocadillo no cambia de forma ni de tamaño).
	_text_label.visible = false
	_choices_box.visible = true
	_catcher.visible = false
	# La opción de salida ya está en la lista: la de la franja inferior no.
	_salir_label.visible = false
	set_selected_choice(clampi(selected, 0, maxi(texts.size() - 1, 0)))


## Cambia la alternativa marcada (gris = ya usada, rojo = marcada).
func set_selected_choice(index: int) -> void:
	_selected_choice = index
	for i: int in _choice_labels.size():
		if not _choice_labels[i].visible:
			continue
		if i == _salir_index:
			# Opción de salida: como una alternativa más (sin enumeración),
			# siempre en su color para no confundirla con la marcada.
			_choice_labels[i].text = TEXTO_SALIR
			_choice_labels[i].add_theme_color_override("font_color", COL_TEXT)
			continue
		# Sin enumeración: solo el texto de la alternativa; la marcada se
		# distingue por el color (rojo) y las ya usadas en gris.
		_choice_labels[i].text = _choice_texts[i]
		var color := COL_TEXT
		if i < _choice_used.size() and _choice_used[i]:
			color = COL_USED       # opción ya usada → gris
		elif i == _selected_choice:
			color = COL_SELECTED   # opción marcada → rojo
		_choice_labels[i].add_theme_color_override("font_color", color)


func hide_choices() -> void:
	_choices_box.visible = false
	_salir_index = -1
	_catcher.visible = true
	_text_label.visible = true
	# Sin lista: la opción de salida vuelve a la franja inferior.
	_salir_label.visible = true


func open() -> void:
	visible = true


func close() -> void:
	hide_choices()
	visible = false


func _build_ui() -> void:
	# --- Plato: panel transparente con el tamaño exacto de la caja.
	_bg = Panel.new()
	_bg.add_theme_stylebox_override("panel", _transparente())
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# --- El asset de la caja, dibujado a escala sin deformarse.
	_textura = TextureRect.new()
	_textura.texture = load(RUTA_CAJA)
	_textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_textura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(_textura)

	# --- Retrato dentro del marco que ya trae el asset.
	_portrait_frame = Panel.new()
	_portrait_frame.add_theme_stylebox_override("panel", _transparente())
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	# --- Nombre del hablante.
	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", COL_NOMBRE)
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bg.add_child(_name_label)

	# --- Texto de la línea (máquina de escribir).
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.scroll_active = false
	_text_label.fit_content = false
	_text_label.add_theme_color_override("default_color", COL_TEXT)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(_text_label)

	# --- Alternativas: misma zona que el texto (el bocadillo no cambia).
	# MAX_CHOICES reales + 1 para la opción de salida "Gracias, nos vemos"
	# que se muestra como una alternativa más al final de la lista.
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 2)
	_choices_box.visible = false
	_bg.add_child(_choices_box)

	for i: int in MAX_CHOICES + 1:
		var choice_label := Label.new()
		choice_label.add_theme_color_override("font_color", COL_TEXT)
		choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Toca/tap sobre la opción entera (objetivo grande para el dedo).
		choice_label.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_label.gui_input.connect(_on_choice_gui_input.bind(i))
		choice_label.visible = false
		_choices_box.add_child(choice_label)
		_choice_labels.append(choice_label)

	# Captador de toques (encima): tocar en cualquier parte avanza el diálogo.
	_catcher = Control.new()
	_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)

	# --- Opción de salida "Gracias, nos vemos" (franja inferior, abajo a la
	# derecha): sustituye a los botones "Continuar" y "Cerrar" en las líneas
	# sin alternativas. Se añade DESPUÉS del captador, así queda encima y
	# recibe el toque (cerrar en vez de avanzar). Cuando hay alternativas se
	# oculta aquí y aparece como una alternativa más al final de la lista.
	_salir_label = Label.new()
	_salir_label.text = TEXTO_SALIR
	_salir_label.add_theme_color_override("font_color", COL_TEXT)
	_salir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_salir_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_salir_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_salir_label.gui_input.connect(_on_salir_input)
	# Al pasar el ratón se marca en rojo, igual que una alternativa marcada.
	_salir_label.mouse_entered.connect(func() -> void:
		_salir_label.add_theme_color_override("font_color", COL_SELECTED))
	_salir_label.mouse_exited.connect(func() -> void:
		_salir_label.add_theme_color_override("font_color", COL_TEXT))
	add_child(_salir_label)


## Coloca la caja en pantalla y reescala todos sus elementos al tamaño real.
## Se ejecuta al abrir y cada vez que cambia el tamaño de la ventana.
func _ajustar_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return

	# Proporción fija del asset: primero por ancho, recortado por alto.
	var ancho := vp.x * ANCHO_PANTALLA
	var alto := ancho * ALTO_ASSET / ANCHO_ASSET
	var alto_max := vp.y * ALTO_PANTALLA
	if alto > alto_max:
		alto = alto_max
		ancho = alto * ANCHO_ASSET / ALTO_ASSET

	var pos := Vector2(
		roundf((vp.x - ancho) * 0.5),
		roundf(vp.y - alto - vp.y * MARGEN_ABAJO)
	)
	_bg.position = pos
	_bg.size = Vector2(ancho, alto)
	_textura.position = Vector2.ZERO
	_textura.size = Vector2(ancho, alto)

	# Escala del asset -> pantalla (uniforme en los dos ejes).
	var e := ancho / ANCHO_ASSET
	_e = e

	_recolocar(_portrait_frame, MARCO_RETRATO, e)
	_portrait.position = Vector2.ZERO
	_portrait.size = _portrait_frame.size

	_recolocar(_name_label, ZONA_NOMBRE, e)
	_recolocar(_text_label, ZONA_TEXTO, e)
	_recolocar(_choices_box, ZONA_TEXTO, e)

	# Opción de salida de la franja inferior (líneas sin alternativas): al
	# final de la franja, alineada a la derecha (donde estaba "Continuar"),
	# en coordenadas de pantalla porque vive fuera del plato de la caja.
	var f_pista := maxi(10, roundf(e * 10.0))
	var alto_btn := ZONA_PISTA.size.y * e * 1.3
	var ancho_salir := maxf(ZONA_PISTA.size.x * e * 0.6, 150.0 * e)
	_salir_label.position = Vector2(
		_bg.position.x + (ZONA_PISTA.position.x + ZONA_PISTA.size.x) * e - ancho_salir,
		_bg.position.y + ZONA_PISTA.position.y * e - (alto_btn - ZONA_PISTA.size.y * e) * 0.5
	)
	_salir_label.size = Vector2(ancho_salir, alto_btn)

	# Tipografía proporcional a la caja: legible en PC y en móvil.
	var f_nombre := maxi(12, roundf(e * 15.0))
	var f_texto := maxi(11, roundf(e * 13.0))
	var f_opcion := maxi(10, roundf(e * 11.0))

	_name_label.add_theme_font_size_override("font_size", f_nombre)
	_text_label.add_theme_font_size_override("normal_font_size", f_texto)
	_salir_label.add_theme_font_size_override("font_size", f_pista)

	# Cada alternativa es una fila holgada: sirve de objetivo de toque.
	var alto_opcion := maxf(f_opcion * 1.7, vp.y * 0.055)
	for choice_label in _choice_labels:
		choice_label.add_theme_font_size_override("font_size", f_opcion)
		choice_label.custom_minimum_size = Vector2(0.0, alto_opcion)


func _on_catcher_input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		DialogueManager.advance()


## Clic/tap sobre "Gracias, nos vemos": sale del cuadro de diálogo al
## instante, sin esperar a que terminen las líneas pendientes.
func _on_salir_input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		DialogueManager.close_now()


## Clic/tap directo sobre una alternativa: la elige al instante (en escritorio
## y en móvil, sin necesidad de flechas ni teclado). Si se toca la opción de
## salida "Gracias, nos vemos" (la que va al final de la lista), se cierra el
## diálogo en vez de elegir una rama.
func _on_choice_gui_input(event: InputEvent, index: int) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if not pressed:
		return
	if index < _choice_texts.size():
		DialogueManager.choose(index)
	elif index == _salir_index:
		DialogueManager.close_now()


func _recolocar(c: Control, r: Rect2, e: float) -> void:
	c.position = r.position * e
	c.size = r.size * e


func _transparente() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.set_border_width_all(0)
	return sb
