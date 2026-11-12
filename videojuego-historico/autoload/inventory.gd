extends Node
## Inventario básico (autoload): recoger, guardar y seleccionar objetos.
## Persiste entre escenas. Cada slot guarda {item: Item, count: int}.

signal inventory_changed
signal selection_changed

const MAX_SLOTS := 8

var items: Array[Dictionary] = []
var selected_index: int = 0

func add_item(item: Item, qty: int = 1) -> bool:
	if item == null or qty <= 0:
		return false
	if item.stackable:
		for stack: Dictionary in items:
			if stack["item"].id == item.id and stack["count"] < item.max_stack:
				stack["count"] = mini(item.max_stack, stack["count"] + qty)
				inventory_changed.emit()
				return true
	if items.size() >= MAX_SLOTS:
		return false
	items.append({"item": item, "count": mini(qty, item.max_stack)})
	inventory_changed.emit()
	return true

func remove_item(id: StringName, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	var removed := 0
	var i := items.size() - 1
	while i >= 0 and removed < qty:
		var stack: Dictionary = items[i]
		if stack["item"].id == id:
			var take: int = mini(stack["count"], qty - removed)
			stack["count"] -= take
			removed += take
			if stack["count"] <= 0:
				items.remove_at(i)
		i -= 1
	if removed > 0:
		_clamp_selection()
		inventory_changed.emit()
		return true
	return false

func has_item(id: StringName) -> bool:
	for stack: Dictionary in items:
		if stack["item"].id == id and stack["count"] > 0:
			return true
	return false

func count(id: StringName) -> int:
	var total := 0
	for stack: Dictionary in items:
		if stack["item"].id == id:
			total += stack["count"]
	return total

func select(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	if selected_index == index:
		return
	selected_index = index
	selection_changed.emit()

func get_selected() -> Item:
	if selected_index >= 0 and selected_index < items.size():
		return items[selected_index]["item"] as Item
	return null

func clear() -> void:
	items.clear()
	selected_index = 0
	inventory_changed.emit()
	selection_changed.emit()

func _clamp_selection() -> void:
	if selected_index >= items.size():
		selected_index = maxi(0, items.size() - 1)
		selection_changed.emit()
