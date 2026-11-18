extends Control
class_name BotonMenu
## Botón del menú principal construido con los assets de Pixelorama de
## res://resources/menuv0.2/png (texto y viñetas en capas separadas).
##
## Estados visuales:
##   NORMAL     -> texto dorado (asset amarillo).
##   ENFOCADO   -> aparece la viñeta (flechas) deslizándose desde fuera,
##                 con un pulso suave para indicar que está "marcado".
##   PULSADO    -> texto en asset gris + viñeta en gris y animación de
##                 encogido alrededor del centro.
##
## Toda la animación es interna del botón; el padre (Columna) se encarga
## de la escala global según el tamaño de pantalla. Al ser un Control con
## foco, funciona igual con ratón, teclado y táctil (móvil).

signal activado(id: String)

const ANCHO := 132.0                # plato del botón (textura + 6 px de lado)
const ALTO := 28.0                  # textura (24) + 2 px arriba/abajo
const TEX_ORIGEN := Vector2(6.0, 2.0)  # dónde se dibuja la textura de 120x24
const TEX_ANCHO := 120.0
const TEX_METADE := 60.0            # las viñetas se dibujan en dos mitades
const DUR_VINIETA := 0.16           # segundos en aparecer/desaparecer
const K_PRESIONADO := 0.88          # escala al presionar
const K_ENFOCADO := 1.05            # escala al estar marcado
const SUAVIDAD := 22.0

const PLATO_NORMAL := Color(0.06, 0.03, 0.02, 0.76)
const PLATO_MARCADO := Color(0.10, 0.05, 0.03, 0.88)
const BORDE_PLATO := Color(0.788, 0.635, 0.29, 0.5)

const CARPETA_ASSETS := "res://resources/menuv0.2/png/"

@export var id_boton: String = "continuar"

var _tex_normal: Texture2D
var _tex_pulsado: Texture2D
var _vin_izq_normal: Texture2D
var _vin_der_normal: Texture2D
var _vin_izq_pulsado: Texture2D
var _vin_der_pulsado: Texture2D

var _pos_base := Vector2.ZERO
var _enfocado := false
var _pulsado := false
var _animando_activacion := false
var _vineta := 0.0                  # progreso 0..1 de la viñeta
var _k := 1.0                       # escala actual
var _t := 0.0                       # tiempo para el pulso
var _plato_a := PLATO_NORMAL.a      # alpha del plato trasero


func _ready() -> void:
	_pos_base = position
	size = Vector2(ANCHO, ALTO)
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_tex_normal = load(CARPETA_ASSETS + "texto_%s_amarillo.png" % id_boton)
	_tex_pulsado = load(CARPETA_ASSETS + "texto_%s_gris.png" % id_boton)
	_vin_izq_normal = load(CARPETA_ASSETS + "vineta_amarilla_izq.png")
	_vin_der_normal = load(CARPETA_ASSETS + "vineta_amarilla_der.png")
	_vin_izq_pulsado = load(CARPETA_ASSETS + "vineta_gris_izq.png")
	_vin_der_pulsado = load(CARPETA_ASSETS + "vineta_gris_der.png")

	focus_entered.connect(_al_enfocar)
	focus_exited.connect(_al_desenfocar)
	mouse_entered.connect(_al_pasar_el_puntero)


func _process(delta: float) -> void:
	_t += delta

	# --- viñeta: entra/sale con fundido ---
	var objetivo_vin := 1.0 if _enfocado else 0.0
	_vineta = move_toward(_vineta, objetivo_vin, delta / DUR_VINIETA)

	# --- escala: presionado > enfocado > normal ---
	var objetivo_k := 1.0
	if _pulsado:
		objetivo_k = K_PRESIONADO
	elif _enfocado:
		objetivo_k = K_ENFOCADO
	_k = lerpf(_k, objetivo_k, 1.0 - exp(-delta * SUAVIDAD))

	# --- el plato trasero se aclara un poco cuando el botón está marcado ---
	var plato_objetivo := PLATO_MARCADO if _enfocado else PLATO_NORMAL
	_plato_a = lerpf(_plato_a, plato_objetivo.a, 1.0 - exp(-delta * SUAVIDAD))

	# Se mantiene el centro del botón fijo al encoger/crecer.
	scale = Vector2(_k, _k)
	position = _pos_base + (size * (1.0 - _k)) * 0.5

	queue_redraw()


func _draw() -> void:
	# Plato propio de cada botón (como en la referencia).
	var c_plato := Color(PLATO_NORMAL.r, PLATO_NORMAL.g, PLATO_NORMAL.b, _plato_a)
	draw_rect(Rect2(Vector2.ZERO, size), c_plato)
	draw_rect(Rect2(Vector2.ZERO, size), BORDE_PLATO, false, 1.0)

	var tex := _tex_pulsado if _pulsado else _tex_normal
	if tex != null:
		draw_texture(tex, TEX_ORIGEN)

	if _vineta <= 0.004:
		return

	# Opacidad: fundido + pulso suave cuando está marcado.
	var alfa := _vineta
	if _enfocado and _vineta >= 0.999:
		alfa = 0.70 + 0.30 * (0.5 + 0.5 * sin(_t * TAU * 0.5))

	# Las flechas entran deslizándose desde fuera del botón.
	var desfase := (1.0 - _vineta) * 8.0
	var izq := _vin_izq_pulsado if _pulsado else _vin_izq_normal
	var der := _vin_der_pulsado if _pulsado else _vin_der_normal
	var color := Color(1.0, 1.0, 1.0, alfa)
	if izq != null:
		draw_texture(izq, TEX_ORIGEN + Vector2(-desfase, 0.0), color)
	if der != null:
		draw_texture(der, TEX_ORIGEN + Vector2(TEX_METADE + desfase, 0.0), color)


# ---------------------------------------------------------------------------
# Entrada (ratón / táctil con emulación de ratón)
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not has_focus():
				grab_focus()
			_pulsado = true
		elif _pulsado:
			var dentro := get_global_rect().has_point(event.global_position)
			_pulsado = false
			if dentro:
				activar_por_entrada()
	elif event is InputEventMouseMotion and _pulsado:
		# Se arrastró fuera del botón: se cancela la pulsación.
		if not get_global_rect().has_point(event.global_position):
			_pulsado = false


func _al_enfocar() -> void:
	_enfocado = true


func _al_desenfocar() -> void:
	_enfocado = false
	_pulsado = false


func _al_pasar_el_puntero() -> void:
	# En escritorio el hover también marca el botón (en táctil no existe hover).
	if not has_focus():
		grab_focus()


## Activación con teclado / gamepad (ui_accept): muestra la animación de
## pulsación y luego emite la señal.
func activar_por_entrada() -> void:
	if _animando_activacion:
		return
	_animando_activacion = true
	_pulsado = true
	await get_tree().create_timer(0.12).timeout
	_pulsado = false
	_animando_activacion = false
	activado.emit(id_boton)
