extends Node
## Genera previews del menú real de Godot a distintas resoluciones de
## dispositivo, más una tira con los 3 estados del botón.
##
## Uso:
##   flatpak run org.godotengine.Godot --path <proyecto> res://preview/captura.tscn
## o con el binario local:
##   godot --path <proyecto> res://preview/captura.tscn
##
## Las imágenes quedan en preview/salidas/.

const SALIDA := "res://preview/salidas/"

## Resoluciones de dispositivo (todas apaisadas, como pediste).
const RESOLUCIONES: Array[Vector2i] = [
	Vector2i(1280, 720),    # HD pequeño / celular apaisado
	Vector2i(1920, 1080),   # Full HD
	Vector2i(2400, 1080),   # celular 20:9 (pantalla muy ancha)
	Vector2i(2560, 1600),   # tablet 16:10
	Vector2i(1080, 1920),   # retrato, para comprobar que también se adapta
]

const ESCALA_CIERRE := 3.0
const VP_CIERRE := Vector2i(560, 560)

@onready var contenedor: SubViewportContainer = $Contenedor
@onready var viewport: SubViewport = $Contenedor/Viewport
@onready var menu: Control = $Contenedor/Viewport/MenuInicio


func _ready() -> void:
	await _frames(4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))

	# Sin hover para que el foco quede siempre donde lo decidimos.
	for b in menu.botones:
		b.permitir_hover = false
	menu.botones[0].grab_focus()

	for res in RESOLUCIONES:
		contenedor.size = res
		await _frames(5)
		var img := viewport.get_texture().get_image()
		img.save_png("%smenu_%dx%d.png" % [SALIDA, res.x, res.y])
		print("[Preview] capturado %dx%d" % [res.x, res.y])

	await _capturar_estados()

	print("[Preview] LISTO -> ", SALIDA)
	get_tree().quit()


## Tira con los tres estados del botón CONTINUAR.
func _capturar_estados() -> void:
	var boton: BotonMenu = menu.botones[0]
	menu.botones[1].release_focus()
	boton.release_focus()
	menu.forzar_escala(ESCALA_CIERRE)
	contenedor.size = VP_CIERRE
	await _frames(5)

	# 1) normal (sin viñeta)
	boton.forzar_estado(false, false)
	await _frames(20)   # deja que la escala vuelva a 1.0
	# Encuadre fijo: los tres estados se recortan igual para que se note
	# el cambio de tamaño entre uno y otro.
	var rect_base: Rect2i = boton.get_global_rect().grow(20)
	rect_base = rect_base.intersection(Rect2i(Vector2i.ZERO, Vector2i(viewport.size)))
	_guardar_corte(rect_base, "estado_1_normal.png")

	# 2) marcado / enfocado (viñeta completa, sin pulso)
	boton.congelar_pulso = true
	boton.forzar_estado(true, false)
	await _frames(14)   # deja terminar el fundido de la viñeta
	_guardar_corte(rect_base, "estado_2_marcado.png")

	# 3) presionado (gris + encogido)
	boton.forzar_estado(true, true)
	await _frames(14)   # deja terminar el encogido
	_guardar_corte(rect_base, "estado_3_presionado.png")

	boton.congelar_pulso = false
	boton.forzar_estado(false, false)
	menu.forzar_escala(0.0)


func _guardar_corte(rect: Rect2i, nombre: String) -> void:
	var img := viewport.get_texture().get_image().get_region(rect)
	img.save_png(SALIDA + nombre)
	print("[Preview] ", nombre, " ", rect)


func _frames(cantidad: int) -> void:
	for i in cantidad:
		await get_tree().process_frame
