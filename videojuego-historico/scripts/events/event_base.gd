class_name EventBase
extends LevelBase
## Base de un evento/misión: coloca al jugador, arranca un temporizador y
## resuelve victoria/derrota. Las subclases (ej. Event1) definen la condición
## específica y qué hacer al ganar/perder (sobrescribiendo _on_win/_on_lose).

signal event_started
signal event_won
signal event_lost
signal time_updated(remaining: float)

@export var event_id: String = ""
@export var time_limit: float = 50.0

var time_remaining: float = 0.0
var is_active: bool = false

var _hud: HUD = null
var _timer_running: bool = false

func _ready() -> void:
	_hud = get_node_or_null("HUD") as HUD
	place_player_at_spawn()
	start_event()

func _process(delta: float) -> void:
	# En el editor (scripts @tool) el temporizador no debe correr.
	if Engine.is_editor_hint():
		return
	if not _timer_running:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_timer_running = false
		_emit_time()
		lose()
		return
	_emit_time()

func start_event() -> void:
	if is_active:
		return
	is_active = true
	time_remaining = time_limit
	_timer_running = true
	_emit_time()
	event_started.emit()

## Detiene el temporizador sin resolver el evento.
func stop_timer() -> void:
	_timer_running = false

func win() -> void:
	if not is_active:
		return
	is_active = false
	_timer_running = false
	event_won.emit()
	_on_win()

func lose() -> void:
	if not is_active:
		return
	is_active = false
	_timer_running = false
	event_lost.emit()
	_on_lose()

func _on_win() -> void:
	pass

func _on_lose() -> void:
	pass

func _emit_time() -> void:
	if _hud != null:
		_hud.set_time(time_remaining)
	time_updated.emit(time_remaining)

func _set_player_movable(movable: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.can_move = movable
