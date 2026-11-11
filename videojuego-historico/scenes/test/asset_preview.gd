extends Node2D
## Escena de prueba de assets: una sala con tiles reales (suelo/muro), el jugador
## con sprites reales e Hidalgo. Ábrela en Godot y pulsa F6 para verla.

const COLS := 20
const ROWS := 12

func _ready() -> void:
	TileWorld.build_room(self, COLS, ROWS)
	_spawn_actors()
	TileWorld.clamp_camera(get_tree().get_first_node_in_group("player"), COLS, ROWS)

func _spawn_actors() -> void:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	add_child(player)
	player.global_position = Vector2(520, 384)

	var npc: NPC = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as NPC
	add_child(npc)
	npc.global_position = Vector2(900, 384)
	npc.dialogue = load("res://resources/dialogues/hidalgo_intro.tres") as Dialogue
