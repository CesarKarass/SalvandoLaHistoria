extends Node
## SceneTransition — transición de escenas con efecto de colapso oscuro (autoload).
## change_scene(path, spawn_id): cierra el iris → cambia la escena → abre el iris.

signal transition_finished

var _layer: TransitionLayer
var _in_progress: bool = false

func _ready() -> void:
	var scene := load("res://scenes/ui/transition_layer.tscn") as PackedScene
	_layer = scene.instantiate() as TransitionLayer
	add_child(_layer)

## Cambia de escena con el efecto de transición. Guarda el spawn pendiente.
func change_scene(path: String, spawn_id: String = "") -> void:
	if _in_progress:
		return
	_in_progress = true
	GameManager.pending_spawn = spawn_id
	# Estado limpio al salir: sin pausa, sin diálogo abierto (se solaparía con
	# la interfaz de inicio) y sin acciones táctiles pegadas (el personaje del
	# siguiente nivel no debe arrancar caminando solo).
	get_tree().paused = false
	DialogueManager.close_now()
	TouchControls.liberar_entrada()
	await _layer.collapse()
	get_tree().change_scene_to_file(path)
	# La escena que entra arranca limpia por si acaso.
	get_tree().paused = false
	TouchControls.liberar_entrada()
	await _layer.expand()
	_in_progress = false
	transition_finished.emit()
