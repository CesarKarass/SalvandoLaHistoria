extends SceneTree
## Verificación automática de:
##   A) Movimiento en las 8 direcciones (rumbo, velocidad y animación de cada una).
##   B) Estilo Moonlighter: inercia, animación de caminar (SpriteFrames),
##      esquiva con enfriamiento y cámara con anticipación.
##
## Ejecutar:  godot --headless --path <proyecto> --script res://tests/test_moonlighter.gd

var escena: Node2D
var jugador: CharacterBody2D
var sprite: AnimatedSprite2D
var camara: Camera2D
var plano: PackedStringArray
var fallos: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	escena = load("res://scenes/plaza_demo.tscn").instantiate()
	root.add_child(escena)
	jugador = escena.get_node("Jugador")
	sprite = jugador.get_node("SpriteJugador")
	camara = jugador.get_node("Camara")
	plano = escena.plano
	_ejecutar()


func _esperar(fisicas: int) -> void:
	for i in fisicas:
		await physics_frame


func chequear(cond: bool, texto: String) -> void:
	if cond:
		print("  OK   - ", texto)
	else:
		fallos.append(texto)
		print("  FALLO- ", texto)


# --------------------------------------------------------------------------- #
# Utilidades de mapa (hitbox real del jugador: 30 x 22 con centro en y + 13)
# --------------------------------------------------------------------------- #
func _choca(pos: Vector2) -> bool:
	var rect := Rect2(pos.x - 15.0, pos.y + 2.0, 30.0, 22.0)
	for fila in plano.size():
		for col in plano[fila].length():
			if not plano[fila][col] in "#Bb":
				continue
			var celda := Rect2(col * 64.0 + 1.0, fila * 64.0 + 1.0, 62.0, 62.0)
			if rect.intersects(celda):
				return true
	return false


## Busca un punto del suelo con ~150 px libres hacia `dir` para testear sin chocar.
func _punto_libre(dir: Vector2) -> Vector2:
	var u := dir.normalized()
	for fila in range(1, plano.size() - 1):
		for col in range(1, plano[fila].length() - 1):
			var base := Vector2(col * 64.0 + 32.0, fila * 64.0 + 32.0)
			if _choca(base):
				continue
			var libre := true
			for paso in range(1, 4):
				if _choca(base + u * float(paso) * 50.0):
					libre = false
					break
			if libre:
				return base
	return Vector2(-1000, -1000)


func _soltar_movimiento() -> void:
	for accion in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(accion)


func _pulsar(dir: Vector2) -> void:
	if dir.x > 0.0:
		Input.action_press("move_right", 1.0)
	else:
		Input.action_release("move_right")
	if dir.x < 0.0:
		Input.action_press("move_left", 1.0)
	else:
		Input.action_release("move_left")
	if dir.y > 0.0:
		Input.action_press("move_down", 1.0)
	else:
		Input.action_release("move_down")
	if dir.y < 0.0:
		Input.action_press("move_up", 1.0)
	else:
		Input.action_release("move_up")


func _ubicar(dir: Vector2) -> void:
	var punto := _punto_libre(dir)
	jugador.global_position = punto
	jugador.velocity = Vector2.ZERO


func _velocidad_max_en(fotogramas: int) -> float:
	var maxima := 0.0
	for i in fotogramas:
		await _esperar(1)
		maxima = maxf(maxima, jugador.velocity.length())
	return maxima


## Pulsa "esquivar" como lo haría un input real (parse_input_event) y mide
## el pico de velocidad y de escala durante la ventana de la esquiva.
func _esquivar_y_medir() -> Array:
	_enviar_esquivar(true)
	var pico_vel := 0.0
	var pico_escala := 1.0
	for i in 20:
		await _esperar(1)
		pico_vel = maxf(pico_vel, jugador.velocity.length())
		pico_escala = maxf(pico_escala, sprite.scale.x)
	_enviar_esquivar(false)
	return [pico_vel, pico_escala]


func _enviar_esquivar(pulsada: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = &"esquivar"
	evento.pressed = pulsada
	Input.parse_input_event(evento)


# --------------------------------------------------------------------------- #
# Pruebas
# --------------------------------------------------------------------------- #
func _ejecutar() -> void:
	await _esperar(10)

	print("\n[A] 8 DIRECCIONES")
	chequear(jugador.esquema_direcciones == 1, "el escenario inicia en modo 8 direcciones")

	var direcciones := {
		Vector2(1, 0): "derecha        →",
		Vector2(1, 1): "abajo-derecha  ↘",
		Vector2(0, 1): "abajo          ↓",
		Vector2(-1, 1): "abajo-izquierda ↙",
		Vector2(-1, 0): "izquierda      ←",
		Vector2(-1, -1): "arriba-izquierda ↖",
		Vector2(0, -1): "arriba         ↑",
		Vector2(1, -1): "arriba-derecha  ↗",
	}

	for dir in direcciones:
		_soltar_movimiento()
		_ubicar(dir)
		await _esperar(3)
		_pulsar(dir)
		await _esperar(25)

		var v := jugador.velocity
		chequear(absf(v.length() - 150.0) < 12.0,
			"%s velocidad %.0f px/s (igual que en recto)" % [direcciones[dir], v.length()])
		chequear(v.normalized().dot(dir.normalized()) > 0.985,
			"%s rumbo correcto" % direcciones[dir])

		# Animación esperada: "walk_" + nombre de la dirección (8 direcciones)
		var anim_esperada := "walk_" + Jugador.NOMBRES_DIRECCIONES[Jugador.indice_8_direcciones(dir)]
		chequear(String(sprite.animation) == anim_esperada,
			"%s animación «%s» correcta" % [direcciones[dir], anim_esperada])

	_soltar_movimiento()

	print("\n[B] INERCIA (estilo Moonlighter)")
	_ubicar(Vector2(1, 0))
	await _esperar(3)
	Input.action_press("move_right", 1.0)
	await _esperar(3)
	chequear(jugador.velocity.length() < 100.0,
		"arranque progresivo: %.0f px/s tras 3 fotogramas (no teletransporta)" % jugador.velocity.length())
	await _esperar(40)
	chequear(absf(jugador.velocity.length() - 150.0) < 12.0, "alcanza la velocidad máxima (150 px/s)")
	_soltar_movimiento()
	await _esperar(60)
	chequear(jugador.velocity.length() < 2.0, "frenado suave hasta detenerse (vel. = %.1f)" % jugador.velocity.length())

	print("\n[C] ANIMACIÓN DE CAMINAR (SpriteFrames)")
	_ubicar(Vector2(1, 0))
	await _esperar(3)
	Input.action_press("move_right", 1.0)
	await _esperar(5)
	chequear(String(sprite.animation) == "walk_right",
		"reproduce «walk_right» al moverse (actual: %s)" % sprite.animation)

	var fotograma_inicial := sprite.frame
	var avanzo := false
	for i in 20:
		await _esperar(1)
		if sprite.frame != fotograma_inicial:
			avanzo = true
	chequear(avanzo, "los fotogramas avanzan (ciclo = %.0f fps)" % (10.0 * sprite.speed_scale))
	chequear(sprite.speed_scale >= 1.0,
		"la velocidad del ciclo acompaña a la velocidad real (%.2fx)" % sprite.speed_scale)

	_soltar_movimiento()
	await _esperar(60)
	chequear(String(sprite.animation) == "idle_right",
		"vuelve a la animación en reposo (actual: %s)" % sprite.animation)

	print("\n[D] ESQUIVA (dash) + ENFRIAMIENTO")
	_ubicar(Vector2(1, 0))
	Input.action_press("move_right", 1.0)
	await _esperar(25)
	_ubicar(Vector2(1, 0))                       # tramo libre otra vez para el dash

	var med := await _esquivar_y_medir()
	chequear(float(med[0]) > 350.0,
		"la esquiva impulsa a %.0f px/s (normal: 150)" % float(med[0]))
	chequear(float(med[1]) > 1.15,
		"squash & stretch durante la esquiva (scale.x máx = %.2f)" % float(med[1]))

	await _esperar(23)                           # la esquiva dura ~0.22 s y luego frena
	chequear(jugador.velocity.length() <= 300.0,
		"la esquiva es limitada en el tiempo (vel. actual %.0f)" % jugador.velocity.length())
	chequear(not jugador.puede_esquivar(), "hay enfriamiento tras esquivar")

	var vel_sin_esquivar := await _velocidad_max_en(10)
	chequear(vel_sin_esquivar < 300.0, "esquivar dentro del enfriamiento NO vuelve a impulsar")

	await _esperar(65)                           # enfriamiento (0.22 + 0.65 s) superado
	chequear(jugador.puede_esquivar(), "el enfriamiento termina y vuelve a estar lista")
	_ubicar(Vector2(1, 0))
	var med2 := await _esquivar_y_medir()
	chequear(float(med2[0]) > 350.0,
		"segunda esquiva tras el enfriamiento: %.0f px/s" % float(med2[0]))
	_soltar_movimiento()

	print("\n[E] CÁMARA CON ANTICIPACIÓN")
	_ubicar(Vector2(1, 0))
	await _esperar(3)
	Input.action_press("move_right", 1.0)
	await _esperar(45)
	chequear(camara.offset.length() > 5.0, "la cámara se adelanta al moverse (offset = %.1f px)" % camara.offset.length())
	_soltar_movimiento()
	await _esperar(120)
	chequear(camara.offset.length() < 0.6, "la cámara vuelve al centro al detenerse (offset = %.2f)" % camara.offset.length())

	chequear(sprite.scale.distance_to(Vector2.ONE) < 0.05, "la escala del sprite se recupera al terminar")

	print("")
	if fallos.is_empty():
		print("RESULTADO: TODAS LAS PRUEBAS PASARON ✔")
		quit(0)
	else:
		print("RESULTADO: %d FALLO(S) ✘" % fallos.size())
		for f in fallos:
			print("  - ", f)
		quit(1)
