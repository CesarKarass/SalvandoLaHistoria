extends SceneTree
## Prueba automática del movimiento cenital y las colisiones.
## Ejecutar:  godot --headless --path <proyecto> --script res://tests/test_movimiento.gd

var escena: Node2D
var jugador: CharacterBody2D
var joystick: Control
var frame := 0
var fallos: PackedStringArray = PackedStringArray()
var p0 := Vector2.ZERO
var x_recta := 0.0


func _initialize() -> void:
	escena = load("res://scenes/plaza_demo.tscn").instantiate()
	root.add_child(escena)
	jugador = escena.get_node("Jugador")
	joystick = escena.get_node("Joystick")
	process_frame.connect(_on_frame)


func chequear(cond: bool, texto: String) -> void:
	if cond:
		print("  OK   - ", texto)
	else:
		fallos.append(texto)
		print("  FALLO- ", texto)


func solapado(pos: Vector2) -> bool:
	# Hitbox real del jugador: centro (pos.x, pos.y + 13), tamaño 30 x 22.
	var rect := Rect2(pos.x - 15.0, pos.y + 2.0, 30.0, 22.0)
	var plano: PackedStringArray = escena.plano
	for fila in plano.size():
		for col in plano[fila].length():
			if not plano[fila][col] in "#Bb":
				continue
			var celda := Rect2(col * 64.0 + 0.5, fila * 64.0 + 0.5, 63.0, 63.0)
			if rect.intersects(celda):
				return true
	return false


func _on_frame() -> void:
	frame += 1

	if frame == 30:
		print("\n[1] Estado inicial y movimiento diagonal")
		p0 = jugador.global_position
		chequear(not solapado(p0), "el jugador nace sin atravesar bloques")
		Input.action_press("move_up")
		Input.action_press("move_right")

	elif frame == 61:
		var v := jugador.velocity.length()
		chequear(absf(v - 150.0) < 15.0, "la diagonal va a %.0f px/s (no más rápido que en recto)" % v)
		Input.action_release("move_up")
		Input.action_release("move_right")

	elif frame == 90:
		print("\n[2] Tras soltar: inercia + sin penetración")
		chequear(jugador.global_position != p0, "el personaje se desplazó")
		chequear(not solapado(jugador.global_position), "nunca quedó dentro de un muro/edificio")
		jugador.global_position = Vector2(544, 928)
		jugador.velocity = Vector2.ZERO
		Input.action_press("move_up")
		x_recta = jugador.global_position.x

	elif frame == 120:
		print("\n[3] Movimiento recto hacia arriba")
		chequear(jugador.velocity.y < -130.0, "velocidad arriba = %.0f px/s" % jugador.velocity.y)
		chequear(absf(jugador.velocity.x) < 1.0, "sin deriva lateral en movimiento recto")

	elif frame == 320:
		print("\n[4] Colisión con el edificio de adobe (fila 12)")
		var y_final := jugador.global_position.y
		# El hitbox (top = y + 2) debe chocar contra la cara inferior del adobe (y = 832).
		chequear(y_final > 824.0 and y_final < 836.0, "se detuvo contra el muro (y = %.1f, esperado ~830)" % y_final)
		chequear(absf(jugador.global_position.x - x_recta) < 2.0, "no se desvió de su eje")
		chequear(not solapado(jugador.global_position), "no penetró el adobe")
		Input.action_release("move_up")

		jugador.global_position = Vector2(544, 928)
		jugador.velocity = Vector2.ZERO
		joystick.size = Vector2(144, 144)
		var toque := InputEventScreenTouch.new()
		toque.index = 0
		toque.pressed = true
		toque.position = Vector2(120, 72)  # mitad derecha del joystick
		joystick._gui_input(toque)
		chequear(Input.is_action_pressed("move_right"), "el joystick tactil activa move_right")

	elif frame == 350:
		print("\n[5] Joystick virtual (táctil)")
		chequear(jugador.velocity.x > 100.0, "el avatar avanza con el dedo (vx = %.0f)" % jugador.velocity.x)
		var toque_off := InputEventScreenTouch.new()
		toque_off.index = 0
		toque_off.pressed = false
		toque_off.position = Vector2(72, 72)
		joystick._gui_input(toque_off)
		chequear(not Input.is_action_pressed("move_right"), "al soltar se liberan las acciones")

	elif frame == 390:
		print("\n[6] Esquema de 4 direcciones")
		chequear(absf(jugador.velocity.x) < 5.0, "frena al soltar el joystick (vx = %.1f)" % jugador.velocity.x)
		jugador.global_position = Vector2(544, 928)
		jugador.velocity = Vector2.ZERO
		jugador.esquema_direcciones = 0
		Input.action_press("move_up")
		Input.action_press("move_right")

	elif frame == 415:
		var vx := absf(jugador.velocity.x)
		var vy := absf(jugador.velocity.y)
		chequear((vx > 130.0 and vy < 5.0) or (vy > 130.0 and vx < 5.0),
			"en modo 4 direcciones solo usa un eje (vx=%.0f, vy=%.0f)" % [vx, vy])
		Input.action_release("move_up")
		Input.action_release("move_right")
		jugador.esquema_direcciones = 1

	elif frame == 425:
		print("\n[7] Cuantización de 4 direcciones (unitaria)")
		chequear(Jugador.cuantizar_4_direcciones(Vector2(1, 0.3)) == Vector2(1, 0), "(1, 0.3) -> (1, 0)")
		chequear(Jugador.cuantizar_4_direcciones(Vector2(0.2, -1)) == Vector2(0, -1), "(0.2, -1) -> (0, -1)")
		chequear(Jugador.cuantizar_4_direcciones(Vector2(-0.9, -0.4)) == Vector2(-1, 0), "(-0.9, -0.4) -> (-1, 0)")
		chequear(Jugador.cuantizar_4_direcciones(Vector2.ZERO) == Vector2.ZERO, "(0, 0) -> (0, 0)")

	elif frame == 435:
		print("")
		if fallos.is_empty():
			print("RESULTADO: TODAS LAS PRUEBAS PASARON ✔")
			quit(0)
		else:
			print("RESULTADO: %d FALLO(S) ✘" % fallos.size())
			for f in fallos:
				print("  - ", f)
			quit(1)
