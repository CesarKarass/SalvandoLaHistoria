class_name DialogueLine
extends Resource
## Una línea individual de un diálogo. Al mostrarse puede activar una bandera global.

@export var speaker: String = ""
@export var portrait: Texture2D
@export_multiline var text: String = ""
## Bandera global opcional a activar al mostrar esta línea (ej. "is_hidalgo_saved").
@export var set_flag: String = ""
## Opciones de respuesta (se usan en el árbol de diálogo de la Fase 4/Evento 2).
@export var choices: Array[String] = []
