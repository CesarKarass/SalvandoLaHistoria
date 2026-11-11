extends Node2D
## Smoke test de UI: skin, menú de inicio, opciones, centrado, pausa y reset.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_ui.tscn

func _ready() -> void:
	_run()

func _collect_controls(node: Node, out: Array[Control]) -> void:
	for c in node.get_children():
		if c is Control:
			out.append(c as Control)
		_collect_controls(c, out)

func _all_controls(node: Node) -> Array[Control]:
	var out: Array[Control] = []
	_collect_controls(node, out)
	return out

func _find_first_panel_container(node: Node) -> PanelContainer:
	for c in node.get_children():
		if c is PanelContainer:
			return c as PanelContainer
		var r := _find_first_panel_container(c)
		if r != null:
			return r
	return null

func _find_button(node: Node, text: String) -> Button:
	for c in _all_controls(node):
		if c is Button and (c as Button).text == text:
			return c as Button
	return null

func _run() -> void:
	var results: Array[String] = []

	# --- 1) Skin: el Theme tiene los styleboxes esperados ---
	var th: Theme = UISkin.theme()
	results.append("theme_panel=" + str(th.has_stylebox("panel", "Panel")))
	results.append("theme_button=" + str(th.has_stylebox("normal", "Button")))
	results.append("theme_slot=" + str(th.has_stylebox("panel", "Slot")))

	# --- 2) Menú de inicio: botones Jugar/Opciones/Salir ---
	var menu: Control = (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	add_child(menu)
	await get_tree().process_frame
	var menu_buttons: Array[String] = []
	for c in _all_controls(menu):
		if c is Button:
			menu_buttons.append((c as Button).text)
	results.append("menu_botones=" + str(menu_buttons))

	# --- 3) Opciones: 3 sliders + 1 check y panel centrado ---
	var opts: OptionsMenu = (load("res://scenes/ui/options_menu.tscn") as PackedScene).instantiate() as OptionsMenu
	add_child(opts)
	await get_tree().process_frame
	var sliders := 0
	var checks := 0
	for c in _all_controls(opts):
		if c is HSlider:
			sliders += 1
		elif c is CheckButton:
			checks += 1
	results.append("opciones_sliders=" + str(sliders))
	results.append("opciones_checks=" + str(checks))

	var vp := get_viewport().get_visible_rect().size
	results.append("viewport=" + str(vp))
	var opt_panel := _find_first_panel_container(opts)
	if opt_panel != null and vp.x > 0.0:
		var off := (opt_panel.get_global_rect().get_center() - vp * 0.5).length()
		results.append("opciones_centrado=" + str(off < 8.0) + " off=" + str(off))
	else:
		results.append("opciones_centrado=<no panel>")

	# --- 4) Settings: cambiar volumen actualiza en memoria ---
	var before := Settings.master_volume
	Settings.set_master_volume(37)
	results.append("settings_volumen=" + str(Settings.master_volume))
	Settings.set_master_volume(before)

	# --- 5) Pausa: open/close, centrado y que Opciones no se solape ---
	var pause: PauseMenu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	add_child(pause)
	await get_tree().process_frame
	pause.open()
	await get_tree().process_frame
	results.append("pausa_abierta=" + str(get_tree().paused))

	var pause_panel := _find_first_panel_container(pause)
	if pause_panel != null and vp.x > 0.0:
		var poff := (pause_panel.get_global_rect().get_center() - vp * 0.5).length()
		results.append("pausa_centrado=" + str(poff < 8.0) + " off=" + str(poff))

	var opts_btn := _find_button(pause, "Opciones")
	if opts_btn != null:
		opts_btn.pressed.emit()
		await get_tree().process_frame
		var content := pause.get_child(0) as Control
		results.append("pausa_contenido_oculto=" + str(not content.visible))
		results.append("pausa_opciones_abiertas=" + str(pause.get_child_count() >= 2))
		pause._close_options()
		await get_tree().process_frame
		results.append("pausa_contenido_restaurado=" + str(content.visible))

	pause.close()
	results.append("pausa_cerrada=" + str(not get_tree().paused))

	# --- 6) GameManager.reset_progress ---
	GameManager.set_flag("test_ui_flag", true)
	GameManager.reset_progress()
	results.append("reset_progress=" + str(not GameManager.has_flag("test_ui_flag")))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
