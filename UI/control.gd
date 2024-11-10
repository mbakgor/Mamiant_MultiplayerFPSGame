extends Control

const PORT = 9999
const DEFAULT_SERVER_IP = "localhost"

var lobby_name: String
var players = {}
var lobbies = {}
var player_info = {"name": "Name"}

@onready var main: Control = $Main
@onready var lobby: Control = $Lobby

@onready var join_team_1: Button = $Lobby/JoinTeam1
@onready var join_team_2: Button = $Lobby/JoinTeam2
@onready var line_edit: LineEdit = $Lobby/LineEdit

@onready var player_list_label: RichTextLabel = $Lobby/Players/PlayerListLabel
@onready var team_1_label: RichTextLabel = $Lobby/Players2/Team1Label
@onready var team_2_label: RichTextLabel = $Lobby/Players3/Team2Label

@onready var host: Button = $Main/Host
@onready var client: Button = $Main/Client

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_pressed():
	main.hide()
	lobby.show()
	
	var enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(PORT)
	if error != OK:
		return error
	
	multiplayer.multiplayer_peer = enet_peer
	var id = multiplayer.get_unique_id()
	players[id] = player_info
	player_list_label.add_text(str(id))

func _on_client_pressed():
	main.hide()
	lobby.show()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	
	if error != OK:
		return error
	
	multiplayer.multiplayer_peer = peer
	# Wait for connected_to_server signal before proceeding

func _on_connected_ok():
	var id = multiplayer.get_unique_id()
	players[id] = player_info
	player_list_label.add_text(str(id))
	# Inform the server about this new player
	rpc_id(1, "_register_player_on_server", player_info)

@rpc("any_peer", "reliable", "call_remote")
func _register_player_on_server(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	
	rpc("_player_joined", new_player_id, new_player_info)

@rpc("any_peer", "reliable", "call_local")
func _player_joined(new_player_id, new_player_info):
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	var text = str(new_player_id) + "\n"
	player_list_label.add_text(text)

func _on_player_connected(id):
	if multiplayer.is_server():
		rpc_id(multiplayer.get_remote_sender_id(), "_sync_players", players)
	
@rpc("any_peer", "reliable", "call_local")
func _sync_players(server_players):
	players = server_players
	player_list_label.clear()
	for player_id in players.keys():
		var text = str(player_id) + "\n"
		player_list_label.add_text(text)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)
	# Update UI if necessary

func _on_connected_fail():
	print("Failed to connect to the server.")
	# Handle connection failure

func _on_server_disconnected():
	print("Disconnected from the server.")
	# Handle server disconnection
