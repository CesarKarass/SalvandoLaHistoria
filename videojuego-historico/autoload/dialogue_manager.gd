extends Node
## DialogueManager — controla el bocadillo de diálogo (autoload).
## Estado: IDLE (sin diálogo) → TYPING (escribiendo línea) → WAITING (esperando
## avanzar) → CHOOSING (esperando elegir una alternativa cuando la línea tiene
## `choices`). Las ramas se resuelven con `next_line` (línea y por opción).

signal dialogue_started(dialogue: Dialogue)
signal dialogue_finished

enum State { IDLE, TYPING, WAITING, CHOOSING }

var state: State = State.IDLE

var _dialogue: Dialogue
var _line_index: int = 0
var _choice_index: int = 0
## Alternativas ya usadas: clave "recurso:línea:opción" → true.
## Persiste mientras dure la sesión para mostrarlas en gris.
var _used_choices: Dictionary = {}
var _box: DialogueBox
var _start_frame: int = -1

func _ready() -> void:
	var box_scene := load("res://scenes/ui/dialogue_box.tscn") as PackedScene
	_box = box_scene.instantiate() as DialogueBox
	_box.line_typed.connect(_on_line_typed)
	add_child(_box)

func start(dialogue: Dialogue) -> void:
	if dialogue == null or state != State.IDLE:
		return
	_dialogue = dialogue
	_line_index = 0
	_box.open()
	_show_current_line()
	_set_player_movable(false)
	_start_frame = Engine.get_process_frames()
	dialogue_started.emit(dialogue)

## Avanza el diálogo: si se está tecleando, completa la línea; si no, pasa a la
## siguiente (o salta/termina según `next_line`). En CHOOSING no hace nada.
func advance() -> void:
	if state == State.TYPING:
		_box.complete_line()
		_enter_waiting_or_choosing()
	elif state == State.WAITING:
		var next := _next_line_index()
		if next >= 0:
			_line_index = next
			_show_current_line()
		else:
			_finish()

func _process(_delta: float) -> void:
	if state == State.IDLE:
		return
	# Evita que la misma pulsación que abrió el diálogo lo avance en el mismo frame.
	if Engine.get_process_frames() == _start_frame:
		return
	if state == State.CHOOSING:
		_handle_choice_input()
		return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("interact"):
		advance()

## Tras teclear una línea: si tiene alternativas pasa a CHOOSING, si no a WAITING.
func _enter_waiting_or_choosing() -> void:
	var line: DialogueLine = _dialogue.lines[_line_index]
	if line.choices.size() > 0:
		state = State.CHOOSING
		_choice_index = 0
		var texts: Array[String] = []
		var used: Array[bool] = []
		for i: int in line.choices.size():
			texts.append(line.choices[i].text)
			used.append(_used_choices.has(_choice_key(_line_index, i)))
		_box.show_choices(texts, 0, used)
	else:
		state = State.WAITING

## Navegación y selección de las alternativas (flechas/W-S, Enter/E y 1-4).
func _handle_choice_input() -> void:
	var line: DialogueLine = _dialogue.lines[_line_index]
	var count: int = line.choices.size()
	if count == 0:
		return
	var moved := false
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
		_choice_index = wrapi(_choice_index - 1, 0, count)
		moved = true
	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down"):
		_choice_index = wrapi(_choice_index + 1, 0, count)
		moved = true
	if moved:
		_box.set_selected_choice(_choice_index)
		return
	for i: int in mini(count, 4):
		if Input.is_action_just_pressed("quick_%d" % (i + 1)):
			_select_choice(i)
			return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("interact"):
		_select_choice(_choice_index)

## Selección pública de una alternativa (clic/tap sobre la opción, desde la UI).
## Solo válida mientras se está eligiendo.
func choose(index: int) -> void:
	if state != State.CHOOSING:
		return
	_select_choice(index)

## Aplica la alternativa elegida: la marca como usada (se mostrará en gris),
## activa su bandera y salta a su línea.
func _select_choice(index: int) -> void:
	var line: DialogueLine = _dialogue.lines[_line_index]
	if index < 0 or index >= line.choices.size():
		return
	var choice: DialogueChoice = line.choices[index]
	_used_choices[_choice_key(_line_index, index)] = true
	_box.hide_choices()
	if choice.set_flag != "":
		GameManager.set_flag(choice.set_flag)
	var next := choice.next_line
	if next == -1:
		next = _line_index + 1
	if next >= 0 and next < _dialogue.lines.size():
		_line_index = next
		_show_current_line()
	else:
		_finish()

## Clave estable de una alternativa dentro de un diálogo (para el registro
## de usadas): identidad del recurso + línea + índice de opción.
func _choice_key(line_index: int, choice_index: int) -> String:
	var dlg_id: String = _dialogue.resource_path
	if dlg_id == "":
		dlg_id = str(_dialogue.get_instance_id())
	return dlg_id + ":" + str(line_index) + ":" + str(choice_index)

## Índice de la línea siguiente al avanzar en WAITING (respeta `next_line`).
func _next_line_index() -> int:
	var line: DialogueLine = _dialogue.lines[_line_index]
	if line.next_line >= 0 and line.next_line < _dialogue.lines.size():
		return line.next_line
	if line.next_line < -1:
		return -1  # fin explícito del diálogo
	var nxt := _line_index + 1
	return nxt if nxt < _dialogue.lines.size() else -1

func _show_current_line() -> void:
	var line: DialogueLine = _dialogue.lines[_line_index]
	if line.set_flag != "":
		GameManager.set_flag(line.set_flag)
	var speaker: String = line.speaker if line.speaker != "" else _dialogue.npc_name
	var portrait: Texture2D = line.portrait if line.portrait != null else _dialogue.portrait
	_box.show_line(speaker, portrait, line.text)
	state = State.TYPING

func _on_line_typed() -> void:
	if state == State.TYPING:
		_enter_waiting_or_choosing()

func _finish() -> void:
	_box.hide_choices()
	_box.close()
	state = State.IDLE
	_set_player_movable(true)
	dialogue_finished.emit()

func _set_player_movable(movable: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.can_move = movable
