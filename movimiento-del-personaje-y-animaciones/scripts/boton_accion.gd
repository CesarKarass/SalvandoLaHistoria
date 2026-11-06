extends Button
## Botón táctil (móvil) que dispara una acción del Input Map.
## Solo ponle la acción en el inspector: `esquivar`, `interactuar`, `correr`...
## Así el juego no distingue entre teclado, mando y dedo.

@export var accion: StringName = &""


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE        # que Espacio no "pique" el botón por foco
	if accion == &"":
		return
	button_down.connect(_al_pulsar)
	button_up.connect(_al_soltar)


func _al_pulsar() -> void:
	Input.action_press(accion, 1.0)


func _al_soltar() -> void:
	Input.action_release(accion)
