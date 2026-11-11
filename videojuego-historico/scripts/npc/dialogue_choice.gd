class_name DialogueChoice
extends Resource
## Una alternativa de respuesta dentro de una línea con opciones múltiples.

## Texto de la opción que se muestra en el bocadillo.
@export var text: String = ""
## Índice de la línea a la que salta al elegir esta opción.
## -1 = continuar en la siguiente línea del array; < -1 = terminar el diálogo.
@export var next_line: int = -1
## Bandera global opcional a activar al elegir esta opción (ej. "chose_bolsa").
@export var set_flag: String = ""
