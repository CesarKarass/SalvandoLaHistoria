extends Node
## Pruebas de recolocación automática al girar y de la ayuda de primera apertura.


func _ready() -> void:
	Inventory.clear()
	var wide := Item.new()
	wide.id = &"giro_3x1"
	wide.grid_size = Vector2i(3, 1)
	assert(Inventory.add_item(wide))
	assert(Inventory.move_item(0, Vector2i(5, 5), Vector2i(3, 1)))
	# En (5,5) no caben las 3 filas del giro; debe encontrar una ubicación cercana.
	assert(Inventory.rotate_item_near(0, Vector2i(5, 5)))
	assert(Inventory.items[0]["size"] == Vector2i(1, 3))
	assert(Inventory.items[0]["position"] == Vector2i(5, 3))
	assert(Inventory.get_item_at(Vector2i(5, 3)) == 0)

	# Si el resto de la cuadrícula está lleno, no se puede girar.
	Inventory.clear()
	assert(Inventory.add_item(wide))
	assert(Inventory.move_item(0, Vector2i(5, 5), Vector2i(3, 1)))
	var one_slot := Item.new()
	one_slot.id = &"relleno"
	one_slot.grid_size = Vector2i.ONE
	for n in range(Inventory.MAX_SLOTS - 3):
		assert(Inventory.add_item(one_slot), "Se deben llenar los espacios restantes")
	var old_position: Vector2i = Inventory.items[0]["position"]
	var old_size: Vector2i = Inventory.items[0]["size"]
	assert(not Inventory.rotate_item_near(0, old_position), "No hay lugar vertical")
	assert(Inventory.items[0]["position"] == old_position)
	assert(Inventory.items[0]["size"] == old_size)

	# La ayuda solo se activa en una instalación en su primera apertura.
	var temporary_save := "user://test_inventario_ayuda.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
	var scene := load("res://scenes/ui/inventory_ui.tscn") as PackedScene
	var ui := scene.instantiate()
	ui.set("tutorial_save_path", temporary_save)
	add_child(ui)
	ui.call("open")
	await get_tree().create_timer(0.75).timeout
	assert(ui.get_node("Overlay/Suitcase/TutorialLayer").visible, "Primera apertura: ayuda visible")
	ui.call("_acknowledge_tutorial")
	assert(not ui.get_node("Overlay/Suitcase/TutorialLayer").visible)
	ui.call("close")
	await get_tree().create_timer(0.65).timeout
	ui.call("open")
	await get_tree().create_timer(0.75).timeout
	assert(not ui.get_node("Overlay/Suitcase/TutorialLayer").visible, "Segunda apertura: no repetir")
	ui.call("close")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
	Inventory.clear()
	print("TEST_INVENTORY_IMPROVEMENTS_OK")
	get_tree().quit()
