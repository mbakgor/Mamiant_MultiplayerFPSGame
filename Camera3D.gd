extends Camera3D

var recoilAmount: Vector3 = Vector3.ZERO  # Current recoil offset
var targetRecoil: Vector3 = Vector3.ZERO  # Target recoil offset
var maxRecoilX = 0.3  # Maximum recoil sway in the horizontal direction
var maxRecoilY = 0.5  # Maximum recoil sway in the vertical direction
var recoilRecoverySpeed = 10  # Speed at which the camera returns to normal position

# Recoil parameters
var recoilKickback = 0.4  # How far back the camera will move with each shot
var recoilSpread = 0.1  # Spread for random horizontal recoil

func _ready():
	# Initialize recoil values if necessary
	targetRecoil = Vector3.ZERO
	recoilAmount = Vector3.ZERO

func _physics_process(delta: float):
	# Smoothly move towards target recoil position
	recoilAmount = lerp(recoilAmount, targetRecoil, delta * recoilRecoverySpeed)
	
	# Apply recoil to camera rotation and position
	rotation_degrees.x += recoilAmount.y
	rotation_degrees.y += recoilAmount.x
	
	# Gradually return to the original target position
	targetRecoil = lerp(targetRecoil, Vector3.ZERO, recoilRecoverySpeed * delta)

	# Check for shooting input
	if Input.is_action_just_pressed("Shoot"):
		applyRecoil()

func applyRecoil():
	# Generate a random horizontal recoil within the spread
	var randomRecoilX = randf_range(-recoilSpread, recoilSpread)
	
	# Increase vertical recoil (upwards kick) and apply horizontal sway
	targetRecoil.x += randomRecoilX * maxRecoilX  # Horizontal sway
	targetRecoil.y -= maxRecoilY  # Vertical recoil
	
	# Add backward movement for a realistic recoil kickback
	position.z -= recoilKickback
