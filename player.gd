extends CharacterBody3D
class_name Player

@onready var camera: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var weapon_handler: Node3D = $Camera3D/WeaponHandler
@onready var buy_screen: Control = $BuyScreen
@onready var health_bar: Label = $HUD/HealthBar


@export var health = 100
@export var team = 1
@export var money = 80000

var is_alive = true
var is_buy_screen_open = false
var primary_weapon: PackedScene
var respawn_point: Vector3

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

var gravity: float = 20.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	await get_tree().process_frame
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	health_bar.text = str(health)

func _input(event: InputEvent) -> void:
		pass
		

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("Buy"):
			toggle_buy_screen()
		
		
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		

	move_and_slide()
	
@rpc("any_peer", "call_local")
func request_purchase(weapon_id, weapon_cost, player_id):
	weapon_handler.update_weapon(weapon_id, player_id)
	
@rpc("any_peer") 
func take_damage(damage: int) -> void:
	health -= damage
	health = max(0, health)
	
	health_bar.text = ""
	health_bar.text = str(health).strip_edges()
	
	if health <= 0:
		position = respawn_point
		health = 100
		health_bar.text = str(health)



func toggle_buy_screen():
	is_buy_screen_open = !is_buy_screen_open
	buy_screen.visible = is_buy_screen_open
	set_process_input(not is_buy_screen_open)
	set_physics_process(not is_buy_screen_open)
	
	if is_buy_screen_open:
		buy_screen.set_focus_mode(Control.FOCUS_ALL)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		get_viewport().set_input_as_handled()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

