extends CharacterBody2D


@export var SPEED = 125.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED

	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			animated_sprite_2d.play("right" if direction.x > 0 else "left")
		else:
			animated_sprite_2d.play("down" if direction.y > 0 else "up")
	else:
		animated_sprite_2d.stop()

	move_and_slide()
