extends Node
## UISkin — carga el recurso de skin y construye un Theme de Godot.
## Expone fábricas que ya aplican el tema + variaciones de tipo, para estilizar
## toda la UI desde un único recurso (resources/ui/ui_skin.tres).

const SKIN_PATH := "res://resources/ui/ui_skin.tres"

var data: UISkinData
var _theme: Theme

func _ready() -> void:
	data = load(SKIN_PATH) as UISkinData
	if data == null:
		data = UISkinData.new()
	_theme = _build_theme()

func theme() -> Theme:
	return _theme

func panel(variant: String = "MenuPanel") -> Panel:
	var p := Panel.new()
	p.theme = _theme
	p.theme_type_variation = variant
	return p

func panel_container(variant: String = "MenuPanel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = _theme
	p.theme_type_variation = variant
	return p

func button(text: String, variant: String = "MenuButton") -> Button:
	var b := Button.new()
	b.text = text
	b.theme = _theme
	b.theme_type_variation = variant
	return b

func primary_button(text: String) -> Button:
	return button(text, "PrimaryButton")

func title(text: String) -> Label:
	return label(text, "TitleLabel")

func subtitle(text: String) -> Label:
	return label(text, "SubtitleLabel")

func label(text: String, variant: String = "BodyLabel") -> Label:
	var l := Label.new()
	l.text = text
	l.theme = _theme
	l.theme_type_variation = variant
	return l

func vbox(separation: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v

func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h

func center() -> CenterContainer:
	return CenterContainer.new()

func spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

func portrait_frame() -> StyleBox:
	return _box(data.portrait_frame, Color(0.05, 0.05, 0.06, 0.6), 4, 4, 1, data.panel_border)

func _build_theme() -> Theme:
	var t := Theme.new()
	if data.font != null:
		t.default_font = data.font
	# Paneles
	t.set_stylebox("panel", "Panel", _box(data.panel_bg, data.panel_color, data.panel_margin, data.corner_radius, data.border_width, data.panel_border))
	t.set_stylebox("panel", "MenuPanel", _box(data.panel_bg, data.panel_color, data.panel_margin, data.corner_radius, data.border_width, data.panel_border))
	# Botones
	t.set_stylebox("normal", "Button", _box(data.button_normal, data.button_color, data.button_margin, data.corner_radius, data.border_width, data.panel_border))
	t.set_stylebox("hover", "Button", _box(data.button_hover, data.button_hover_color, data.button_margin, data.corner_radius, data.border_width, data.accent))
	t.set_stylebox("pressed", "Button", _box(data.button_pressed, data.button_pressed_color, data.button_margin, data.corner_radius, data.border_width, data.panel_border))
	t.set_stylebox("disabled", "Button", _box(data.button_disabled, Color(0.3, 0.3, 0.3, 0.5), data.button_margin, data.corner_radius, data.border_width, data.muted))
	t.set_stylebox("focus", "Button", _box(null, Color(0, 0, 0, 0), 0, data.corner_radius, 1, data.accent))
	t.set_color("font_color", "Button", data.text_color)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", data.accent)
	# Botón primario (acento dorado)
	t.set_stylebox("normal", "PrimaryButton", _box(data.button_normal, data.accent, data.button_margin, data.corner_radius, data.border_width, data.panel_border))
	t.set_stylebox("hover", "PrimaryButton", _box(data.button_hover, data.accent.lightened(0.15), data.button_margin, data.corner_radius, data.border_width, Color(1, 1, 1)))
	t.set_stylebox("pressed", "PrimaryButton", _box(data.button_pressed, data.accent.darkened(0.3), data.button_margin, data.corner_radius, data.border_width, data.panel_border))
	t.set_color("font_color", "PrimaryButton", Color(0.12, 0.1, 0.08))
	# Labels base + variaciones
	t.set_color("font_color", "Label", data.text_color)
	t.set_font_size("font_size", "Label", 18)
	_register_label(t, "TitleLabel", data.accent, 48)
	_register_label(t, "SubtitleLabel", data.muted, 22)
	_register_label(t, "BodyLabel", data.text_color, 18)
	_register_label(t, "SmallLabel", data.muted, 14)
	_register_label(t, "HudLabel", data.accent, 26)
	_register_label(t, "DialogueName", data.accent, 18)
	_register_label(t, "DialogueText", data.text_color, 16)
	# Slots de inventario
	t.set_stylebox("panel", "Slot", _box(data.slot_bg, Color(0.12, 0.11, 0.09, 0.9), 4, 4, 1, data.muted))
	t.set_stylebox("panel", "SlotSelected", _box(data.slot_selected, Color(0.2, 0.16, 0.1, 0.95), 4, 4, 2, data.accent))
	return t

func _register_label(t: Theme, type: String, color: Color, size: int) -> void:
	t.set_color("font_color", type, color)
	t.set_font_size("font_size", type, size)

func _box(tex: Texture2D, color: Color, margin: int, radius: int, border: int, border_color: Color) -> StyleBox:
	if tex != null:
		return _tex(tex, margin)
	return _flat(color, margin, radius, border, border_color)

func _tex(tex: Texture2D, margin: int) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = tex
	st.texture_margin_left = margin
	st.texture_margin_top = margin
	st.texture_margin_right = margin
	st.texture_margin_bottom = margin
	return st

func _flat(color: Color, margin: int, radius: int, border: int, border_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = border_color
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_top = margin
	sb.content_margin_right = margin
	sb.content_margin_bottom = margin
	return sb
