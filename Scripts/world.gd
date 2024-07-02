extends Node3D

#Player hit registration
@onready var hit_rect = $UI/PlayerHit

#map spawing
@onready var spawns = $Map/Spawns
@onready var navigation_region = $Map/NavigationRegion3D

#Crosshair
@onready var crosshair = $UI/Crosshair
@onready var crosshair_hit = $UI/CrosshairHit
@onready var crosshair_headshot = $UI/CrosshairHeadshot

#Health 
@onready var healthbar = $UI/HealthBar
@onready var gameover = $UI/GameOver

#score
@onready var score = $UI/ScoreLabel/Score


var zombie = load("res://Scenes/zombie.tscn")
var instance
var currentscore = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	crosshair.position.x = get_viewport().size.x / 2 - 32
	crosshair.position.y = get_viewport().size.y / 2 - 32
	crosshair_hit.position.x = get_viewport().size.x / 2 - 32
	crosshair_hit.position.y = get_viewport().size.y / 2 - 32
	crosshair_headshot.position.x = get_viewport().size.x / 2 - 32
	crosshair_headshot.position.y = get_viewport().size.y / 2 - 32

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_player_player_hit_zombie():
	hit_rect.visible = true
	_take_damage(3)
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false
	
func _take_damage(value):
	healthbar.value -= value
	if healthbar.value <= 0:
		hit_rect.visible = true
		gameover.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _on_zombie_spawn_timer_timeout():
	var spawn_point = _get_random_child(spawns).global_position
	instance = zombie.instantiate()
	instance.position = spawn_point
	instance.zombie_hit.connect(_on_enemy_hit)
	instance.zombie_hit_headshot.connect(_on_enemy_hit_headshot)
	instance.zombie_die.connect(_on_zombie_death)
	navigation_region.add_child(instance)


func _on_enemy_hit():
	crosshair_hit.visible = true
	await get_tree().create_timer(0.05).timeout
	crosshair_hit.visible = false

func _on_enemy_hit_headshot():
	crosshair_headshot.visible = true
	await get_tree().create_timer(0.05).timeout
	crosshair_headshot.visible = false

func _on_zombie_death():
	currentscore += 1
	score.text = str(currentscore)


