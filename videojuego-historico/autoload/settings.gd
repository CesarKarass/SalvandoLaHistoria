extends Node
## Settings — opciones persistentes (volumen y pantalla completa).
## Guarda en user://settings.cfg y aplica sobre AudioServer / DisplayServer.

const SETTINGS_PATH := "user://settings.cfg"

var master_volume: int = 100
var music_volume: int = 80
var sfx_volume: int = 80
var fullscreen: bool = false

func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply_settings()

func set_master_volume(v: int) -> void:
	master_volume = clampi(v, 0, 100)
	apply_settings()
	save_settings()

func set_music_volume(v: int) -> void:
	music_volume = clampi(v, 0, 100)
	apply_settings()
	save_settings()

func set_sfx_volume(v: int) -> void:
	sfx_volume = clampi(v, 0, 100)
	apply_settings()
	save_settings()

func set_fullscreen(v: bool) -> void:
	fullscreen = v
	apply_settings()
	save_settings()

func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	if _is_mobile():
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")

func _set_bus_volume(bus_name: String, volume: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var linear := maxf(float(volume) / 100.0, 0.0001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func _is_mobile() -> bool:
	var display := DisplayServer.get_name()
	return display == "headless" or OS.get_name() == "Android" or OS.get_name() == "iOS"

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	master_volume = int(cf.get_value("audio", "master_volume", master_volume))
	music_volume = int(cf.get_value("audio", "music_volume", music_volume))
	sfx_volume = int(cf.get_value("audio", "sfx_volume", sfx_volume))
	fullscreen = bool(cf.get_value("display", "fullscreen", fullscreen))

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master_volume", master_volume)
	cf.set_value("audio", "music_volume", music_volume)
	cf.set_value("audio", "sfx_volume", sfx_volume)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.save(SETTINGS_PATH)
