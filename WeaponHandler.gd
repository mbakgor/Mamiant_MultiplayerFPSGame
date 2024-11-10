extends Node3D
@onready var ammo_handler: AmmoHandler = %AmmoHandler

var primary_weapon: Node3D
var secondary_weapon: Node3D
var current_primary_id: int = 0
var current_secondary_id: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("Equip Primary"):
		equip_weapon(2)  # Equip primary weapon
	elif event.is_action_pressed("Equip Secondary"):
		equip_weapon(1)  # Equip secondary weapon

# Equip the selected weapon and update visibility
func equip_weapon(weapon_id: int) -> void:
	if weapon_id == 1 and secondary_weapon:
		rpc_id(0, "equip_weapon_rpc", 1)
	elif weapon_id == 2 and primary_weapon:
		rpc_id(0, "equip_weapon_rpc", 2)

@rpc("any_peer", "call_local")
func equip_weapon_rpc(weapon_id: int) -> void:
	print("Equipping weapon:", weapon_id)  # Debugging

	# Ensure only the selected weapon is visible
	if weapon_id == 1:
		set_weapon_visibility(secondary_weapon, true)
		set_weapon_visibility(primary_weapon, false)
		secondary_weapon.ammo_handler.update_ammo_label(secondary_weapon.ammo_type)
	elif weapon_id == 2:
		set_weapon_visibility(primary_weapon, true)
		set_weapon_visibility(secondary_weapon, false)
		primary_weapon.ammo_handler.update_ammo_label(primary_weapon.ammo_type)

# Helper function to control weapon visibility and process state
func set_weapon_visibility(weapon: Node3D, visible: bool) -> void:
	if weapon:
		weapon.visible = visible
		weapon.set_process(visible)

# Add or replace a weapon and immediately equip it if appropriate
func update_weapon(weapon_id: int, player_id: int) -> void:
	var weapon_scene: PackedScene
	match weapon_id:
		1:
			weapon_scene = preload("res://Weapons/glock.tscn")  # Secondary
		2:
			weapon_scene = preload("res://Weapons/ak_47.tscn")  # Primary

	if weapon_scene:
		var new_weapon = weapon_scene.instantiate()
		new_weapon.set_multiplayer_authority(player_id)
		new_weapon.ammo_handler = ammo_handler
		add_child(new_weapon)
		new_weapon.set_owner(self)
		new_weapon.name = "Weapon_" + str(player_id)

		# Handle secondary weapon slot
		if weapon_id == 1:
			if secondary_weapon:
				secondary_weapon.queue_free()  # Remove old secondary weapon
			secondary_weapon = new_weapon

			# Equip it if no primary weapon exists or primary is inactive
			if !primary_weapon or !primary_weapon.visible:
				equip_weapon(1)

		# Handle primary weapon slot
		elif weapon_id == 2:
			if primary_weapon:
				primary_weapon.queue_free()  # Remove old primary weapon
			primary_weapon = new_weapon

			# Equip it if no secondary weapon exists or secondary is inactive
			if !secondary_weapon or !secondary_weapon.visible:
				equip_weapon(2)

		# Make sure only the equipped weapon is visible
		set_weapon_visibility(new_weapon, false)  # Default to hidden initially

func get_current_index() -> int:
	for index in get_child_count():
		if get_child(index).visible:
			return index
	return 0
	
func get_weapon_ammo() ->  AmmoHandler.ammo_type:
	return get_child(get_current_index()).ammo_type
