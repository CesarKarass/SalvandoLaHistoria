extends CanvasLayer
## Menú de inicio v0.2 de "Salvando la Historia".
##
## Reconstruido con los assets de res://resources/menuv0.2/png (fondo, título,
## textos de botón y viñetas en capas separadas, todo editable en el editor).
## El bloque de menú (título + 4 botones + plato) se ancla abajo a la izquierda
## y se escala según el lado corto de la pantalla, igual que en el proyecto de
## referencia resources/menuv0.2/menu_inicio_godot.
##
## El fondo panorámico se dibuja a sangre sin deformarse (KEEP_ASPECT_COVERED)
## y la música del menú suena en bucle para que la primera pantalla nunca
## quede en silencio.

const OVERWORLD := "res://scenes/overworld/overworld.tscn"
const OPTIONS := "res://scenes/ui/options_menu.tscn"

const BTN_ANCHO := 120.0
const COL_ANCHO := 132.0            # ancho base del bloque (platos de los botones)
const COL_ALTO := 185.0             # 41 (título) + 14 + 4*28 (platos) + 3*6 (huecos)
const RELACION := 0.40              # el botón ocupa ~40% del lado corto
const ESCALA_MIN := 1.0
const ESCALA_MAX := 6.0
const MARGEN_IZQ := 0.05            # 5% del ancho de pantalla
const MARGEN_ABAJO := 0.07          # 7% del alto de pantalla

@onready var columna: Control = $Columna
@onready var vigneta: TextureRect = $Vigneta
@onready var oscurecer_izq: TextureRect = $OscurecerIzq
@onready var musica: AudioStreamPlayer = $MusicaMenu

var botones: Array[BotonMenu] = []
var escala := 1.0


func _ready() -> void:
	botones.clear()
	for hijo in columna.get_children():
		if hijo is BotonMenu:
			botones.append(hijo)
			hijo.activado.connect(_on_boton_activado)

	_crear_vigneta()
	_crear_oscurecer_izquierdo()
	get_viewport().size_changed.connect(_ajustar_layout)
	_ajustar_layout()

	# La música del menú suena en bucle para que la primera pantalla nunca
	# quede en silencio. Solo se reproduce si hay salida de audio real: en
	# modo headless (tests/CI) no hay driver de audio y el stream quedaría
	# vivo al cerrar el proceso.
	if musica != null and musica.stream != null and not musica.playing \
			and DisplayServer.get_name() != "headless":
		musica.play()

	if not botones.is_empty():
		# El primer botón arranca marcado, como en la referencia.
		botones[0].call_deferred("grab_focus")


func _ajustar_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return

	# Escala en múltiplos de 0.5 para que el pixel art se vea nítido.
	var s := roundf(minf(vp.x, vp.y) * RELACION / BTN_ANCHO * 2.0) * 0.5
	s = clampf(s, ESCALA_MIN, ESCALA_MAX)
	escala = s

	var visual := Vector2(COL_ANCHO, COL_ALTO) * s
	columna.scale = Vector2(s, s)
	# Anclado abajo a la izquierda, con márgenes proporcionales a la pantalla.
	var y := vp.y - vp.y * MARGEN_ABAJO - visual.y
	y = maxf(y, vp.y * 0.04)
	columna.position = Vector2(
		roundf(vp.x * MARGEN_IZQ),
		roundf(y)
	)


## Viñeta radial suave (bordes oscuros) para dar profundidad al fondo.
func _crear_vigneta() -> void:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gradiente.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.10),
		Color(0.0, 0.0, 0.0, 0.55),
	])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 512
	textura.height = 512
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(0.5, 0.0)
	vigneta.texture = textura
	vigneta.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## Degradado suave desde el borde izquierdo: oscurece la zona donde vive el
## menú para que el título y los botones se lean sobre el atardecer, sin usar
## una caja (se ve como la caída de la luz del atardecer).
func _crear_oscurecer_izquierdo() -> void:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.55])
	gradiente.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.44),
		Color(0.0, 0.0, 0.0, 0.0),
	])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 256
	textura.height = 8
	textura.fill = GradientTexture2D.FILL_LINEAR
	textura.fill_from = Vector2(0.0, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	oscurecer_izq.texture = textura
	oscurecer_izq.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _on_boton_activado(id: String) -> void:
	match id:
		"continuar":
			# Retoma la partida en curso sin reiniciar el progreso.
			SceneTransition.change_scene(OVERWORLD, "")
		"nuevo_juego":
			GameManager.reset_progress()
			Inventory.clear()
			SceneTransition.change_scene(OVERWORLD, "")
		"opciones":
			var opts: PackedScene = load(OPTIONS)
			if opts != null:
				add_child(opts.instantiate())
		"salir":
			_detener_musica()
			get_tree().quit()


## Detiene la música del menú. Se hace al salir de la escena y justo antes de
## cerrar el programa, para no dejar el stream de audio vivo al terminar.
func _detener_musica() -> void:
	if musica != null:
		musica.stop()


func _notification(what: int) -> void:
	# Cierre de la ventana (X): paramos la música antes de que Godot termine.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_detener_musica()


func _exit_tree() -> void:
	_detener_musica()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var foco := get_viewport().gui_get_focus_owner()
		if foco is BotonMenu:
			foco.activar_por_entrada()
			get_viewport().set_input_as_handled()
