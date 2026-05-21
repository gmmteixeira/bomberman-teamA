extends CharacterBody2D


@export var SPEED = 125.0
@export var power: int = 1
@export var max_bombs: int = 1

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var level: Node2D = get_parent()

# Alpha-blink rate used during the level-completion pause.
const _COMPLETE_BLINK_INTERVAL := 0.15

var _is_dead: bool = false
# Set while the level-completion pause runs: gameplay input/movement is halted but
# the node keeps processing (PROCESS_MODE_ALWAYS) so its blink tween can animate.
var _frozen: bool = false
var _active_bombs: int = 0


func _ready() -> void:
	add_to_group("players")


func _physics_process(_delta: float) -> void:
	if _is_dead or _frozen:
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


func blink() -> void:
	# Called by the level during the completion pause. The SceneTree is paused, so
	# switch to ALWAYS process mode (a tween bound to this node would otherwise be
	# frozen with the tree) and freeze gameplay explicitly, since ALWAYS would keep
	# _physics_process running. The tween blinks the sprite's alpha until reload.
	_frozen = true
	velocity = Vector2.ZERO
	animated_sprite_2d.stop()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tween := create_tween().set_loops()
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.0, _COMPLETE_BLINK_INTERVAL)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, _COMPLETE_BLINK_INTERVAL)


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	print("player died")
	velocity = Vector2.ZERO
	animated_sprite_2d.animation_finished.connect(_on_die_finished, CONNECT_ONE_SHOT)
	animated_sprite_2d.play("die")


func _on_die_finished() -> void:
	# Death restarts the level (no lives / further levels yet). Reloading replaces
	# the whole scene, so the player node is removed as part of the restart.
	if is_instance_valid(level) and level.has_method("restart_level"):
		level.restart_level()
	else:
		get_tree().reload_current_scene()
