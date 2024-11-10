extends Node3D

@export var fire_rate := 14.0
@export var max_recoil := 0.3
@export var recoil := 0.05
@export var weapon_penalty := 0.1
@export var weapon_mesh : Node3D
@export var weapon_damage := 15
@export var muzzle_flash: GPUParticles3D
@export var sparks: PackedScene
@export var automatic: bool
@export var ammo_handler: AmmoHandler
@export var ammo_type: AmmoHandler.ammo_type

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var weapon_position: Vector3 = weapon_mesh.position
@onready var ray_cast_3d: RayCast3D = $RayCast3D

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
			
	if automatic:
		if Input.is_action_pressed("Shoot"):
			if cooldown_timer.is_stopped():
				shoot()
	else:
		if Input.is_action_just_pressed("Shoot"):
			if cooldown_timer.is_stopped():
				shoot()
	
	weapon_mesh.position = weapon_mesh.position.lerp(weapon_position, delta * 10.0)
	
func shoot() -> void:
	if not is_multiplayer_authority(): return
	
	if ammo_handler.has_ammo(ammo_type):
		ammo_handler.use_ammo(ammo_type)
		cooldown_timer.start(1.0 / fire_rate)
		weapon_mesh.position.z += recoil
	
		play_visual_effects(ray_cast_3d.get_collision_point())
	
		if ray_cast_3d.is_colliding():
			var collider = ray_cast_3d.get_collider()
		
			if collider is Player and collider != null:
				var authority = collider.get_multiplayer_authority()
				printt(weapon_damage,collider.health)
				collider.rpc_id(authority, "take_damage", weapon_damage)
			else:
				print("invalid")
				
		rpc("play_visual_effects", ray_cast_3d.get_collision_point())
	

@rpc("call_remote")
func play_visual_effects(collison_point: Vector3) -> void:
	muzzle_flash.restart()
	
	var spark = sparks.instantiate()
	add_child(spark)
	spark.global_position = collison_point
