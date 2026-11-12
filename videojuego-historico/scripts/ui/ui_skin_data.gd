class_name UISkinData
extends Resource
## Datos de skin de la interfaz. Las texturas son opcionales: si están en null,
## UISkin genera placeholders (StyleBoxFlat). Para re-skinear, rellena los slots
## de textura en resources/ui/ui_skin.tres (y opcionalmente la fuente).

@export var font: Font
@export var menu_background: Texture2D
@export var logo: Texture2D

@export var panel_bg: Texture2D
@export var panel_margin: int = 12

@export var button_normal: Texture2D
@export var button_hover: Texture2D
@export var button_pressed: Texture2D
@export var button_disabled: Texture2D
@export var button_margin: int = 10

@export var slot_bg: Texture2D
@export var slot_selected: Texture2D
@export var portrait_frame: Texture2D

# Colores/medidas de los placeholders (cuando la textura es null).
@export var panel_color: Color = Color(0.08, 0.07, 0.06, 0.96)
@export var panel_border: Color = Color(0.55, 0.42, 0.22)
@export var button_color: Color = Color(0.5, 0.3, 0.16)
@export var button_hover_color: Color = Color(0.66, 0.42, 0.22)
@export var button_pressed_color: Color = Color(0.38, 0.22, 0.11)
@export var accent: Color = Color(1.0, 0.85, 0.4)
@export var text_color: Color = Color(0.95, 0.92, 0.85)
@export var muted: Color = Color(0.72, 0.66, 0.58)
@export var corner_radius: int = 6
@export var border_width: int = 2
