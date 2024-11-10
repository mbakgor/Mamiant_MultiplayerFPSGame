extends Node3D

@onready var lobby_menu: Control = $CanvasLayer/LobbyMenu


@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var spawn_1: Marker3D = $Spawn_1
@onready var spawn_2: Marker3D = $Spawn_2

@onready var team_1_label: RichTextLabel = $CanvasLayer/LobbyMenu/Lobby/Players2/Team1Label
@onready var team_2_label: RichTextLabel = $CanvasLayer/LobbyMenu/Lobby/Players3/Team2Label


const Player = preload("res://player.tscn")
const PORT = 9999

var players = []
var player_template  = { "id" :0 ,
						 "team_number": 0 }


func _ready():
	$MultiplayerSpawner.set_spawn_function(my_spawn)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()


func add_player(peer_id, team_number):
	if get_node_or_null(str(peer_id)) != null: return
	print("asd")
	var spawn_pos = spawn_1.global_position
	if team_number == 2:
		spawn_pos = spawn_2.global_position

	$MultiplayerSpawner.spawn( {"peer_id":peer_id,  "spawn_pos":spawn_pos } )
	 
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func my_spawn(data:Dictionary) -> Node:
	var player = Player.instantiate()
	player.name = str(data.peer_id)
	player.respawn_point = data.spawn_pos
	print("Spawning player with name:", player.name)

	call_deferred("set_player_position", player, data.spawn_pos)
	
	return player

func set_player_position(player: Node3D, spawn_pos: Vector3) -> void:
	if player.is_inside_tree():
		player.global_position = spawn_pos


func _on_join_team_1_pressed() -> void:
	_add_player_to_teams.rpc(multiplayer.get_unique_id(), 1)


func _on_join_team_2_pressed() -> void:
	_add_player_to_teams.rpc(multiplayer.get_unique_id(), 2)

func _on_start_pressed() -> void:
	for player in players:
		add_player(player["id"], player["team_number"])
	close_menu.rpc()

@rpc("call_local")
func close_menu():
	lobby_menu.hide()


@rpc("any_peer","reliable","call_local")
func _add_player_to_teams(id: int, team_number: int):
	var text = str(id) + "\n"
	if team_number == 1:
		team_1_label.add_text(text)
	elif team_number == 2:
		team_2_label.add_text(text)
	
	var new_player = player_template.duplicate()
	new_player["id"] = id
	new_player["team_number"] = team_number
	players.append(new_player)

		


