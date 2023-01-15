extends Node3D

@export var SPEED: int = 30
@export var FRICTION: int = 15
var SHIFT_DIRECTION: Vector3 = Vector3.ZERO

@onready var label: Label3D = $Label3D

# Called when the node enters the scene tree for the first time.
func _ready():
	SHIFT_DIRECTION = Vector3(0.2, 0.2, 0)

func _process_physics(delta):
	global_position += SPEED * SHIFT_DIRECTION * delta
	SPEED = max(SPEED - FRICTION * delta, 0)
