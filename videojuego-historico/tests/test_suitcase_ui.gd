extends Node
## Prueba de la animación y compatibilidad de la interfaz con Inventory.

func _ready() -> void:
	var scene := load("res://scenes/ui/inventory_ui.tscn") as PackedScene
	assert(scene != null, "Debe existir la escena UI del juego")
	var ui := scene.instantiate() as CanvasLayer
	add_child(ui)
	assert(ui.has_method("open") and ui.has_method("close"), "API conservada")
	ui.open()
	assert(ui.is_open(), "Apertura inmediata desde el estado lógico")
	await get_tree().create_timer(0.70).timeout
	var lid := ui.get_node("Overlay/Suitcase/OpenLid") as TextureRect
	var cover := ui.get_node("Overlay/Suitcase/ClosedCover") as TextureRect
	var grid := ui.get_node("Overlay/Suitcase/Contents/InventoryGrid") as InventoryGrid
	assert(is_equal_approx(lid.scale.y, 1.0), "La tapa termina abierta")
	assert(cover.scale.y < 0.05, "La cubierta se repliega")
	assert(grid != null and InventoryGrid.COLUMNS == 8 and InventoryGrid.ROWS == 6, "La cuadrícula original sigue disponible")
	ui.close()
	assert(not ui.is_open(), "Cierra lógicamente sin retrasar los controles")
	await get_tree().create_timer(0.60).timeout
	assert(not ui.get_node("Overlay").visible, "La interfaz se oculta al acabar")
	print("TEST_SUITCASE_UI_OK")
	get_tree().quit()
