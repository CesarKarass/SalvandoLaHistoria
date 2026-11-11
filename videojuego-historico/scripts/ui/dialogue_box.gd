class_name DialogueBox
extends CanvasLayer
## Bocadillo de diálogo (estilo Stardew Valley): retrato + nombre + texto con
## efecto "máquina de escribir". Estilado por UISkin (fondo, marco de retrato, texto).

signal line_typed

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
	_portrait_frame.visible = portrait != null
	_full_text = text
	_text_label.text = text
	_text_label.visible_characters = 0
	_visible_chars = 0
	_typing = true
	_next_label.visible = false

func is_typing() -> bool:
	return _typing

func complete_line() -> void:
	_visible_chars = _full_text.length()
	_text_label.visible_characters = _visible_chars
	_typing = false
	_next_label.visible = true

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _build_ui() -> void:
	_bg = UISkin.panel("MenuPanel")
	_anchor(_bg, 0.0, 1.0, 1.0, 1.0, 0.0, -150.0, 0.0, 0.0)
	add_child(_bg)

	_portrait_frame = UISkin.panel()
	_portrait_frame.add_theme_stylebox_override("panel", UISkin.portrait_frame())
	_anchor(_portrait_frame, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 116.0, 116.0)
	_bg.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.anchor_left = 0.0
	_portrait.anchor_top = 0.0
	_portrait.anchor_right = 1.0
	_portrait.anchor_bottom = 1.0
	_portrait.offset_left = 4.0
	_portrait.offset_top = 4.0
	_portrait.offset_right = -4.0
	_portrait.offset_bottom = -4.0
	_portrait_frame.add_child(_portrait)

	_name_label = UISkin.label("", "DialogueName")
	_anchor(_name_label, 0.0, 0.0, 1.0, 0.0, 132.0, 14.0, -24.0, 40.0)
	_bg.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.scroll_active = false
	_text_label.fit_content = false
	_text_label.add_theme_font_size_override("normal_font_size", 16)
	_text_label.add_theme_color_override("default_color", UISkin.data.text_color)
	_anchor(_text_label, 0.0, 0.0, 1.0, 1.0, 132.0, 42.0, -24.0, -34.0)
	_bg.add_child(_text_label)

	_next_label = UISkin.label("▼", "BodyLabel")
	_anchor(_next_label, 1.0, 1.0, 1.0, 1.0, -40.0, -32.0, -16.0, -8.0)
	_next_label.visible = false
	_bg.add_child(_next_label)

func _anchor(c: Control, al: float, at: float, ar: float, ab: float, ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob
