extends CanvasLayer
## Menú de inicio: fondo + logo + botones Jugar / Opciones / Salir.
## Toda la UI vive en la escena (main_menu.tscn) construida con los assets de
## res://resources/Menu (fondo, titulo y botones en PNG, todos editables en el
## editor); aquí solo se conectan las acciones de los botones.

const OVERWORLD := "res://scenes/overworld/overworld.tscn"
const OPTIONS := "res://scenes/ui/options_menu.tscn"

@onready var _btn_jugar: TextureButton = $Botones/BtnJugar

func _ready() -> void:
	_btn_jugar.grab_focus()

func _on_play() -> void:
	GameManager.reset_progress()
	Inventory.clear()
	SceneTransition.change_scene(OVERWORLD, "")

func _on_options() -> void:
	var opts_scene: PackedScene = load(OPTIONS)
	if opts_scene != null:
		add_child(opts_scene.instantiate())

func _on_quit() -> void:
	get_tree().quit()
