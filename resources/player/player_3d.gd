extends "res://resources/entity/entity_base_3d.gd"

@onready var camera_pivot = $CameraPivot3D
@onready var camera_3d = $CameraPivot3D/SpringArm3D/Camera3D

var mouse_motion: Vector2 = Vector2()
var mouse_right_down: bool = false
var look_at: Basis = Basis()
var pivot: Basis = Basis()

@export var SENSITIVITY_X: int = 50
@export var SENSITIVITY_Y: int = 50
@export var MIN_ZOOM: float = 0.5
@export var MAX_ZOOM: float = 5.0
#@export var zoom: float = 5.0

enum State {IDLE, WALK, RUN, FALLING}

func _ready():
	get_weapon()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _process(_delta):
	#gamepad
	mouse_motion.y += Input.get_axis("camera_up", "camera_down") / 100 * SENSITIVITY_Y
	mouse_motion.x += Input.get_axis("camera_left", "camera_right") / 100 * SENSITIVITY_X
	
	#move
	mouse_motion.y = clamp(mouse_motion.y, -90, 90)
	pivot = Basis(Vector3i(1,0,0), deg_to_rad(-mouse_motion.y))
	look_at = Basis(Vector3i(0,1,0), deg_to_rad(-mouse_motion.x))
	camera_pivot.transform.basis = look_at * pivot
	#zoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM)
	#camera_3d.position.z = lerp(camera_3d.position.z, zoom, 0.1)

func _physics_process(delta):	
	var input_dir = Input.get_vector("left", "right", "up", "down")

	if not isAttacking:
		if(Input.is_action_pressed("crouch")):
			input_dir *= 0.5
		var movement = look_at * Vector3(input_dir.x, 0, input_dir.y)

		velocity.x = movement.x * SPEED
		velocity.z = movement.z * SPEED

		if movement:
			var angle = atan2(-movement.x, -movement.z)
			character_pivot.transform.basis = Basis(Vector3i(0,1,0), angle)

		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			canDoubleJump = true

		if Input.is_action_just_pressed("jump") and (is_on_floor() or canDoubleJump):
			velocity.y = JUMP_VELOCITY 
			if not is_on_floor():
				canDoubleJump = false

	else:
		velocity = Vector3(0.0, 0.0, 0.0)
#
	move()	
	
func _input(event):
	#Mouse Mode
	if Input.is_action_just_pressed("unlock_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	#Camera Control
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_motion.x += event.relative.x / 1000 * SENSITIVITY_X
			mouse_motion.y += event.relative.y / 1000 * SENSITIVITY_Y
		elif mouse_right_down:
			mouse_motion.x += event.relative.x / 1000 * SENSITIVITY_X
			mouse_motion.y += event.relative.y / 1000 * SENSITIVITY_Y
			
	#Zooming
	if event is InputEventMouseButton:
		#if(event.button_index == 4 && !event.is_pressed()):
		#	zoom -= 1.0
		#elif(event.button_index == 5 && !event.is_pressed()):
		#	zoom += 1.0
		if event.button_index == 2 and event.is_pressed():
			mouse_right_down = true
		elif event.button_index == 2 and not event.is_pressed():
			mouse_right_down = false
