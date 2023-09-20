extends Area3D

@export var damage: int = 10

@onready var shape: CollisionShape3D = $CollisionShape3D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func trigger_hitbox():
	shape.disabled = false
	await get_tree().create_timer(0.2).timeout
	shape.disabled = true
