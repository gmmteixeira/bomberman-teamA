extends Node2D


const EXPLOSION_TILE_SCENE := preload("res://Scenes/explosion_tile.tscn")

const _ARMS := [
	{"dir": Vector2i(0, -1), "mid": &"mid_v", "end": &"end_u"},
	{"dir": Vector2i(0, 1),  "mid": &"mid_v", "end": &"end_d"},
	{"dir": Vector2i(-1, 0), "mid": &"mid_h", "end": &"end_l"},
	{"dir": Vector2i(1, 0),  "mid": &"mid_h", "end": &"end_r"},
]

var _level: Node2D = null
var _center_cell: Vector2i = Vector2i.ZERO
var _power: int = 1
var _ready_done: bool = false


func setup(level: Node2D, center_cell: Vector2i, power: int) -> void:
	_level = level
	_center_cell = center_cell
	_power = max(1, power)
	if _ready_done:
		_paint()


func _ready() -> void:
	_ready_done = true
	if _level != null:
		_paint()


func _paint() -> void:
	var center_tile := _spawn_tile(_center_cell, &"center", true)
	if center_tile != null:
		center_tile.get_sprite().animation_finished.connect(_on_center_finished, CONNECT_ONE_SHOT)

	for arm in _ARMS:
		_walk_arm(arm["dir"], arm["mid"], arm["end"])


func _walk_arm(direction: Vector2i, mid_anim: StringName, end_anim: StringName) -> void:
	# Phase 1: walk the arm to discover which cells get painted.
	# Stopping rules: out of bounds → stop, no paint; pillar → stop, no paint;
	# wall → paint this cell (terminal), break wall, stop.
	var reached: Array = []
	for step in range(1, _power + 1):
		var cell: Vector2i = _center_cell + direction * step
		if not _level.cell_in_bounds(cell):
			break
		if _level.cell_has_pillar(cell):
			break
		var wall = _level.wall_at_cell(cell)
		reached.append({"cell": cell, "wall": wall})
		if wall != null:
			break

	# Phase 2: paint. The LAST reached cell is always end_*; all others are mid_*.
	var last_index: int = reached.size() - 1
	for i in range(reached.size()):
		var entry: Dictionary = reached[i]
		var anim: StringName = end_anim if i == last_index else mid_anim
		_spawn_tile(entry["cell"], anim, false)
		var wall = entry["wall"]
		if wall != null and wall.has_method("break_wall"):
			wall.break_wall()


func _spawn_tile(cell: Vector2i, type: StringName, is_center: bool) -> Node:
	var tile := EXPLOSION_TILE_SCENE.instantiate()
	add_child(tile)
	var local_offset: Vector2 = _level.tile_map.transform * _level.tile_map.map_to_local(cell) - position
	tile.position = local_offset
	tile.setup(type, is_center)
	tile.flame_hit.connect(_on_flame_hit)
	return tile


func _on_flame_hit(body: Node2D) -> void:
	if body == null:
		return
	if body.is_in_group("bombs") or body.has_method("detonate_now"):
		body.detonate_now()
	elif body.is_in_group("players") or body.has_method("die"):
		body.die()


func _on_center_finished() -> void:
	queue_free()
