extends CharacterBody3D
var player = null
var state_machine

const SPEED = 4.0
const DAMAGE = 10.0
const ATTACK_RANGE = 3.0
const HIT_STAGGER = 80.0
var health = 18

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
		"Run":
			navigation_agent_3d.target_position = player.global_transform.origin
			var next_nav_point = navigation_agent_3d.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	#coditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	anim_tree.get("parameters/playback")
	
	move_and_slide()

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finsihed():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir, DAMAGE)

func damaged(dir, DAMAGE):
	velocity += dir * HIT_STAGGER
	
func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	health_bar.health = health
	if health <= 0:
		queue_free()
