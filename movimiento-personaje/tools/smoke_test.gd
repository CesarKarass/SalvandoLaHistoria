extends Node
## ---------------------------------------------------------------------------
## SMOKE TEST — Movimiento cenital, colisiones y animaciones.
##
## Ejecutar con:
##   godot --headless --path . -- --smoke-test
##
## Sin la bandera "--smoke-test" este nodo se elimina solo y no interfiere
## con el juego. Sirve para comprobar en segundos que el movimiento, las
## hitboxes y las colisiones siguen funcionando tras cada cambio.
## ---------------------------------------------------------------------------

var _failures: PackedStringArray = []

var _level: LevelMap
var _player: CharacterBody2D
var _sprite: AnimatedSprite2D
var _dialogue: Label


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--smoke-test"):
		queue_free()
		return
	# Los autoloads se inicializan ANTES que la escena principal.
	while get_tree().current_scene == null:
		await get_tree().process_frame
	# Esperar a que la escena termine de construirse (Level._ready, etc.).
	while not get_tree().current_scene.is_node_ready():
		await get_tree().process_frame
	await _run()


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
func _check(condition: bool, label: String) -> void:
	if condition:
		print("  OK   " + label)
	else:
		_failures.append(label)
		print("  FAIL " + label)


func _ticks(count: int) -> void:
	"""Espera 'count' pasos de física, validando que el jugador no salga del mapa."""
	for i in count:
		await get_tree().physics_frame
		var p := _player.global_position
		var b := _level.bounds
		if p.x < b.position.x - 1.0 or p.y < b.position.y - 1.0 \
				or p.x > b.end.x + 1.0 or p.y > b.end.y + 1.0:
			_check(false, "el jugador se mantuvo dentro de los límites (salió en %s)" % str(p))
			break


func _anim_is(expected: StringName) -> bool:
	return _sprite.animation == expected


# ---------------------------------------------------------------------------
# Pruebas
# ---------------------------------------------------------------------------
func _run() -> void:
	var tree := get_tree()
	_level = tree.current_scene.get_node("Level") as LevelMap
	_player = tree.current_scene.get_node("Level/Player") as CharacterBody2D
	_sprite = _player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_dialogue = tree.get_first_node_in_group("dialogue") as Label

	print("[SMOKE] === Movimiento cenital y colisiones ===")
	_check(_level != null and _player != null and _dialogue != null, "escena principal cargada")

	# --- 1. El nivel se construyó a partir de la matriz ------------------
	var expected_walls := 0
	var expected_floor := 0
	var expected_spawn := Vector2.ZERO
	for i in _level.map.size():
		var row: String = _level.map[i]
		for j in row.length():
			var cell: String = row[j]
			if cell == "#" or cell == "B":
				expected_walls += 1
			else:
				expected_floor += 1
			if cell == "P":
				expected_spawn = Vector2(
					j * LevelMap.TILE + LevelMap.TILE * 0.5,
					(i + 1) * LevelMap.TILE
				)

	var walls := 0
	var npcs := 0
	for k in _level.get_children().size():
		var body := _level.get_children()[k] as StaticBody2D
		if body != null:
			if body.collision_layer == _level.LAYER_WORLD:
				walls += 1
			elif body.collision_layer == 4:
				npcs += 1

	var floor_layer := tree.current_scene.get_node("FloorLayer") as Node2D
	_check(walls == expected_walls, "bloques sólidos creados: %d (esperados %d)" % [walls, expected_walls])
	_check(floor_layer.get_child_count() == expected_floor,
		"baldosas de piso: %d (esperadas %d)" % [floor_layer.get_child_count(), expected_floor])
	_check(npcs == 1, "1 NPC instanciado con su hitbox")
	_check(_level.spawn_position == expected_spawn, "aparición del jugador en %s" % str(expected_spawn))
	# Tolerancia de 0.5 px: al nacer tocando un muro, la física de contacto
	# asienta al cuerpo con una separación ínfima (sub-pixel).
	_check(_player.global_position.distance_to(expected_spawn) <= 0.5,
		"el jugador nace en su punto de aparición (actual %s)" % str(_player.global_position))
	_check(_level.bounds.size == Vector2(16 * LevelMap.TILE, 12 * LevelMap.TILE),
		"límites del nivel = %s" % str(_level.bounds.size))

	# --- 2. Hitboxes y capas ---------------------------------------------
	var shape := _player.get_node("CollisionShape2D").shape as RectangleShape2D
	_check(shape != null, "la hitbox del jugador es un rectángulo")
	if shape != null:
		_check(shape.size == Vector2(26, 16),
			"hitbox del jugador 26x16 a los pies (actual %s)" % str(shape.size))
	_check(_player.collision_layer == 2 and _player.collision_mask == 5,
		"capas del jugador: capa 2, máscara 1+3 (mundo e interactuables)")
	var area := _player.get_node("InteractArea") as Area2D
	_check(area != null and area.collision_mask == 4,
		"InteractArea detecta la capa 3 (NPC)")

	# --- 3. Animaciones estilo Moonlighter -------------------------------
	var frames := _sprite.sprite_frames
	_check(frames != null, "SpriteFrames construido desde las hojas de sprites")
	if frames != null:
		_check(frames.get_animation_names().size() == 16,
			"16 animaciones (8 idle + 8 walk) (hay %d)" % frames.get_animation_names().size())
		_check(frames.get_frame_count(&"walk_up") == 4, "walk_up tiene 4 frames")
		_check(frames.get_frame_count(&"idle_down") == 2, "idle_down tiene 2 frames")
		_check(frames.has_animation(&"walk_down_right"), "existe la diagonal walk_down_right")

	# --- 4. Movimiento diagonal: 8 direcciones sin acelerar --------------
	Input.action_press("move_up")
	Input.action_press("move_right")
	await _ticks(12)
	var speed := _player.velocity.length()
	_check(absf(speed - 190.0) < 0.5,
		"velocidad diagonal normalizada a 190 px/s (actual %.1f)" % speed)
	_check(absf(_player.velocity.x) > 1.0 and absf(_player.velocity.y) > 1.0,
		"se desplaza en X e Y a la vez = 8 direcciones")
	_check(_anim_is(&"walk_up_right"), "anima walk_up_right al nordeste (actual: %s)" % String(_sprite.animation))

	# --- 4b. Modo 4 direcciones: el eje secundario se bloquea -------------
	_player.set("allow_diagonals", false)
	await _ticks(12)
	_check(absf(_player.velocity.x) < 0.5,
		"modo 4 direcciones bloquea el eje X (actual vx=%.1f)" % _player.velocity.x)
	_player.set("allow_diagonals", true)

	# --- 5. Cambio de animación al ir recto ------------------------------
	Input.action_release("move_right")
	await _ticks(60)
	_check(_anim_is(&"walk_up"), "cambia a walk_up al ir recto al norte (actual: %s)" % String(_sprite.animation))

	# --- 6. Colisión con el muro superior --------------------------------
	Input.action_release("move_up")
	await _ticks(5)
	_player.global_position = Vector2(96, 704)   # columna libre (x=96)
	await _ticks(2)
	Input.action_press("move_up")
	await _ticks(500)
	# muro en y=0..64 + media hitbox (16) => se detiene en y=80
	_check(absf(_player.global_position.y - 80.0) <= 1.0,
		"choca contra el muro norte y se detiene en y=80 (actual y=%.1f)" % _player.global_position.y)
	# Al empujar contra el muro se mantiene la animación de caminar en el
	# sitio (comportamiento estándar de Moonlighter/Zelda).
	_check(_anim_is(&"walk_up"), "mantiene walk_up empujando contra el muro (actual: %s)" % String(_sprite.animation))
	Input.action_release("move_up")
	await _ticks(10)
	_check(_anim_is(&"idle_up"), "al soltar queda en idle_up (conserva la última dirección mirada)")

	# --- 7. Colisión con el muro este ------------------------------------
	Input.action_press("move_right")
	await _ticks(500)
	# muro en x=960 - media hitbox (13) => se detiene en x=947
	_check(absf(_player.global_position.x - 947.0) <= 1.0,
		"choca contra el muro este y se detiene en x=947 (actual x=%.1f)" % _player.global_position.x)
	Input.action_release("move_right")
	await _ticks(5)

	# --- 8. InteractArea detecta al NPC (hitbox de interacción) ----------
	_player.global_position = Vector2(686, 704)
	await _ticks(3)
	var nearby: Array = _player.get("nearby_bodies")
	_check(nearby.size() >= 1, "InteractArea detecta al NPC cercano")

	# --- 9. Tecla Interact muestra el diálogo -----------------------------
	Input.action_release("interact")
	Input.action_press("interact")
	await _ticks(2)
	_check(_dialogue.text != "", "la tecla Interact muestra el diálogo del NPC")
	Input.action_release("interact")

	# --- 10. El NPC es sólido: no se atraviesa ---------------------------
	_player.global_position = Vector2(660, 704)
	await _ticks(2)
	Input.action_press("move_right")
	await _ticks(80)
	# hitbox del NPC en x=721 - media hitbox jugador (13) => para en x=708
	_check(absf(_player.global_position.x - 708.0) <= 1.5,
		"no atraviesa al NPC: se detiene en x=708 (actual x=%.1f)" % _player.global_position.x)
	Input.action_release("move_right")

	# --- Resumen ----------------------------------------------------------
	if _failures.is_empty():
		print("[SMOKE] RESULTADO: TODAS LAS PRUEBAS PASARON")
		get_tree().quit(0)
	else:
		print("[SMOKE] RESULTADO: %d FALLO(S)" % _failures.size())
		for f in _failures:
			print("[SMOKE]   FALLO: " + f)
		get_tree().quit(1)
