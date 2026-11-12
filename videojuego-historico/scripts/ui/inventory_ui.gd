class_name InventoryUI
extends CanvasLayer
## Inventario: hotbar (selección rápida) + panel abrible con "inventory".
## Estilado por UISkin (slots "Slot"/"SlotSelected", panel "MenuPanel").

const SLOT_PX := 44
const COLUMNS := 4

var _hot_slots: Array[Panel] = []
var _grid_slots: Array[Panel] = []
var _panel: Panel

func _ready() -> void:
	layer = 15
	_build_hotbar()
	_build_panel()
	Inventory.inventory_changed.connect(_refresh)
	Inventory.selection_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		_panel.visible = not _panel.visible
	if Input.is_action_just_pressed("quick_1"):
		Inventory.select(0)
	elif Input.is_action_just_pressed("quick_2"):
		Inventory.select(1)
	elif Input.is_action_just_pressed("quick_3"):
		Inventory.select(2)
	elif Input.is_action_just_pressed("quick_4"):
		Inventory.select(3)

func _build_hotbar() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -110.0
	bar.offset_right = 110.0
	bar.offset_top = -58.0
	bar.offset_bottom = -10.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	for i in Inventory.MAX_SLOTS:
		var slot := _make_slot(SLOT_PX)
		slot.gui_input.connect(_on_slot_input.bind(i))
		bar.add_child(slot)
		_hot_slots.append(slot)

func _build_panel() -> void:
	_panel = UISkin.panel("MenuPanel")
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -180.0
	_panel.offset_right = 180.0
	_panel.offset_top = -150.0
	_panel.offset_bottom = 150.0
	_panel.visible = false
	add_child(_panel)

	var title := UISkin.subtitle("Maletín")
	title.position = Vector2(18, 12)
	_panel.add_child(title)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.position = Vector2(18, 52)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_panel.add_child(grid)
	for i in Inventory.MAX_SLOTS:
		var slot := _make_slot(SLOT_PX + 8)
		slot.gui_input.connect(_on_slot_input.bind(i))
		grid.add_child(slot)
		_grid_slots.append(slot)

func _make_slot(px: int) -> Panel:
	var slot := UISkin.panel("Slot")
	slot.custom_minimum_size = Vector2(px, px)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.anchor_left = 0.0
	icon.anchor_top = 0.0
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.offset_left = 4.0
	icon.offset_top = 4.0
	icon.offset_right = -4.0
	icon.offset_bottom = -4.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var count := Label.new()
	count.name = "Count"
	count.theme = UISkin.theme()
	count.theme_type_variation = "SmallLabel"
	count.anchor_left = 1.0
	count.anchor_top = 1.0
	count.anchor_right = 1.0
	count.anchor_bottom = 1.0
	count.offset_left = -22.0
	count.offset_top = -22.0
	count.offset_right = -2.0
	count.offset_bottom = -2.0
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)

	return slot

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Inventory.select(index)

func _refresh() -> void:
	_update_slots(_hot_slots)
	_update_slots(_grid_slots)

func _update_slots(slots: Array[Panel]) -> void:
	for i in slots.size():
		var slot := slots[i]
		var icon := slot.get_node("Icon") as TextureRect
		var count := slot.get_node("Count") as Label
		if i < Inventory.items.size():
			var stack: Dictionary = Inventory.items[i]
			var item: Item = stack["item"]
			icon.texture = item.icon
			var c: int = stack["count"]
			count.text = str(c) if c > 1 else ""
			slot.theme_type_variation = "SlotSelected" if i == Inventory.selected_index else "Slot"
		else:
			icon.texture = null
			count.text = ""
			slot.theme_type_variation = "Slot"
