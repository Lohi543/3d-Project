extends Node3D

@onready var hit_rect: ColorRect = $Ui/HitRect
@onready var spawns: Node3D = $map/Spawns
@onready var navigation_region: NavigationRegion3D = $map/NavigationRegion3D

const BEAR = preload("res://Assets/TSCN/Bear.tscn")
const WOLF = preload("res://Assets/TSCN/Wolf.tscn")

var mobs = [BEAR, WOLF]
var instance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_character_body_3d_player_hit() -> void:
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false
	
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func choose(array):
	return array[randi() % array.size()]

func _on_mob_spawn_timer_timeout() -> void:
	var spawn_point = _get_random_child(spawns).global_position
	var mob = choose(mobs)
	instance = mob.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)
	
