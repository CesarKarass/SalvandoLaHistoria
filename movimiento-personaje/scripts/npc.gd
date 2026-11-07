extends StaticBody2D
## ---------------------------------------------------------------------------
## NPC INTERACTUABLE (Miguel Hidalgo, placeholder)
##
## Su StaticBody2D está en la capa 3 "interactuable":
##   · el jugador lo detecta con el Area2D "InteractArea" (máscara 4)
##   · además el jugador colisiona con él (máscara 5): no se atraviesa
##
## Al presionar "Interact" junto a él se muestra su diálogo en la UI.
## ---------------------------------------------------------------------------

## Texto del bocadillo al interactuar.
@export var dialogue_text: String = "¡Joven! Nadie cruza la plaza mientras el tiempo corre..."


func interact() -> void:
	var label := get_tree().get_first_node_in_group("dialogue") as Label
	if label == null:
		return
	label.text = dialogue_text
	_clear_dialogue_after(label, 4.0)


func _clear_dialogue_after(label: Label, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	# Solo borra si el jugador no ha hablado con otro NPC en el medio.
	if is_instance_valid(label) and label.text == dialogue_text:
		label.text = ""
