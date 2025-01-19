extends Node3D

const SPEED = 40.0
const BULLET_DAMAGE = 5.0
@onready var mesh: MeshInstance3D = $Bulet
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var timer: Timer = $Timer
@onready var ray: RayCast3D = $RayCast3D
@onready var fish: MeshInstance3D = $Fish

var bullet
var player = null
var player_path = "/root/World/CharacterBody3D"

@export var Fish_Mode: bool

var Hit_object


# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)
	if Fish_Mode:
		mesh.visible = false
		fish.visible = true
		bullet = fish
	bullet = mesh
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta	
	await get_tree().create_timer(0.001).timeout
	if ray.is_colliding() and ray.get_collider().name != "Terrain":
		bullet.visible = false
		particles.emitting = true
		ray.enabled = false
		if ray.get_collider().is_in_group("enemy"):
			ray.get_collider().hit()
		if ray.get_collider().is_in_group("character") or ray.get_collider().is_in_group("player"):
			var dir = global_position.direction_to(player.global_position)
			ray.get_collider().damaged(dir, BULLET_DAMAGE)
		if get_tree():
			await get_tree().create_timer(1.0).timeout
			queue_free()

func _on_timer_timeout() -> void:
	queue_free()
