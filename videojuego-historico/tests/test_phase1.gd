extends Node2D
## Smoke test de Fase 1: movimiento en 8 direcciones + colisiones.
## Se ejecuta con: godot --headless --path <proyecto> res://tests/test_phase1.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: CharacterBody2D = player_scene.instantiate()
	add_child(player)

	var results: Array[String] = []

	# --- 1) Movimiento a la derecha + encarado ---
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	for i in 20:
		await get_tree().physics_frame
	Input.action_release("move_right")
	results.append("derecha_x=" + str(player.global_position.x) + " facing=" + player.facing)

	# --- 2) Movimiento hacia arriba ---
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	Input.action_press("move_up")
	for i in 20:
		await get_tree().physics_frame
	Input.action_release("move_up")
	results.append("arriba_y=" + str(player.global_position.y) + " facing=" + player.facing)

	# --- 3) Diagonal normalizada (derecha + abajo) ---
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in 20:
		await get_tree().physics_frame
	Input.action_release("move_right")
	Input.action_release("move_down")
	results.append("diagonal_dx=" + str(player.global_position.x) + " dy=" + str(player.global_position.y))

	# --- 4) Colisión con un muro (no debe atravesarlo) ---
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	var wall_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 400)
	wall_shape.shape = rect
	wall.add_child(wall_shape)
	add_child(wall)
	wall.global_position = Vector2(48, 0)

	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	for i in 120:
		await get_tree().physics_frame
	Input.action_release("move_right")
	results.append("colision_x_final=" + str(player.global_position.x) + " (muro en x=48)")

	# --- 5) Deslizamiento en esquina: en diagonal contra el muro, X se bloquea
	#         pero Y sigue avanzando (no se queda atorado). ---
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in 90:
		await get_tree().physics_frame
	Input.action_release("move_right")
	Input.action_release("move_down")
	results.append("esquina_x=" + str(player.global_position.x) + " esquina_y=" + str(player.global_position.y))

	for line: String in results:
		print("TEST: ", line)
	print("TEST_DONE")
	get_tree().quit()
