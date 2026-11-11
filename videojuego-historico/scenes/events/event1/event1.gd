class_name Event1
extends EventBase
## Evento 1: "El Duelo en la Plaza de Dolores" (1810).
## Victoria: interactuar con el objetivo "Antagonista" llevando seleccionado
## el ítem correcto (bolsa_monedas o mapa) antes de que acabe el tiempo.

@export var win_item_ids: Array[String] = ["bolsa_monedas", "mapa"]

func _ready() -> void:
	super._ready()
	var target := get_node_or_null("Antagonista") as InteractTarget
	if target != null:
		target.activated.connect(_on_target_activated)

func _on_target_activated() -> void:
	var selected: Item = Inventory.get_selected()
	if selected == null:
		_show_no_item()
		return
	var selected_id: String = String(selected.id)
	if selected_id in win_item_ids:
		win()
	else:
		_show_no_item()

func _show_no_item() -> void:
	if _hud != null:
		_hud.show_result("Necesitas seleccionar el ítem correcto (bolsa_monedas o mapa).")

func _on_win() -> void:
	GameManager.set_flag("is_hidalgo_saved", true)
	if _hud != null:
		_hud.show_result("¡Victoria! Hidalgo está a salvo.")
	_set_player_movable(false)
	await get_tree().create_timer(1.2).timeout
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "SpawnFromEvent1")

func _on_lose() -> void:
	GameManager.set_flag("is_hidalgo_saved", false)
	if _hud != null:
		_hud.show_result("Derrota... el tiempo se agotó.")
	_set_player_movable(false)
	await get_tree().create_timer(1.5).timeout
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "SpawnFromEvent1")
