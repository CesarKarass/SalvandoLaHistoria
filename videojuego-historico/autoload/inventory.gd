extends Node
## Inventario espacial persistente (8 x 6). Esta es la única fuente de datos.
## Cada entrada: {item: Item, count: int, position: Vector2i, size: Vector2i}.
## Mantiene la API que consumen Pickup, Event1 y los tests del equipo.

signal inventory_changed
signal selection_changed

const COLUMNS: int = 8
const ROWS: int = 6
const MAX_SLOTS: int = COLUMNS * ROWS

var items: Array[Dictionary] = []
var selected_index: int = 0


func add_item(item: Item, qty: int = 1) -> bool:
	if item == null or qty <= 0 or item.grid_size.x <= 0 or item.grid_size.y <= 0:
		return false

	# Trabajar en una copia: si no cabe toda la cantidad, no se recoge nada.
	var pending: Array[Dictionary] = []
	for entry: Dictionary in items:
		pending.append(entry.duplicate())
	var remaining: int = qty

	if item.stackable and item.id != &"":
		for entry: Dictionary in pending:
			var existing: Item = entry["item"] as Item
			if existing != null and existing.id == item.id and existing.stackable:
				var free_count: int = maxi(0, maxi(1, existing.max_stack) - int(entry["count"]))
				var amount: int = mini(remaining, free_count)
				entry["count"] = int(entry["count"]) + amount
				remaining -= amount
				if remaining == 0:
					break

	while remaining > 0:
		if pending.size() >= MAX_SLOTS:
			return false
		var position: Vector2i = _find_first_space(pending, item.grid_size)
		if position.x < 0:
			return false
		var amount: int = mini(remaining, maxi(1, item.max_stack)) if item.stackable else 1
		pending.append({
			"item": item,
			"count": amount,
			"position": position,
			"size": item.grid_size
		})
		remaining -= amount

	items = pending
	inventory_changed.emit()
	return true


func remove_item(id: StringName, qty: int = 1) -> bool:
	if qty <= 0 or count(id) < qty:
		return false
	var remaining: int = qty
	for i in range(items.size() - 1, -1, -1):
		var entry: Dictionary = items[i]
		var existing: Item = entry["item"] as Item
		if existing == null or existing.id != id:
			continue
		var amount: int = mini(remaining, int(entry["count"]))
		entry["count"] = int(entry["count"]) - amount
		remaining -= amount
		if int(entry["count"]) == 0:
			items.remove_at(i)
		if remaining == 0:
			break
	_clamp_selection()
	inventory_changed.emit()
	selection_changed.emit()
	return true


func has_item(id: StringName) -> bool:
	return count(id) > 0


func count(id: StringName) -> int:
	var total: int = 0
	for entry: Dictionary in items:
		var existing: Item = entry["item"] as Item
		if existing != null and existing.id == id:
			total += int(entry["count"])
	return total


func select(index: int) -> void:
	if index < 0 or index >= items.size() or selected_index == index:
		return
	selected_index = index
	selection_changed.emit()


func get_selected() -> Item:
	if selected_index >= 0 and selected_index < items.size():
		return items[selected_index]["item"] as Item
	return null


func get_item_at(cell: Vector2i) -> int:
	for i in range(items.size() - 1, -1, -1):
		var entry: Dictionary = items[i]
		if Rect2i(entry["position"], entry["size"]).has_point(cell):
			return i
	return -1


func can_place(item_index: int, position: Vector2i, size: Vector2i) -> bool:
	return _can_place_in(items, item_index, position, size)


func move_item(item_index: int, position: Vector2i, size: Vector2i) -> bool:
	if item_index < 0 or item_index >= items.size():
		return false
	var entry: Dictionary = items[item_index]
	var item: Item = entry["item"] as Item
	if item == null:
		return false
	var original: Vector2i = item.grid_size
	if size != original:
		if not item.can_rotate or size != Vector2i(original.y, original.x):
			return false
	if not can_place(item_index, position, size):
		return false
	entry["position"] = position
	entry["size"] = size
	inventory_changed.emit()
	return true


## Gira el objeto buscando su lugar: primero la casilla solicitada,
## después la posición libre más cercana (distancia Manhattan).
## Nunca altera el inventario si no existe una ubicación válida.
func rotate_item_near(item_index: int, preferred_position: Vector2i) -> bool:
	if item_index < 0 or item_index >= items.size():
		return false
	var entry: Dictionary = items[item_index]
	var item: Item = entry["item"] as Item
	if item == null or not item.can_rotate:
		return false
	var current_size: Vector2i = entry["size"]
	var rotated_size := Vector2i(current_size.y, current_size.x)
	var position: Vector2i = _find_nearest_space(item_index, preferred_position, rotated_size)
	if position.x < 0:
		return false
	return move_item(item_index, position, rotated_size)


func _find_nearest_space(excluded_index: int, origin: Vector2i, item_size: Vector2i) -> Vector2i:
	if _can_place_in(items, excluded_index, origin, item_size):
		return origin
	var best := Vector2i(-1, -1)
	var best_distance: int = 999999
	for y in range(ROWS - item_size.y + 1):
		for x in range(COLUMNS - item_size.x + 1):
			var candidate := Vector2i(x, y)
			if not _can_place_in(items, excluded_index, candidate, item_size):
				continue
			var distance: int = absi(x - origin.x) + absi(y - origin.y)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best

func clear() -> void:
	items.clear()
	selected_index = 0
	inventory_changed.emit()
	selection_changed.emit()


func _find_first_space(occupied: Array[Dictionary], item_size: Vector2i) -> Vector2i:
	for y in range(ROWS):
		for x in range(COLUMNS):
			var position := Vector2i(x, y)
			if _can_place_in(occupied, -1, position, item_size):
				return position
	return Vector2i(-1, -1)


func _can_place_in(occupied: Array[Dictionary], excluded_index: int, position: Vector2i, item_size: Vector2i) -> bool:
	if item_size.x <= 0 or item_size.y <= 0:
		return false
	if position.x < 0 or position.y < 0 or position.x + item_size.x > COLUMNS or position.y + item_size.y > ROWS:
		return false
	var candidate := Rect2i(position, item_size)
	for i in range(occupied.size()):
		if i == excluded_index:
			continue
		var entry: Dictionary = occupied[i]
		var rect := Rect2i(entry["position"], entry["size"])
		if candidate.intersects(rect):
			return false
	return true


func _clamp_selection() -> void:
	if selected_index >= items.size():
		selected_index = maxi(0, items.size() - 1)
		selection_changed.emit()
