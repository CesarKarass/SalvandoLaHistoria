extends Node2D
## Smoke test de Fase 5: inventario (recoger, guardar, seleccionar) + integración
## con la condición de victoria del Evento 1.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_phase5.tscn

func _ready() -> void:
	_run()

func _make_item(id: StringName, item_name: String) -> Item:
	var it := Item.new()
	it.id = id
	it.display_name = item_name
	return it

func _run() -> void:
	var results: Array[String] = []
	Inventory.clear()

	# --- 1) add / has / count / select / get_selected ---
	var monedas := _make_item(&"bolsa_monedas", "Bolsa de monedas")
	Inventory.add_item(monedas)
	results.append("tiene_monedas=" + str(Inventory.has_item(&"bolsa_monedas")))
	results.append("count=" + str(Inventory.count(&"bolsa_monedas")))
	Inventory.select(0)
	var sel: Item = Inventory.get_selected()
	results.append("seleccionado=" + str(sel.id) if sel != null else "seleccionado=<null>")

	# --- 2) remove ---
	Inventory.remove_item(&"bolsa_monedas")
	results.append("tras_remove=" + str(Inventory.has_item(&"bolsa_monedas")))

	# --- 3) Pickup: recoger un objeto del mapa ---
	var pickup_scene: PackedScene = load("res://scenes/items/pickup.tscn")
	var pickup: Pickup = pickup_scene.instantiate() as Pickup
	pickup.item = _make_item(&"mapa", "Mapa antiguo")
	add_child(pickup)
	pickup.interact()
	await get_tree().process_frame
	results.append("pickup_recogido=" + str(Inventory.has_item(&"mapa")))
	results.append("pickup_liberado=" + str(not is_instance_valid(pickup)))

	# --- 4) Integración con Evento 1: sin ítem no gana; con ítem gana ---
	Inventory.clear()
	var e1: Event1 = load("res://scenes/events/event1/event1.tscn").instantiate() as Event1
	add_child(e1)
	await get_tree().process_frame
	var target: InteractTarget = e1.get_node_or_null("Antagonista") as InteractTarget
	if target != null:
		target.interact()
	results.append("sin_item_bandera=" + str(GameManager.get_flag("is_hidalgo_saved")))
	results.append("sin_item_activo=" + str(e1.is_active))

	Inventory.add_item(_make_item(&"bolsa_monedas", "Bolsa de monedas"))
	Inventory.select(0)
	if target != null:
		target.interact()
	results.append("con_item_bandera=" + str(GameManager.get_flag("is_hidalgo_saved")))
	results.append("con_item_activo=" + str(e1.is_active))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
