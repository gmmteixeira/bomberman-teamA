extends StaticBody2D


signal broke

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_breaking: bool = false


func break_wall() -> void:
	if _is_breaking:
		return
	_is_breaking = true
	broke.emit()
	animated_sprite.animation_finished.connect(_on_break_finished, CONNECT_ONE_SHOT)
	animated_sprite.play("break")


func _on_break_finished() -> void:
	queue_free()
