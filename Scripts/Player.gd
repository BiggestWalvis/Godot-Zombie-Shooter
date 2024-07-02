extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005
const HIT_STAGGER = 8.0

#head bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.03
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# signal
signal player_hit_zombie

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

# Bullets
var bullet = load("res://Scenes/bullet.tscn")
var instance

# Camera
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var aim_ray = $Head/Camera3D/AimRay
@onready var aim_ray_end = $Head/Camera3D/AimRayEnd

# Guns
@onready var gun_anim = $Head/Camera3D/Rifle/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/Rifle/RayCast3D

func _ready():
	# capture mouse on game start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

#this function is called whenever the player does anything
func _unhandled_input(event):
	#rotate camera based off of mouse movement
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	# us head.transfor.basis to have the direction determined off of the players head, which was defined early and rotates with the mouse
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# this enables a small slide effect when coming to a stop
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# this dictates drifting and control in the air
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	#head bob calculation
	#is_on_floor returns a 1 or a 0 when converted to a float. Since we only want head bob while on the ground, this will give us that.
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# Handles FOV changes at different speeds
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Shooting
	if Input.is_action_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")
			instance = bullet.instantiate()
			# we are using global position for these next 2 lines, because we want to take into account the player's position
			#and not just the position of the gun within the player.
			instance.position = gun_barrel.global_position
			
			get_parent().add_child(instance)
			if aim_ray.is_colliding():
				instance.set_velocity(aim_ray.get_collision_point())
			else:
				instance.set_velocity(aim_ray_end.global_position)
			


	move_and_slide()
	
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func hit(dir, type):
	if type == "zombie":
		emit_signal("player_hit_zombie")
	velocity += dir * HIT_STAGGER

