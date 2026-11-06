extends SceneTree
## ---------------------------------------------------------------------------
## HERRAMIENTA (no es parte del juego): crea assets/jugador_sprites.tres
## con las 16 animaciones (8 direcciones x quieto/caminar) a partir de la
## hoja de sprites assets/jugador_sheet.png.
##
## Se ejecuta desde terminal:
##   godot --headless --path . --script res://tools/crear_spriteframes.gd
##
## Es un ejemplo práctico de GDScript: constantes, bucles, creación de
## recursos desde código y uso de la API de Godot (SpriteFrames, AtlasTexture).
## ---------------------------------------------------------------------------

const HOJA := "res://assets/jugador_sheet.png"
const SALIDA := "res://assets/jugador_sprites.tres"
const CELDA := 64.0

## Mismo orden que Jugador.indice_8_direcciones():
const NOMBRES: Array[String] = [
	"right", "down_right", "down", "down_left",
	"left", "up_left", "up", "up_right",
]


func _initialize() -> void:
	var hoja: Texture2D = load(HOJA)
	if hoja == null:
		push_error("No se pudo cargar " + HOJA)
		quit(1)
		return

	var sprites := SpriteFrames.new()

	for indice in NOMBRES.size():
		_crear_animacion(sprites, hoja, indice, "idle", [0], 1.0)
		_crear_animacion(sprites, hoja, indice, "walk", [1, 2, 3, 4], 10.0)

	var error := ResourceSaver.save(sprites, SALIDA)
	print("Recurso guardado en %s -> error = %s (0 = OK)" % [SALIDA, error])
	quit(0 if error == OK else 1)


## Crea una animación recortando la hoja con AtlasTexture.
func _crear_animacion(sprites: SpriteFrames, hoja: Texture2D, indice: int,
		prefijo: String, columnas: Array, velocidad: float) -> void:

	var nombre := "%s_%s" % [prefijo, NOMBRES[indice]]

	if not sprites.has_animation(nombre):
		sprites.add_animation(nombre)
	sprites.set_animation_loop(nombre, true)
	sprites.set_animation_speed(nombre, velocidad)

	for columna in columnas:
		var recorte := AtlasTexture.new()     # "sub-imagen" dentro de la hoja
		recorte.atlas = hoja
		recorte.region = Rect2(float(columna) * CELDA, float(indice) * CELDA, CELDA, CELDA)
		sprites.add_frame(nombre, recorte)    # posición -1 = añadir al final
