extends CharacterBody2D


@export var SPEED = 125.0
@export var power: int = 1
@export var max_bombs: int = 1

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var level: Node2D = get_parent()

var _is_dead: bool = false
var _active_bombs: int = 0


func _ready() -> void:
	add_to_group("players")


func _physics_process(_delta: float) -> void:
	if _is_dead:
		return

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

	if Input.is_action_just_pressed("bomb"):
		level.place_bomb_at_player(self)


func can_place_bomb() -> bool:
	return _active_bombs < max_bombs


func register_bomb() -> void:
	_active_bombs += 1


func release_bomb() -> void:
	_active_bombs = maxi(_active_bombs - 1, 0)


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	print("player died")
	velocity = Vector2.ZERO
	animated_sprite_2d.animation_finished.connect(_on_die_finished, CONNECT_ONE_SHOT)
	animated_sprite_2d.play("die")


func _on_die_finished() -> void:
	queue_free()
