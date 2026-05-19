extends Area2D


signal flame_hit(body: Node2D)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_center: bool = false
var _hit_bodies: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Bodies already overlapping when the Area2D is added don't trigger
	# body_entered on their own — catch them after one physics frame.
	_check_initial_overlaps.call_deferred()


func _check_initial_overlaps() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func setup(type: StringName, is_center: bool = false) -> void:
	_is_center = is_center
	animated_sprite.play(type)


func is_center() -> bool:
	return _is_center


func get_sprite() -> AnimatedSprite2D:
	return animated_sprite


func _on_body_entered(body: Node2D) -> void:
	if _hit_bodies.has(body):
		return
	_hit_bodies[body] = true
	flame_hit.emit(body)
