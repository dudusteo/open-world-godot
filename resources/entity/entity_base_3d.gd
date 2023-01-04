extends CharacterBody3D

signal hp_changed(new_hp: int)

const INDICATOR_DAMAGE = preload("res://resources/overlap/damage_indicator.tscn")

@export var hp_max: int = 20
@export var hp: int = hp_max
@export var defense: int = 0

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 11

@onready var character_pivot: Marker3D = $CharacterPivot3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var weapon: Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var canDoubleJump: bool = true
var isAttacking: bool = false

func get_weapon():
	var weapon_att: BoneAttachment3D = character_pivot.get_child(0).get_node("Armature/Skeleton3D/WeaponAttachment")
	if(weapon_att and weapon_att.get_child_count() == 1):
		weapon = weapon_att.get_child(0)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
			
	move()
	
func move():
	return move_and_slide()

func die():
	anim_tree.set("parameters/is_dead/current", 1)
	await get_tree().create_timer(0).timeout
	queue_free()
	
func deal_damage():
	weapon.get_node("Hitbox3D").trigger_hitbox()

func spawn_effect(EFFECT: PackedScene, effect_position: Vector3 = global_position):
	if EFFECT:
		var effect = EFFECT.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = effect_position + Vector3(0, 1, 0)
		return effect

func receive_damage(base_damage: int):
	var actual_damage = base_damage
	actual_damage -= defense
	self.hp = clamp(self.hp - actual_damage, 0, hp_max)
	if not hp:
		die()
	var indicator = spawn_effect(INDICATOR_DAMAGE)
	if indicator:
		print(actual_damage)
		indicator.label.text = str(actual_damage)
	emit_signal("hp_changed", self.hp)

func _on_hurtbox_3d_area_entered(hitbox):
	receive_damage(hitbox.damage)
	
