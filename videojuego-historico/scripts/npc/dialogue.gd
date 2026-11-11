class_name Dialogue
extends Resource
## Diálogo completo de un NPC: nombre, retrato por defecto y lista de líneas.

@export var npc_name: String = ""
@export var portrait: Texture2D
@export var lines: Array[DialogueLine] = []
