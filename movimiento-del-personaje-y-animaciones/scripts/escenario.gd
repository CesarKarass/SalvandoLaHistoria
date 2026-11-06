extends Node2D
## Construye el escenario cenital a partir de un "plano" ASCII exportado.
##
## Cada carácter del plano = una celda de 64 x 64 px (la medida de los bloques
## que define el GDD para los escenarios de eventos).
##
##   #  muro / cantera   -> StaticBody2D con hitbox (colisión)
##   B  edificio adobe   -> StaticBody2D con hitbox (colisión)
##   b  barricada/mueble -> StaticBody2D con hitbox (colisión)
##   c  decoración       -> Polygon2D sin cuerpo (SIN colisión)
##   .  suelo            -> espacio recorrible

const TAM_BLOQUE: int = 64
const ESCENA_BLOQUE: PackedScene = preload("res://scenes/bloque.tscn")

const PALETA := {
	"#": Color("6f6a63"),  # Stone Grey (muro de cantera)
	"B": Color("b5623c"),  # Terracotta (adobe)
	"b": Color("7d7048"),  # Olive Green (mobiliario / barricada)
}
const COLOR_DECORACION := Color("f2a03d")  # Cempasúchil Orange (sin colisión)

## Plano del escenario, una cadena por fila (16 filas x 16 celdas = 1024 px).
@export var plano: PackedStringArray = PackedStringArray()

@onready var _bloques: Node2D = $Bloques
@onready var _decoracion: Node2D = $Decoracion
@onready var _jugador: Jugador = $Jugador
@onready var _aviso: Label = $HUD/Aviso

var _aviso_restante: float = 0.0


func _ready() -> void:
	_validar_plano()
	_construir_escenario()
	_configurar_camara()
	_jugador.interactuar.connect(_al_interactuar)


func _process(delta: float) -> void:
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		if _aviso_restante <= 0.0:
			_aviso.text = ""


## El jugador emitió la señal "interactuar" dentro de una zona de evento.
func _al_interactuar(zona: Node) -> void:
	var texto := "Zona de interacción activada."
	if zona.has_method("obtener_mensaje"):
		texto = zona.obtener_mensaje()
	_aviso.text = texto
	_aviso_restante = 4.0
	print("[Evento] ", texto)


func _validar_plano() -> void:
	if plano.is_empty():
		push_warning("El escenario no tiene plano definido.")
		return
	var ancho: int = plano[0].length()
	for fila in plano.size():
		if plano[fila].length() != ancho:
			push_warning("Fila %d con longitud %d (se esperaba %d)." % [fila, plano[fila].length(), ancho])


func _construir_escenario() -> void:
	for fila in plano.size():
		var texto: String = plano[fila]
		for columna in texto.length():
			var caracter: String = texto[columna]
			var centro := Vector2(
				columna * TAM_BLOQUE + TAM_BLOQUE * 0.5,
				fila * TAM_BLOQUE + TAM_BLOQUE * 0.5
			)

			if PALETA.has(caracter):
				_crear_bloque_solido(centro, PALETA[caracter])
			elif caracter == "c":
				_crear_decoracion(centro)


## Crea un StaticBody2D (hitbox 64x64) que el jugador no podrá atravesar.
func _crear_bloque_solido(centro: Vector2, color: Color) -> void:
	var bloque: Node2D = ESCENA_BLOQUE.instantiate()
	bloque.position = centro
	bloque.get_node("Visual").color = color
	bloque.get_node("BordeSuperior").color = color.lightened(0.22)
	_bloques.add_child(bloque)


## Decoración que solo dibuja: NO genera colisión.
func _crear_decoracion(centro: Vector2) -> void:
	var rombo := Polygon2D.new()
	rombo.polygon = PackedVector2Array([
		centro + Vector2(-22, 0),
		centro + Vector2(0, -22),
		centro + Vector2(22, 0),
		centro + Vector2(0, 22),
	])
	rombo.color = COLOR_DECORACION
	_decoracion.add_child(rombo)


func _configurar_camara() -> void:
	var camara := _jugador.get_node_or_null("Camara") as Camera2D
	if camara == null:
		return
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = TAM_BLOQUE * plano[0].length()
	camara.limit_bottom = TAM_BLOQUE * plano.size()


## Ancho y alto del escenario en píxeles (útil para los límites de la cámara).
func tamano_escenario() -> Vector2:
	return Vector2(TAM_BLOQUE * plano[0].length(), TAM_BLOQUE * plano.size())
