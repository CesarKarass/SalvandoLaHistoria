class_name DialogueBox
extends CanvasLayer
## Bocadillo de diálogo (estilo Stardew Valley): retrato + nombre + texto con
## efecto de "máquina de escribir". Construye su UI en _ready (placeholder);
## cuando haya arte/UI definitiva se puede sustituir por una escena .tscn visual.

signal line_typed

var _typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0

## Velocidad del efecto máquina de escribir (caracteres por segundo).
var _type_speed: float = 60.0

var _bg: ColorRect
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
	_portrait.visible = portrait != null
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
	_bg = ColorRect.new()
	_bg.color = Color(0.04, 0.04, 0.07, 0.92)
	_anchor(_bg, 0.0, 1.0, 1.0, 1.0, 0.0, -150.0, 0.0, 0.0)
	add_child(_bg)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anchor(_portrait, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 116.0, 116.0)
	_bg.add_child(_portrait)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_anchor(_name_label, 0.0, 0.0, 1.0, 0.0, 132.0, 14.0, -24.0, 40.0)
	_bg.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.scroll_active = false
	_text_label.fit_content = false
	_text_label.add_theme_font_size_override("normal_font_size", 16)
	_text_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.92))
	_anchor(_text_label, 0.0, 0.0, 1.0, 1.0, 132.0, 42.0, -24.0, -34.0)
	_bg.add_child(_text_label)

	_next_label = Label.new()
	_next_label.text = "▼"
	_next_label.add_theme_font_size_override("font_size", 16)
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
