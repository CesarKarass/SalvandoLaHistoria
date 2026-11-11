class_name DialogueBox
extends CanvasLayer
## Bocadillo de diálogo estilo "avatar box" de la muestra: panel de color
## durazno con borde marrón oscuro, gemas azules en las cuatro esquinas,
## retrato enmarcado del personaje a la izquierda y texto marrón a la
## derecha. Construye su UI en _ready y mantiene SIEMPRE la misma forma,
## con o sin alternativas de respuesta. Incorpora captador de toques para
## avanzar el diálogo en móvil (controles táctiles de upstream).

signal line_typed

## Colores del estilo de la muestra.
const COL_BG := Color(0.965, 0.815, 0.69)       # relleno durazno
const COL_BORDER := Color(0.31, 0.17, 0.12)     # borde marrón oscuro
const COL_TEXT := Color(0.27, 0.15, 0.10)       # texto marrón
const COL_NAME := Color(0.44, 0.23, 0.13)       # nombre marrón cálido
const COL_GEM := Color(0.42, 0.76, 0.93)        # gemas azules de las esquinas
const COL_SELECTED := Color(0.78, 0.30, 0.10)   # alternativa resaltada
const COL_USED := Color(0.58, 0.47, 0.42)       # alternativa ya usada (gris)
const COL_HINT := Color(0.50, 0.36, 0.28)       # ayuda
const COL_FRAME := Color(0.99, 0.94, 0.88)      # fondo del marco del retrato

var _typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0
## Velocidad del efecto máquina de escribir (caracteres por segundo).
var _type_speed: float = 60.0

var _bg: Panel
var _portrait_frame: Panel
var _portrait: TextureRect
var _name_label: Label
var _text_label: RichTextLabel
var _next_label: Label
var _choices_box: VBoxContainer
var _choice_labels: Array[Label] = []
var _choice_texts: Array[String] = []
var _choice_used: Array[bool] = []
var _hint_label: Label
var _selected_choice: int = 0
## Captador de toques a pantalla completa (avanzar diálogo); se oculta mientras
## se elige una alternativa para no tapar los clics/touches sobre las opciones.
var _catcher: Control

## Máximo de alternativas mostradas (coincide con quick_1..quick_4).
const MAX_CHOICES := 4
## Altura del bocadillo: siempre la misma, con o sin alternativas.
const BOX_HEIGHT := -150.0

func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false

func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_chars = mini(_full_text.length(), _visible_chars + int(_type_speed * delta))
	_text_label.visible_characters = _visible_chars
	if _visible_chars >= _full_text.length():
		_typing = false
		_next_label.visible = true
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
	_next_label.visible = false
	hide_choices()

func is_typing() -> bool:
	return _typing

func complete_line() -> void:
	_visible_chars = _full_text.length()
	_text_label.visible_characters = _visible_chars
	_typing = false
	_next_label.visible = true

## Muestra las alternativas DENTRO del bocadillo (misma forma siempre):
## se oculta el texto anterior y solo se ven las opciones de respuesta,
## con la opción `selected` resaltada con "▸" y las ya usadas en gris.
func show_choices(texts: Array[String], selected: int, used: Array[bool] = []) -> void:
	_choice_texts = texts.duplicate()
	_choice_used.resize(texts.size())
	_choice_used.fill(false)
	for i: int in mini(texts.size(), used.size()):
		_choice_used[i] = used[i]
	for i: int in _choice_labels.size():
		_choice_labels[i].visible = i < texts.size()
	_hint_label.text = "↑ ↓ / W S: mover   ·   Enter / E: elegir   ·   1-" \
		+ str(texts.size()) + ": elegir directo"
	# Solo se ven las alternativas: el texto de la línea anterior se oculta
	# (el bocadillo no cambia de forma ni de tamaño).
	_text_label.visible = false
	_next_label.visible = false
	_choices_box.visible = true
	_catcher.visible = false
	set_selected_choice(clampi(selected, 0, maxi(texts.size() - 1, 0)))

## Cambia la alternativa resaltada (gris = ya usada, rojo = resaltada).
func set_selected_choice(index: int) -> void:
	_selected_choice = index
	for i: int in _choice_labels.size():
		if not _choice_labels[i].visible:
			continue
		var marker: String = "▸ " if i == _selected_choice else "   "
		_choice_labels[i].text = marker + str(i + 1) + ". " + _choice_texts[i]
		var color := COL_TEXT
		if i < _choice_used.size() and _choice_used[i]:
			color = COL_USED     # opción ya usada → gris
		elif i == _selected_choice:
			color = COL_SELECTED  # opción resaltada → rojo quemado
		_choice_labels[i].add_theme_color_override("font_color", color)

func hide_choices() -> void:
	_choices_box.visible = false
	_catcher.visible = true
	_text_label.visible = true

func open() -> void:
	visible = true

func close() -> void:
	hide_choices()
	visible = false

func _build_ui() -> void:
	# --- Cuadro principal: relleno durazno, borde marrón, esquinas redondeadas.
	_bg = Panel.new()
	_anchor(_bg, 0.0, 1.0, 1.0, 1.0, 0.0, BOX_HEIGHT, 0.0, 0.0)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COL_BG
	bg_style.border_color = COL_BORDER
	bg_style.set_border_width_all(6)
	bg_style.set_corner_radius_all(10)
	_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(_bg)

	# --- Retrato del personaje enmarcado (izquierda, más grande y detallado).
	_portrait_frame = Panel.new()
	_anchor(_portrait_frame, 0.0, 0.0, 0.0, 0.0, 14.0, 14.0, 134.0, 134.0)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = COL_FRAME
	frame_style.border_color = COL_BORDER
	frame_style.set_border_width_all(4)
	frame_style.set_corner_radius_all(6)
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	_bg.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anchor(_portrait, 0.0, 0.0, 1.0, 1.0, 8.0, 8.0, -8.0, -8.0)
	_portrait_frame.add_child(_portrait)

	# --- Gemas azules (rombos) en las cuatro esquinas del cuadro.
	_add_gem(0.0, 0.0, 2.0, 2.0, 12.0, 12.0)
	_add_gem(1.0, 0.0, -12.0, 2.0, -2.0, 12.0)
	_add_gem(0.0, 1.0, 2.0, -12.0, 12.0, -2.0)
	_add_gem(1.0, 1.0, -12.0, -12.0, -2.0, -2.0)

	# --- Nombre del hablante.
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", COL_NAME)
	_anchor(_name_label, 0.0, 0.0, 1.0, 0.0, 146.0, 12.0, -24.0, 38.0)
	_bg.add_child(_name_label)

	# --- Texto de la línea (máquina de escribir).
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.scroll_active = false
	_text_label.fit_content = false
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	_text_label.add_theme_color_override("default_color", COL_TEXT)
	_anchor(_text_label, 0.0, 0.0, 1.0, 1.0, 146.0, 42.0, -24.0, -30.0)
	_bg.add_child(_text_label)

	# --- Indicador "continuar" abajo a la derecha (estilo de la muestra).
	_next_label = Label.new()
	_next_label.text = "[Enter] Continuar ▸"
	_next_label.add_theme_font_size_override("font_size", 14)
	_next_label.add_theme_color_override("font_color", COL_NAME)
	_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_anchor(_next_label, 1.0, 1.0, 1.0, 1.0, -240.0, -28.0, -16.0, -6.0)
	_next_label.visible = false
	_bg.add_child(_next_label)

	# --- Alternativas: misma zona que el texto (el cuadro no cambia).
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 3)
	_anchor(_choices_box, 0.0, 0.0, 1.0, 1.0, 146.0, 42.0, -24.0, -24.0)
	_choices_box.visible = false
	_bg.add_child(_choices_box)

	for i: int in MAX_CHOICES:
		var choice_label := Label.new()
		choice_label.add_theme_font_size_override("font_size", 16)
		choice_label.add_theme_color_override("font_color", COL_TEXT)
		choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_label.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_label.gui_input.connect(_on_choice_gui_input.bind(i))
		choice_label.visible = false
		_choices_box.add_child(choice_label)
		_choice_labels.append(choice_label)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", COL_HINT)
	_choices_box.add_child(_hint_label)

	# Captador de toques (encima): tocar en cualquier parte avanza el diálogo.
	_catcher = Control.new()
	_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)

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

## Clic/tap directo sobre una alternativa: la elige al instante (en escritorio
## y en móvil, sin necesidad de flechas ni teclado).
func _on_choice_gui_input(event: InputEvent, index: int) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed and index < _choice_texts.size():
		DialogueManager.choose(index)

## Gema azul (rombo girado45°) en una esquina del cuadro.
func _add_gem(al: float, at: float, ol: float, ot: float, orr: float, ob: float) -> void:
	var gem := ColorRect.new()
	_anchor(gem, al, at, al, at, ol, ot, orr, ob)
	gem.color = COL_GEM
	gem.pivot_offset = Vector2(5, 5)
	gem.rotation_degrees = 45.0
	_bg.add_child(gem)

func _anchor(c: Control, al: float, at: float, ar: float, ab: float, ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob
