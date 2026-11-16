class_name InventoryGrid
extends Control
## Cuadrícula creada por el equipo de inventario: ahora dibuja los objetos
## reales de Inventory (autoload) y actualiza sus posiciones al arrastrar.
## Ratón/touch: arrastrar, pulsar: seleccionar, R/botón: rotar.

const COLUMNS: int = 8
const ROWS: int = 6
const CELL_SIZE: int = 48

const BG_COLOR := Color("#121523")
const BORDER_COLOR := Color("#a86940")
const VALID_COLOR := Color("#a0e4a2")
const INVALID_COLOR := Color("#ee7772")
const SELECTED_COLOR := Color("#f4c46d")

signal rotation_rejected

var dragging_index: int = -1
var drag_offset: Vector2i = Vector2i.ZERO
var drag_size: Vector2i = Vector2i.ZERO
var _pointer: Vector2 = Vector2.ZERO
var _touch_index: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(COLUMNS * CELL_SIZE, ROWS * CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Inventory.inventory_changed.connect(queue_redraw)
	Inventory.selection_changed.connect(queue_redraw)
	queue_redraw()


func mouse_to_cell() -> Vector2i:
	return Vector2i(floori(_pointer.x / CELL_SIZE), floori(_pointer.y / CELL_SIZE))


func get_item_at(cell: Vector2i) -> int:
	return Inventory.get_item_at(cell)


func can_place(item_index: int, position: Vector2i, item_size: Vector2i) -> bool:
	return Inventory.can_place(item_index, position, item_size)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			start_drag()
		else:
			finish_drag()
	elif event is InputEventMouseMotion:
		_pointer = get_global_transform_with_canvas().affine_inverse() * event.position
		if dragging_index != -1:
			queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_pointer = get_global_transform_with_canvas().affine_inverse() * event.position
			if _within_grid(mouse_to_cell()):
				_touch_index = event.index
				start_drag()
		elif not event.pressed and event.index == _touch_index:
			_pointer = get_global_transform_with_canvas().affine_inverse() * event.position
			finish_drag()
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_pointer = get_global_transform_with_canvas().affine_inverse() * event.position
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotate_item()


func start_drag() -> void:
	if dragging_index != -1:
		return
	var cell := mouse_to_cell()
	if not _within_grid(cell):
		return
	var index: int = get_item_at(cell)
	if index == -1:
		return
	Inventory.select(index)
	dragging_index = index
	var entry: Dictionary = Inventory.items[index]
	drag_offset = cell - Vector2i(entry["position"])
	drag_size = entry["size"]
	queue_redraw()


func finish_drag() -> void:
	if dragging_index == -1:
		return
	var position := mouse_to_cell() - drag_offset
	# La validación es atómica: si no cabe, el objeto permanece en su sitio.
	Inventory.move_item(dragging_index, position, drag_size)
	dragging_index = -1
	queue_redraw()


func rotate_item() -> void:
	var index: int = dragging_index
	if index == -1:
		index = Inventory.selected_index
	if index < 0 or index >= Inventory.items.size():
		return
	var entry: Dictionary = Inventory.items[index]
	var item: Item = entry["item"] as Item
	if item == null or not item.can_rotate:
		rotation_rejected.emit()
		return

	var preferred_position: Vector2i = entry["position"]
	var next_offset := drag_offset
	if dragging_index != -1:
		var size_after: Vector2i = Vector2i(drag_size.y, drag_size.x)
		next_offset = Vector2i(
			mini(drag_offset.x, size_after.x - 1),
			mini(drag_offset.y, size_after.y - 1)
		)
		preferred_position = mouse_to_cell() - next_offset

	# Se rota y recoloca atómicamente: nunca se modifica a medias un objeto.
	if not Inventory.rotate_item_near(index, preferred_position):
		rotation_rejected.emit()
		queue_redraw()
		return

	if dragging_index != -1:
		drag_size = Inventory.items[index]["size"]
		drag_offset = next_offset
		# Si hubo que buscar otra zona, dejamos el objeto allí y terminamos
		# el arrastre para que el cursor no muestre una posición inválida.
		if Inventory.items[index]["position"] != preferred_position:
			dragging_index = -1
			_touch_index = -1
	queue_redraw()


func _within_grid(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, Vector2i(COLUMNS, ROWS)).has_point(cell)


func _draw() -> void:
	draw_grid()
	for i in range(Inventory.items.size()):
		if i == dragging_index:
			continue
		var entry: Dictionary = Inventory.items[i]
		draw_item(entry, entry["position"], entry["size"], false, i == Inventory.selected_index)
	if dragging_index != -1 and dragging_index < Inventory.items.size():
		var position := mouse_to_cell() - drag_offset
		draw_item(Inventory.items[dragging_index], position, drag_size, true, true)


func draw_grid() -> void:
	# Casillas oscuras con bisel de cuero/bronce, a la escala exacta del arte.
	for y in range(ROWS):
		for x in range(COLUMNS):
			var origin := Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var outer := Rect2(origin + Vector2(1, 1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2))
			var inside := Rect2(origin + Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8))
			draw_rect(outer, Color("#3d211e"))
			draw_rect(inside, BG_COLOR)
			draw_line(origin + Vector2(2, 2), origin + Vector2(CELL_SIZE - 2, 2), Color("#d28b4e"), 2.0)
			draw_line(origin + Vector2(2, 2), origin + Vector2(2, CELL_SIZE - 2), BORDER_COLOR, 2.0)
			draw_line(origin + Vector2(3, CELL_SIZE - 2), origin + Vector2(CELL_SIZE - 2, CELL_SIZE - 2), Color("#42231e"), 2.0)
			draw_line(origin + Vector2(CELL_SIZE - 2, 3), origin + Vector2(CELL_SIZE - 2, CELL_SIZE - 2), Color("#42231e"), 2.0)


func draw_item(entry: Dictionary, position: Vector2i, item_size: Vector2i, preview: bool, selected: bool) -> void:
	var rect := Rect2(Vector2(position * CELL_SIZE) + Vector2(5, 5), Vector2(item_size * CELL_SIZE) - Vector2(10, 10))
	var item: Item = entry["item"] as Item
	if item == null:
		return
	var border := SELECTED_COLOR if selected else Color("#bc814d")
	var fill: Color = item.grid_color.darkened(0.60)
	fill.a = 0.72 if preview else 1.0
	if preview:
		border = VALID_COLOR if can_place(dragging_index, position, item_size) else INVALID_COLOR
	# Una pieza ocupa todas sus casillas: sin bordes internos que la fragmenten.
	draw_rect(rect, fill)
	draw_rect(rect, Color("#3a1c1a"), false, 3.0)
	draw_rect(rect.grow(-2.0), border, false, 2.0)
	if item.icon != null:
		var available := rect.size - Vector2(11, 11)
		var ratio: float = minf(available.x / item.icon.get_width(), available.y / item.icon.get_height())
		var icon_size := Vector2(item.icon.get_size()) * ratio
		var icon_rect := Rect2(rect.position + (rect.size - icon_size) * 0.5, icon_size)
		draw_texture_rect(item.icon, icon_rect, false, Color(1, 1, 1, 0.62 if preview else 1.0))
	else:
		var font := ThemeDB.fallback_font
		var label: String = item.display_name if item.display_name != "" else str(item.id)
		var font_size: int = 11 if rect.size.x >= 68 else 9
		var center := Vector2(rect.position.x + 2.0, rect.position.y + rect.size.y * 0.5 + 4.0)
		draw_string(font, center, label.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 4.0, font_size, Color("#f8dfb6"))
	if int(entry["count"]) > 1:
		var counter := str(entry["count"])
		var font := ThemeDB.fallback_font
		var pos := Vector2(rect.end.x - 27.0, rect.end.y - 4.0)
		draw_rect(Rect2(pos - Vector2(1, 12), Vector2(26, 15)), Color("#382016"))
		draw_string(font, pos, "x" + counter, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 11, Color("#fbe5b9"))
