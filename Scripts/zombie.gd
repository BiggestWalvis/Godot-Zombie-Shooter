extends CharacterBody3D

var player = null
var state_machine
var health = 6
var deathFlag = "stillAlive"

signal zombie_hit
signal zombie_hit_headshot
signal zombie_die


const SPEED = 4.0
const ATTACK_RANGE = 2.5

@export var player_path := "/root/World/Map/NavigationRegion3D/Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree





func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")


func _process(delta):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Run":
			#Navigation
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)


	#conditions
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	
	if health <= 0:
		if deathFlag != "zombieDied":
			emit_signal("zombie_die")
			deathFlag = "zombieDied"
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(4.0).timeout
		queue_free()

	move_and_slide()


func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE


func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		var type = "zombie"
		player.hit(dir,type)


func _on_area_3d_body_part_hit(dam):
	health -= dam
	if deathFlag != "zombieDied":
		emit_signal("zombie_hit")

func _on_area_3d_body_part_hit_headshot(dam):
	health -= dam
	if deathFlag != "zombieDied":
		emit_signal("zombie_hit_headshot")
