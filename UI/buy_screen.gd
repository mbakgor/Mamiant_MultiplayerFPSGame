extends Control

var weapon_cost
var weapon_id
var player

func _enter_tree():
	player = get_parent()
	

func _on_glock_button_pressed() -> void:
	weapon_cost = 800
	weapon_id = 1
	print(weapon_id,weapon_cost,str(player.name).to_int())
	player.request_purchase.rpc(weapon_id,weapon_cost,str(player.name).to_int())
		


func _on_ak_button_pressed() -> void:
	weapon_cost = 2800
	weapon_id = 2
	print(weapon_id,weapon_cost,str(player.name).to_int())
	player.request_purchase.rpc(weapon_id,weapon_cost,str(player.name).to_int())
