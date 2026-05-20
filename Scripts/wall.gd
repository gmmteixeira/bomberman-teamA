extends StaticBody2D


signal broke

enum Variant { A, B }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var variant: Variant = Variant.A
var _is_breaking: bool = false


func _ready() -> void:
	# Pick one of the two wall variants at random whenever a wall is placed.
	variant = Variant.A if randi() % 2 == 0 else Variant.B
	animated_sprite.play(_idle_anim())


func break_wall() -> void:
	if _is_breaking:
		return
	_is_breaking = true
	broke.emit()
	animated_sprite.animation_finished.connect(_on_break_finished, CONNECT_ONE_SHOT)
	animated_sprite.play(_break_anim())


func _on_break_finished() -> void:
	queue_free()


func _idle_anim() -> StringName:
	return &"idle_b" if variant == Variant.B else &"idle_a"


func _break_anim() -> StringName:
	return &"break_b" if variant == Variant.B else &"break_a"
