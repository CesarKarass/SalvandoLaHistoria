extends Node2D
## Smoke test de Fase 3: transición de escenas (colapso oscuro) + spawn.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_phase3.tscn
##
## El Driver se añade a la raíz del SceneTree para sobrevivir a los cambios de
## escena (change_scene_to_file libera la escena actual, no los nodos de la raíz).

class Driver:
	extends Node

	func run() -> void:
		var results: Array[String] = []

		# 1) Overworld (spawn por defecto)
		await SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "")
		results.append("escena1=" + _current_scene_name())
		results.append("pos1=" + str(_player_pos()))

		# 2) Evento 1 (spawn nombrado)
		await SceneTransition.change_scene("res://scenes/events/event1/event1.tscn", "SpawnDefault")
		results.append("escena2=" + _current_scene_name())
		results.append("pos2=" + str(_player_pos()))

		# 3) Volver al Overworld (spawn desde evento)
		await SceneTransition.change_scene("res://scenes/overworld/overworld.tscn", "SpawnFromEvent1")
		results.append("escena3=" + _current_scene_name())
		results.append("pos3=" + str(_player_pos()))

		for line: String in results:
			print("TEST: ", line)
		print("TEST_DONE")
		get_tree().quit()

	func _current_scene_name() -> String:
		var cs: Node = get_tree().current_scene
		return cs.name if cs != null else "<null>"

	func _player_pos() -> Vector2:
		var p: Node2D = get_tree().get_first_node_in_group("player")
		return p.global_position if p != null else Vector2.ZERO

func _ready() -> void:
	var driver := Driver.new()
	# add_child diferido: durante _ready la raíz aún está configurando sus hijos.
	get_tree().root.call_deferred("add_child", driver)
	driver.run.call_deferred()
