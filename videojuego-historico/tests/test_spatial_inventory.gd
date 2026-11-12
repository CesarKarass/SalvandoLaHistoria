extends Node
## Pruebas de regresión de la cuadrícula y API original.
## Ejecutar con Godot 4.7+: godot --headless --path . res://tests/test_spatial_inventory.tscn

func _ready() -> void:
	Inventory.clear()

	var large := Item.new()
	large.id = &"grande"
	large.display_name = "Objeto de prueba 2x2"
	large.grid_size = Vector2i(2, 2)
	assert(Inventory.add_item(large), "Agregar objeto 2x2")
	assert(Inventory.get_item_at(Vector2i(1, 1)) == 0, "Ocupa cuatro celdas")
	assert(Inventory.get_item_at(Vector2i(2, 2)) == -1, "No invade otras celdas")

	var long_item := Item.new()
	long_item.id = &"largo"
	long_item.display_name = "Objeto de prueba 3x1"
	long_item.grid_size = Vector2i(3, 1)
	assert(Inventory.add_item(long_item), "Agregar objeto 3x1")
	var original_pos: Vector2i = Inventory.items[1]["position"]
	assert(not Inventory.move_item(1, Vector2i(0, 0), long_item.grid_size), "Rechazar solapamiento")
	assert(Inventory.items[1]["position"] == original_pos, "Conservar posicion invalida")
	assert(Inventory.move_item(1, Vector2i(3, 3), Vector2i(1, 3)), "Mover y rotar")
	assert(Inventory.get_item_at(Vector2i(3, 5)) == 1, "Rotacion ocupa tres filas")
	Inventory.select(1)
	assert(Inventory.get_selected() == long_item, "API de seleccion del Evento 1")

	var pile := Item.new()
	pile.id = &"municion"
	pile.stackable = true
	pile.max_stack = 3
	assert(Inventory.add_item(pile, 7), "Crear tres pilas sin perder cantidades")
	assert(Inventory.count(&"municion") == 7, "Conteo de pilas")
	assert(Inventory.remove_item(&"municion", 5), "Consumir varias pilas")
	assert(Inventory.count(&"municion") == 2, "Cantidad restante")
	assert(not Inventory.remove_item(&"municion", 3), "No consumir parcialmente si falta")
	assert(Inventory.count(&"municion") == 2, "Sin efectos parciales")

	var impossible := Item.new()
	impossible.id = &"imposible"
	impossible.grid_size = Vector2i(9, 1)
	assert(not Inventory.add_item(impossible), "No cabe ancho 9")
	assert(not Inventory.has_item(&"imposible"), "Sin perdida de consistencia")

	var ui := (load("res://scenes/ui/inventory_ui.tscn") as PackedScene).instantiate()
	add_child(ui)
	await get_tree().process_frame
	assert(ui.has_method("open"), "UI espacial vinculada al juego")
	ui.call("open")
	assert(ui.call("is_open"), "Se abre la mochila")
	ui.call("close")
	assert(not ui.call("is_open"), "Se cierra la mochila")

	Inventory.clear()
	print("TEST_SPATIAL_INVENTORY_OK")
	get_tree().quit()
