class_name DialogueLine
extends Resource
## Una línea individual de un diálogo. Al mostrarse puede activar una bandera global.

@export var speaker: String = ""
@export var portrait: Texture2D
@export_multiline var text: String = ""
## Bandera global opcional a activar al mostrar esta línea (ej. "is_hidalgo_saved").
@export var set_flag: String = ""
## Índice de la línea a la que salta esta línea al avanzar.
## -1 = siguiente línea del array; < -1 = terminar el diálogo.
@export var next_line: int = -1
## Opciones de respuesta: si no está vacía, la línea espera a que el jugador
## elija una alternativa (estado CHOOSING) antes de saltar a su `next_line`.
@export var choices: Array[DialogueChoice] = []
