extends Control
## Menú de inicio de "Salvando la Historia".
##
## El bloque de menú (título + 4 botones + plato) se centra en pantalla y
## se escala según el lado corto del dispositivo, de modo que llena la
## pantalla de forma simétrica en cualquier resolución (móvil, tablet, PC).
##
## El fondo panorámico se dibuja a sangre sin deformarse (KEEP_ASPECT_COVERED).

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

var botones: Array[BotonMenu] = []
var escala := 1.0
var _escala_forzada := 0.0          # la usa el preview de captura


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

	if not botones.is_empty():
		# El primer botón arranca marcado, como en la referencia.
		botones[0].call_deferred("grab_focus")


func _ajustar_layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return

	var s := _escala_forzada
	if s <= 0.0:
		# Escala en múltiplos de 0.5 para que el pixel art se vea nítido.
		s = roundf(minf(vp.x, vp.y) * RELACION / BTN_ANCHO * 2.0) * 0.5
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
			print("[Menú] Continuar partida")
		"nuevo_juego":
			print("[Menú] Nuevo juego")
		"opciones":
			print("[Menú] Opciones")
		"salir":
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var foco := get_viewport().gui_get_focus_owner()
		if foco is BotonMenu:
			foco.activar_por_entrada()
			get_viewport().set_input_as_handled()


## Uso exclusivo del preview de captura.
func forzar_escala(valor: float) -> void:
	_escala_forzada = valor
	_ajustar_layout()
