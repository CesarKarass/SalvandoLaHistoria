
extends Control

const COLUMNS: int = 8
const ROWS: int = 6
const CELL_SIZE: int = 48

const BG_COLOR := Color("#303943")
const BORDER_COLOR := Color("#65717D")
const VALID_COLOR := Color("#8FD6A2")
const INVALID_COLOR := Color("#E17E76")

var items: Array[Dictionary] = []

var dragging_index: int = -1
var drag_offset: Vector2i = Vector2i.ZERO
var drag_size: Vector2i = Vector2i.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(
		COLUMNS * CELL_SIZE,
		ROWS * CELL_SIZE
	)

	# Objetos de prueba
	items = [
		{
			"name": "BOTIQUIN",
			"position": Vector2i(0, 0),
			"size": Vector2i(2, 2),
			"color": Color("#60778B")
		},
		{
			"name": "ESCOPETA",
			"position": Vector2i(3, 0),
			"size": Vector2i(4, 1),
			"color": Color("#8C7550")
		},
		{
			"name": "RADIO",
			"position": Vector2i(3, 2),
			"size": Vector2i(2, 2),
			"color": Color("#667E75")
		},
		{
			"name": "MUNICION",
			"position": Vector2i(6, 3),
			"size": Vector2i(1, 2),
			"color": Color("#897E52")
		}
	]

	queue_redraw()


# Convertir posición del ratón a casilla
func mouse_to_cell() -> Vector2i:
	var mouse_pos := get_local_mouse_position()

	return Vector2i(
		floori(mouse_pos.x / CELL_SIZE),
		floori(mouse_pos.y / CELL_SIZE)
	)


# Buscar el objeto que ocupa una casilla
func get_item_at(cell: Vector2i) -> int:
	for i in range(items.size() - 1, -1, -1):
		var item := items[i]
		var rect := Rect2i(
			item["position"],
			item["size"]
		)

		if rect.has_point(cell):
			return i

	return -1


# Validar espacio disponible
func can_place(
	item_index: int,
	position: Vector2i,
	item_size: Vector2i
) -> bool:

	# Verificar limites de la mochila
	if position.x < 0 or position.y < 0:
		return false

	if position.x + item_size.x > COLUMNS:
		return false

	if position.y + item_size.y > ROWS:
		return false

	# Comprobar cada casilla del objeto
	for y in range(item_size.y):
		for x in range(item_size.x):
			var cell := position + Vector2i(x, y)

			for i in range(items.size()):
				if i == item_index:
					continue

				var other := items[i]
				var other_rect := Rect2i(
					other["position"],
					other["size"]
				)

				if other_rect.has_point(cell):
					return false

	return true


# Gestionar raton y teclado
func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				start_drag()
			else:
				finish_drag()

	elif event is InputEventMouseMotion:
		if dragging_index != -1:
			queue_redraw()

	elif event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				rotate_item()


# Comenzar a arrastrar
func start_drag() -> void:
	if dragging_index != -1:
		return

	var cell := mouse_to_cell()

	if not Rect2i(
		Vector2i.ZERO,
		Vector2i(COLUMNS, ROWS)
	).has_point(cell):
		return

	var index := get_item_at(cell)

	if index == -1:
		return

	dragging_index = index

	var item := items[index]

	drag_offset = cell - Vector2i(
		item["position"]
	)

	drag_size = item["size"]

	queue_redraw()


# Terminar el arrastre
func finish_drag() -> void:
	if dragging_index == -1:
		return

	var position := mouse_to_cell() - drag_offset

	if can_place(
		dragging_index,
		position,
		drag_size
	):
		items[dragging_index]["position"] = position
		items[dragging_index]["size"] = drag_size

	# Si no cabe, conserva su posición y tamaño
	dragging_index = -1
	queue_redraw()


# Rotar el objeto seleccionado
func rotate_item() -> void:
	if dragging_index != -1:

		# Durante el arrastre, rotar la vista previa
		drag_size = Vector2i(
			drag_size.y,
			drag_size.x
		)

	else:
		# Rotar objeto bajo el cursor
		var index := get_item_at(mouse_to_cell())

		if index == -1:
			return

		var item := items[index]
		var old_size: Vector2i = item["size"]

		var new_size := Vector2i(
			old_size.y,
			old_size.x
		)

		if can_place(
			index,
			item["position"],
			new_size
		):
			items[index]["size"] = new_size

	queue_redraw()


# Dibujo principal
func _draw() -> void:
	draw_grid()

	# Dibujar los objetos colocados
	for i in range(items.size()):
		if i == dragging_index:
			continue

		var item := items[i]

		draw_item(
			item,
			item["position"],
			item["size"],
			false
		)

	# Dibujar vista previa al arrastrar
	if dragging_index != -1:
		var position := mouse_to_cell() - drag_offset
		var item := items[dragging_index]

		draw_item(
			item,
			position,
			drag_size,
			true
		)


# Dibujar las casillas
func draw_grid() -> void:
	for y in range(ROWS):
		for x in range(COLUMNS):

			var rect := Rect2(
				Vector2(
					x * CELL_SIZE + 2,
					y * CELL_SIZE + 2
				),
				Vector2(
					CELL_SIZE - 4,
					CELL_SIZE - 4
				)
			)

			draw_rect(rect, BG_COLOR)
			draw_rect(
				rect,
				BORDER_COLOR,
				false,
				1.0
			)


# Dibujar cada objeto
func draw_item(
	item: Dictionary,
	position: Vector2i,
	item_size: Vector2i,
	preview: bool
) -> void:

	var rect := Rect2(
		Vector2(position * CELL_SIZE)
		+ Vector2(3, 3),
		Vector2(item_size * CELL_SIZE)
		- Vector2(6, 6)
	)

	var item_color: Color = item["color"]
	var border_color := Color("#E0D8C5")

	if preview:
		if can_place(
			dragging_index,
			position,
			item_size
		):
			border_color = VALID_COLOR
		else:
			border_color = INVALID_COLOR

		item_color.a = 0.65

	draw_rect(rect, item_color)

	draw_rect(
		rect,
		border_color,
		false,
		2.0
	)

	# Nombre centrado
	var font := ThemeDB.fallback_font
	var font_size := 10

	var text_position := Vector2(
		rect.position.x + 3,
		rect.position.y + rect.size.y / 2.0 + 4
	)

	draw_string(
		font,
		text_position,
		str(item["name"]),
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x - 6,
		font_size,
		Color.WHITE
	)
