extends Area2D


# Level exit door. Hidden under one breakable wall and revealed when that wall
# is broken. Starts disabled (translucent) while enemies remain; the level calls
# enable() once every enemy is cleared, switching it to opaque. Walking into an
# enabled door completes the level. The root is an Area2D so the door never
# blocks movement — the player walks onto its cell to finish.
#
# A door hit by flame is destroyed: it stays a usable exit (overlapping it still
# completes the level) but never returns to the opaque enabled look — it keeps
# blinking and spawning one enemy every 2 seconds until the player reaches it.

const _DISABLED_ALPHA := 0.4
# A destroyed door blinks between these alphas and spawns one enemy per interval.
const _BLINK_INTERVAL := 0.25
const _SPAWN_INTERVAL := 2.0
# Completion fires only when the player's center is within this distance of the
# door center — "more or less inside" the 48px tile, not on first edge overlap.
const ENTER_RADIUS := 12.0

@onready var sprite: Sprite2D = $Sprite2D

var enabled: bool = false
var _completed: bool = false
# Once destroyed by flame, the door becomes a permanent enemy spawner and can
# never be enabled or completed again.
var _destroyed: bool = false


func _ready() -> void:
	_apply_state()


func _physics_process(_delta: float) -> void:
	# Completion fires only when a player is more or less inside the tile — its
	# center within ENTER_RADIUS of the door center — not on first edge overlap.
	# A destroyed door stays a usable exit, so completion is allowed when enabled
	# OR destroyed. Polling each frame also covers a player already centered when
	# the door enables / is destroyed (no fresh overlap event needed).
	if _completed:
		return
	if not (enabled or _destroyed):
		return
	for body in get_overlapping_bodies():
		if not body.is_in_group("players"):
			continue
		if global_position.distance_to(body.global_position) <= ENTER_RADIUS:
			_complete()
			return


func enable() -> void:
	if _destroyed:
		return
	if enabled:
		return
	enabled = true
	_apply_state()


func destroy() -> void:
	# Flame entry point. Idempotent: a door already destroyed ignores further hits.
	# The door is NOT freed (unlike a breakable wall) — it stays to spawn enemies.
	if _destroyed:
		return
	_destroyed = true
	enabled = false
	_start_blink()
	_start_spawning()


func _start_blink() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "modulate:a", _DISABLED_ALPHA, _BLINK_INTERVAL)
	tween.tween_property(sprite, "modulate:a", 1.0, _BLINK_INTERVAL)


func _start_spawning() -> void:
	var timer := Timer.new()
	timer.wait_time = _SPAWN_INTERVAL
	timer.one_shot = false
	timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(timer)
	timer.start()


func _on_spawn_timer_timeout() -> void:
	var level := get_parent()
	# Guard against firing during teardown (scene reload frees the level first).
	if not is_instance_valid(level) or not level.has_method("spawn_random_enemy"):
		return
	var tile_map = level.tile_map
	var cell: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	level.spawn_random_enemy(cell)


func _apply_state() -> void:
	sprite.modulate.a = 1.0 if enabled else _DISABLED_ALPHA


func _complete() -> void:
	if _completed:
		return
	_completed = true
	var level := get_parent()
	if level != null and level.has_method("complete_level"):
		level.complete_level()
	else:
		get_tree().reload_current_scene()
