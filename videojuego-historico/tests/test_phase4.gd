extends Node2D
## Smoke test de Fase 4: temporizador + victoria/derrota del Evento 1.
## Ejecuta: godot --headless --path <proyecto> res://tests/test_phase4.tscn

class TimerProbe extends EventBase:
	var won := false
	var lost := false
	func _on_win() -> void:
		won = true
	func _on_lose() -> void:
		lost = true

func _ready() -> void:
	_run()

func _run() -> void:
	var results: Array[String] = []

	# --- 1) El temporizador cuenta y al agotarse dispara derrota ---
	var probe := TimerProbe.new()
	probe.time_limit = 0.4
	add_child(probe)
	results.append("tiempo_inicial=" + str(probe.time_remaining))
	await get_tree().create_timer(0.8).timeout
	results.append("tiempo_final=" + str(probe.time_remaining))
	results.append("perdio=" + str(probe.lost))
	results.append("activo_tras_lose=" + str(probe.is_active))

	# --- 2) Ganar detiene el temporizador ---
	var probe2 := TimerProbe.new()
	probe2.time_limit = 5.0
	add_child(probe2)
	probe2.win()
	var t_before := probe2.time_remaining
	await get_tree().create_timer(0.2).timeout
	results.append("gano=" + str(probe2.won))
	results.append("temporizador_detenido=" + str(probe2.time_remaining == t_before))

	# --- 3) Evento 1: interactuar con el objetivo activa is_hidalgo_saved ---
	var e1: Event1 = load("res://scenes/events/event1/event1.tscn").instantiate()
	add_child(e1)
	await get_tree().process_frame
	var target: InteractTarget = e1.get_node_or_null("Antagonista") as InteractTarget
	if target != null:
		target.interact()
	results.append("flag_hidalgo=" + str(GameManager.get_flag("is_hidalgo_saved")))
	results.append("evento1_activo=" + str(e1.is_active))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
