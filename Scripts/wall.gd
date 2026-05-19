extends StaticBody2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_breaking: bool = false


func break_wall() -> void:
	if _is_breaking:
		return
	_is_breaking = true
	collision_shape.set_deferred("disabled", true)
	animated_sprite.animation_finished.connect(_on_break_finished, CONNECT_ONE_SHOT)
	animated_sprite.play("break")


func _on_break_finished() -> void:
	queue_free()
