extends Node
## DialogueManager — controla el bocadillo de diálogo (autoload).
## Estado: IDLE (sin diálogo) → TYPING (escribiendo línea) → WAITING (esperando avanzar).

signal dialogue_started(dialogue: Dialogue)
signal dialogue_finished

enum State { IDLE, TYPING, WAITING }

var state: State = State.IDLE

var _dialogue: Dialogue
var _line_index: int = 0
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

## Avanza el diálogo: si se está tecleando, completa la línea; si no, pasa a la siguiente.
func advance() -> void:
	if state == State.TYPING:
		_box.complete_line()
		state = State.WAITING
	elif state == State.WAITING:
		if _line_index + 1 < _dialogue.lines.size():
			_line_index += 1
			_show_current_line()
		else:
			_finish()

func _process(_delta: float) -> void:
	if state == State.IDLE:
		return
	# Evita que la misma pulsación que abrió el diálogo lo avance en el mismo frame.
	if Engine.get_process_frames() == _start_frame:
		return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("interact"):
		advance()

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
		state = State.WAITING

func _finish() -> void:
	_box.close()
	state = State.IDLE
	_set_player_movable(true)
	dialogue_finished.emit()

func _set_player_movable(movable: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.can_move = movable
