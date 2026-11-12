extends Control
## Escena de demostración independiente; no afecta el progreso del juego normal.
## Muestra objetos historicos y del prototipo en la misma maleta.

func _ready() -> void:
	Inventory.clear()
	_seed("res://resources/items/mapa.tres", Vector2i(0, 0))
	_seed("res://resources/items/bolsa_monedas.tres", Vector2i(2, 0))
	_seed("res://inventario/items/pistol.tres", Vector2i(4, 0))
	_seed("res://inventario/items/medkit.tres", Vector2i(6, 0))
	_seed("res://inventario/items/shotgun.tres", Vector2i(0, 3))
	var radio := Item.new()
	radio.id = &"radio"
	radio.display_name = "RADIO"
	radio.grid_size = Vector2i(2, 2)
	radio.grid_color = Color("#667E75")
	radio.icon = load("res://inventario/art/icons/radio.png") as Texture2D
	_place(radio, Vector2i(4, 3))
	var ammo := Item.new()
	ammo.id = &"municion"
	ammo.display_name = "MUNICION"
	ammo.grid_size = Vector2i(1, 2)
	ammo.grid_color = Color("#897E52")
	ammo.icon = load("res://inventario/art/icons/ammo.png") as Texture2D
	_place(ammo, Vector2i(6, 3))
	get_node("InventoryUI").open()


func _seed(path: String, position: Vector2i) -> void:
	var item := load(path) as Item
	if item != null:
		_place(item, position)


func _place(item: Item, position: Vector2i) -> void:
	if Inventory.add_item(item):
		Inventory.move_item(Inventory.items.size() - 1, position, item.grid_size)
