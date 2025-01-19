extends CharacterBody3D

var player = null
var state_machine

const SPEED = 0.9
const IDLE_RANGE = 25.0
const HIT_STAGGER = 80.0
var health = 20

# Gun bear stats
const BULLET = preload("res://Assets/TSCN/bullet.tscn")
var instance
@onready var Gun_barrel: RayCast3D = $interaction
@onready var timer: Timer = $Timer

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var health_bar: ProgressBar = $Sprite3D/SubViewport/HealthBar

var PULL_POWER = 4

var player_path = "/root/World/CharacterBody3D"

# Called when the node enters the scene tree for the first time.
func _ready():
	health_bar.init_health(health)
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walk":
			navigation_agent_3d.target_position = player.global_transform.origin
			var next_nav_point = navigation_agent_3d.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Idle":
			look_at(Vector3(player.global_position.x, player.global_position.y, player.global_position.z), Vector3.UP)
	#coditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	move_and_slide()

func _target_in_range():
	if global_position.distance_to(player.global_position) < IDLE_RANGE:
		if timer.is_stopped():
			timer.start()
		return true
	else:
		timer.stop()
		return false
func _hit_finsihed():
	player.hit()


func _on_timer_timeout():
	instance = BULLET.instantiate()
	instance.position = Gun_barrel.global_position
	instance.transform.basis = Gun_barrel.global_transform.basis
	get_parent().add_child(instance)
	
func damaged(dir, DAMAGE):
	velocity += dir * HIT_STAGGER

func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	health_bar.health = health
	if health <= 0:
		queue_free()
