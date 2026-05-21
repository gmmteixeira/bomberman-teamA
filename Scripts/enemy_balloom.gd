extends CharacterBody2D


# Balloom: the simplest Bomberman enemy. Wanders the grid in straight lines,
# re-rolling a random direction whenever its path is blocked. No player
# awareness. Kills the player on contact; dies to a single explosion flame via
# the level's existing die() flame hook.

@export var speed: float = 60.0

const _DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const _ARRIVE_EPSILON := 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_area: Area2D = $HurtArea
@onready var level: Node2D = get_parent()

var _is_dead: bool = false
var _dir: Vector2i = Vector2i.ZERO
# The enemy is always moving from _from_cell to _target_cell (equal when at rest).
var _from_cell: Vector2i = Vector2i.ZERO
var _target_cell: Vector2i = Vector2i.ZERO
# Vertical movement has no dedicated art, so alternate the left/right walk
# strips on each vertical step to convey motion.
var _vertical_flip: bool = false


func _ready() -> void:
	add_to_group("enemies")
	hurt_area.body_entered.connect(_on_hurt_area_body_entered)
	animated_sprite.play(&"walk_right")
	_from_cell = _current_cell()
	_target_cell = _from_cell
	_choose_direction()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	# Poll every frame (not just on enter) so a bomb placed onto our path — or
	# spawned right on top of us — is treated as a solid obstacle even though no
	# body_entered event fires for an already-overlapping bomb.
	if level.bomb_at_cell(_target_cell) != null:
		_react_to_bomb()
	var target_world := _cell_to_world(_target_cell)
	global_position = global_position.move_toward(target_world, speed * delta)
	if global_position.distance_to(target_world) <= _ARRIVE_EPSILON:
		global_position = target_world
		_on_reached_cell()


func _on_reached_cell() -> void:
	# Continue straight while the path ahead is open; otherwise re-roll.
	var ahead := _target_cell + _dir
	if _dir != Vector2i.ZERO and _is_enterable(ahead):
		_step_to(ahead)
	else:
		_choose_direction()


func _choose_direction() -> void:
	var cur := _target_cell
	var options: Array[Vector2i] = []
	for d: Vector2i in _DIRS:
		if _is_enterable(cur + d):
			options.append(d)
	if options.is_empty():
		# Fully boxed in — stay put until an adjacent tile opens (e.g. a wall breaks).
		_dir = Vector2i.ZERO
		_from_cell = cur
		return
	_step_to(cur + options[randi() % options.size()])


func _react_to_bomb() -> void:
	# A bomb appeared on the cell we are entering. Never cross it.
	var bomb_cell := _target_cell
	if bomb_cell != _from_cell and _is_enterable(_from_cell):
		# Back up to the cell we just left (still clear) and head the other way.
		_target_cell = _from_cell
		_from_cell = bomb_cell
		_dir = _target_cell - bomb_cell
		_update_anim()
		return
	# No clean reverse (e.g. bomb spawned on our own cell): flee to any open neighbour.
	var here := _current_cell()
	var options: Array[Vector2i] = []
	for d: Vector2i in _DIRS:
		if _is_enterable(here + d):
			options.append(d)
	if options.is_empty():
		_dir = Vector2i.ZERO
		_from_cell = here
		_target_cell = here
		return
	_dir = options[randi() % options.size()]
	_from_cell = here
	_target_cell = here + _dir
	_update_anim()


func _step_to(cell: Vector2i) -> void:
	_from_cell = _target_cell
	_dir = cell - _target_cell
	_target_cell = cell
	_update_anim()


func _update_anim() -> void:
	if _dir.x > 0:
		_play(&"walk_right")
	elif _dir.x < 0:
		_play(&"walk_left")
	elif _dir.y != 0:
		_vertical_flip = not _vertical_flip
		_play(&"walk_right" if _vertical_flip else &"walk_left")


func _play(anim: StringName) -> void:
	if animated_sprite.animation != anim or not animated_sprite.is_playing():
		animated_sprite.play(anim)


func _is_enterable(cell: Vector2i) -> bool:
	if not level.cell_in_bounds(cell):
		return false
	if level.cell_has_pillar(cell):
		return false
	if level.wall_at_cell(cell) != null:
		return false
	if level.bomb_at_cell(cell) != null:
		return false
	return true


func _current_cell() -> Vector2i:
	var tm: TileMapLayer = level.tile_map
	return tm.local_to_map(tm.to_local(global_position))


func _cell_to_world(cell: Vector2i) -> Vector2:
	var tm: TileMapLayer = level.tile_map
	return tm.to_global(tm.map_to_local(cell))


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	# A dying Balloom no longer harms the player.
	hurt_area.set_deferred("monitoring", false)
	animated_sprite.animation_finished.connect(_on_die_finished, CONNECT_ONE_SHOT)
	animated_sprite.play(&"die")


func _on_die_finished() -> void:
	queue_free()


func _on_hurt_area_body_entered(body: Node2D) -> void:
	if _is_dead:
		return
	if body.is_in_group("players") and body.has_method("die"):
		body.die()
