class_name TouchControls
extends CanvasLayer
## Controles táctiles (juego): joystick + botones Interactuar / Inventario / Pausa.
## Emiten las mismas acciones que el teclado, así la lógica existente no cambia.
## Se oculta en escritorio salvo force_visible (para probar con ratón).

@export var force_visible: bool = true

func _ready() -> void:
	layer = 10
	visible = force_visible or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_build()

func _build() -> void:
	# Zona táctil del joystick flotante: mitad izquierda de la pantalla.
	var joystick := FloatingJoystick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_top = 0.0
	joystick.anchor_right = 0.5
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0.0
	joystick.offset_top = 0.0
	joystick.offset_right = 0.0
	joystick.offset_bottom = 0.0
	add_child(joystick)

	var interact := _make_button("E", "interact")
	interact.anchor_left = 1.0
	interact.anchor_top = 1.0
	interact.anchor_right = 1.0
	interact.anchor_bottom = 1.0
	interact.offset_left = -150.0
	interact.offset_top = -150.0
	interact.offset_right = -40.0
	interact.offset_bottom = -40.0
	add_child(interact)

	var inventory := _make_button("Inv", "inventory")
	inventory.anchor_left = 1.0
	inventory.anchor_top = 1.0
	inventory.anchor_right = 1.0
	inventory.anchor_bottom = 1.0
	inventory.offset_left = -264.0
	inventory.offset_top = -130.0
	inventory.offset_right = -172.0
	inventory.offset_bottom = -38.0
	add_child(inventory)

	var pause := _make_button("II", "")
	pause.tapped.connect(_toggle_pause)
	pause.anchor_left = 1.0
	pause.anchor_top = 1.0
	pause.anchor_right = 1.0
	pause.anchor_bottom = 1.0
	pause.offset_left = -142.0
	pause.offset_top = -248.0
	pause.offset_right = -60.0
	pause.offset_bottom = -166.0
	add_child(pause)

## La pausa se llama directamente (no vía acción) para evitar estados pegados
## cuando el árbol se pausa y no llega el evento de liberación.
func _toggle_pause() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var pm := parent.get_node_or_null("PauseMenu") as PauseMenu
	if pm != null:
		pm.toggle()

func _make_button(text: String, action: String) -> TouchButton:
	var b := TouchButton.new()
	b.label = text
	b.action = action
	return b
