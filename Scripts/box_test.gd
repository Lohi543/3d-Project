extends RigidBody3D
@onready var outline: MeshInstance3D = $Outline


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_detected(_visible: bool):
	outline.visible = _visible
