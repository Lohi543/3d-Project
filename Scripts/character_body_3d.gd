extends CharacterBody3D

var speed
var health = 100
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const HIT_STAGGER = 8.0


#Item pickup settings
var picked_object
var raycast_item
var object
const ROTATION_POWER = 0.05
const PULL_POWER = 7.0
const THROW_STRENGTH = 1.5
const OUTLINE_SHADER = preload("res://Assets/Tetures/Outline_shader.tres")
var Item_pickup_cooldown = false
var locked = false
var Holding_item = false
var Hovering_item = false

#weapon settings
const BULLET = preload("res://Assets/TSCN/bullet.tscn")
var instance

#camer Bob settings
const  BOB_FREQ= 2.0
const  BOB_AMP =  0.1
var t_bob = 0.0

#fov settings
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@onready var world: Node3D = $".."
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction: RayCast3D = $Head/Camera3D/interaction
@onready var hand: Marker3D = $Head/Camera3D/hand
@onready var static_body: StaticBody3D = $Head/Camera3D/StaticBody3D
@onready var joint: Generic6DOFJoint3D = $Head/Camera3D/Generic6DOFJoint3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var cooldown_timer: Timer = $Item_pickup_cooldown
@onready var health_bar: ProgressBar = $Head/Camera3D/HealthBar

#signal
signal  player_hit

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_bar.init_health(health)

func rotate_object(event: InputEvent):
	if picked_object != null:
		if event is InputEventMouseMotion:
			static_body.rotate_x(deg_to_rad(event.relative.y * ROTATION_POWER))
			static_body.rotate_y(deg_to_rad(event.relative.x * ROTATION_POWER))

func pickup_object():
	var collider = interaction.get_collider()
	if collider != null: #check what raycast found
		if collider.is_in_group("object"):
			picked_object = collider
			var Collision_shape = picked_object.get_node("CollisionShape3D")
			#var stats = mesh_instance_3d
			#stats.
			if picked_object.is_in_group("weapon"):
				Hide_outline(picked_object)
				Holding_item = true
				picked_object.reparent(camera)
				picked_object.freeze = true
				Collision_shape.disabled = true
				picked_object.position = camera.position + Vector3(0.65, -0.2, -0.953)
				picked_object.rotation = Vector3(0,0,0)
			else:
				Hide_outline(picked_object)
				joint.node_b = picked_object.get_path()

func remove_object():
	if picked_object != null:
		picked_object = null
		joint.node_b = joint.get_path()

func Throw_object():
	if picked_object != null:
		var Collision_shape = picked_object.get_node("CollisionShape3D")
		if picked_object.is_in_group("weapon"):
			var Knockback = picked_object.global_position - global_position
			var position = picked_object.global_position
			picked_object.reparent($"..")
			picked_object.global_position = position
			picked_object.freeze = false
			Collision_shape.disabled = false
			picked_object.apply_central_impulse(Knockback * THROW_STRENGTH)
			picked_object = null
			Holding_item = false
		else:
			var Knockback = picked_object.global_position - global_position
			picked_object.apply_central_impulse(Knockback * THROW_STRENGTH)
			remove_object()

func _input(event: InputEvent):
	if Input.is_action_just_pressed("Select_item"):
		Item_pickup_cooldown = true
		if Item_pickup_cooldown == true:
			cooldown_timer.start()
	if Input.is_action_pressed("Rotate_item"):
		locked = true
		rotate_object(event)
	if Input.is_action_just_released("Rotate_item"): # rotates object
		locked = false
	if Input.is_action_just_pressed("Throw_item"): # throws item
		Throw_object()

func _on_item_pickup_cooldown_timeout():
	Item_pickup_cooldown = false
	if picked_object == null:
		pickup_object()
	elif picked_object != null:
		if picked_object.is_in_group("weapon") and Holding_item == true:#interacted with item
			var Animation_player = picked_object.get_node("AnimationPlayer")
			var Gun_barrel: RayCast3D = picked_object.get_node("RayCast3D")
			if !Animation_player.is_playing():
				Animation_player.play("Action")
				instance = BULLET.instantiate()
				instance.position = Gun_barrel.global_position
				instance.transform.basis = Gun_barrel.global_transform.basis
				get_parent().add_child(instance)
		else:
			remove_object()

func  _unhandled_input(event: InputEvent):
	if !locked:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	#handle the running
	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.2)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.2)
		
	# head bob action
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	#FOV handling
	var velcoity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velcoity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	#pickup handler
	if picked_object != null:
		if picked_object.is_in_group("weapon"): 
			pass
		else:
			var a = picked_object.global_transform.origin
			var b = hand.global_transform.origin
			var c = a.distance_to(b)
			var calc = (a.direction_to(b)) * PULL_POWER * c
			picked_object.set_linear_velocity(calc)
		
	
	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func Hide_outline(object: Node3D) -> void:
	if object.is_in_group("object") or object.is_in_group("weapon"): 
		if Hovering_item == true:
			Hovering_item = false
			var mesh = object.get_node("Outline")
			mesh.visible = false

func _on_area_3d_body_entered(object: Node3D) -> void:
	if picked_object == null:
		if object.is_in_group("object") or object.is_in_group("weapon"): 
			if Hovering_item == false:
				Hovering_item = true
				var mesh = object.get_node("Outline")
				mesh.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	object = body
	Hide_outline(object)

func hit(dir, damage):
	print("Player_HIt")
	emit_signal("player_hit")
	health -= damage
	if health > 0:
		health_bar.health = health
		velocity += dir * HIT_STAGGER
	else:
		get_tree().reload_current_scene()
	

func damaged(dir, damage):
	hit(dir, damage)
