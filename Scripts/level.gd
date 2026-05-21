extends Node2D


@export var grid_width: int = 11
@export var grid_height: int = 11
@export_range(0.0, 1.0, 0.05) var wall_spawn_chance: float = 0.5
@export_range(0.0, 1.0, 0.05) var powerup_spawn_chance: float = 0.3
@export var enemy_count: int = 3

const SOLID_ATLAS := Vector2i(0, 0)
const EMPTY_ATLAS := Vector2i(0, 1)
const SOURCE_ID := 0
const SOLID_SOURCE_ID := 1

const WALL_SCENE := preload("res://Scenes/wall.tscn")
const BOMB_SCENE := preload("res://Scenes/bomb.tscn")
const EXPLOSION_SCENE := preload("res://Scenes/explosion.tscn")
const POWERUP_SCENE := preload("res://Scenes/powerup.tscn")
const POWERUP_SCRIPT := preload("res://Scripts/powerup.gd")
const ENEMY_SCENE := preload("res://Scenes/enemy_balloom.tscn")
const SPAWN_SAFE_CELLS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
# Keep enemies a few tiles away from the player's spawn corner (0, 0).
const ENEMY_SPAWN_MIN_DISTANCE := 3

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var ground_map: TileMapLayer = $GroundLayer
@onready var player: CharacterBody2D = $CharacterBody2D

var _bombs_by_cell: Dictionary = {}
var _walls_by_cell: Dictionary = {}
var _powerups_by_cell: Dictionary = {}


func _ready() -> void:
	_generate_level()
	_scatter_walls()
	_place_player()
	_spawn_enemies()


func _generate_level() -> void:
	tile_map.clear()
	ground_map.clear()

	# Lay an opaque ground tile across the whole arena (including under the
	# perimeter and pillars) so the transparent catalyst wall art never reveals
	# the level background behind it.
	for y in range(-1, grid_height + 1):
		for x in range(-1, grid_width + 1):
			ground_map.set_cell(Vector2i(x, y), SOURCE_ID, EMPTY_ATLAS)

	for x in range(-1, grid_width + 1):
		tile_map.set_cell(Vector2i(x, -1), SOLID_SOURCE_ID, SOLID_ATLAS)
		tile_map.set_cell(Vector2i(x, grid_height), SOLID_SOURCE_ID, SOLID_ATLAS)
	for y in range(0, grid_height):
		tile_map.set_cell(Vector2i(-1, y), SOLID_SOURCE_ID, SOLID_ATLAS)
		tile_map.set_cell(Vector2i(grid_width, y), SOLID_SOURCE_ID, SOLID_ATLAS)

	for iy in range(grid_height):
		for ix in range(grid_width):
			# Bomberman pillar pattern: solid only on odd-odd interior cells so
			# entire rows/cols stay traversable. Swap to `(ix + iy) % 2 == 1`
			# for a literal every-other-tile alternation (brick pattern).
			var is_pillar := ix % 2 == 1 and iy % 2 == 1
			var atlas := SOLID_ATLAS if is_pillar else EMPTY_ATLAS
			var source := SOLID_SOURCE_ID if is_pillar else SOURCE_ID
			tile_map.set_cell(Vector2i(ix, iy), source, atlas)


func _scatter_walls() -> void:
	for iy in range(grid_height):
		for ix in range(grid_width):
			var cell := Vector2i(ix, iy)
			if ix % 2 == 1 and iy % 2 == 1:
				continue
			if cell in SPAWN_SAFE_CELLS:
				continue
			if randf() >= wall_spawn_chance:
				continue
			var wall := WALL_SCENE.instantiate()
			wall.position = tile_map.transform * tile_map.map_to_local(cell)
			add_child(wall)
			_walls_by_cell[cell] = wall
			wall.tree_exited.connect(func() -> void: _walls_by_cell.erase(cell))
			wall.broke.connect(func() -> void: _try_drop_powerup(cell))


func _place_player() -> void:
	var local_pos := tile_map.map_to_local(Vector2i(0, 0))
	player.position = tile_map.transform * local_pos


func _spawn_enemies() -> void:
	# Gather floor cells clear of pillars, breakable walls, and the player's
	# spawn corner, keeping only cells that have at least one open neighbour so a
	# Balloom never spawns fully boxed in.
	var candidates: Array = []
	for iy in range(grid_height):
		for ix in range(grid_width):
			var cell := Vector2i(ix, iy)
			if cell in SPAWN_SAFE_CELLS:
				continue
			if cell.x + cell.y < ENEMY_SPAWN_MIN_DISTANCE:
				continue
			if cell_has_pillar(cell):
				continue
			if _walls_by_cell.has(cell):
				continue
			if not _has_open_neighbor(cell):
				continue
			candidates.append(cell)

	candidates.shuffle()
	for i in range(mini(enemy_count, candidates.size())):
		var cell: Vector2i = candidates[i]
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = tile_map.transform * tile_map.map_to_local(cell)
		add_child(enemy)


func _has_open_neighbor(cell: Vector2i) -> bool:
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor: Vector2i = cell + dir
		if cell_in_bounds(neighbor) and not cell_has_pillar(neighbor) and not _walls_by_cell.has(neighbor):
			return true
	return false


func place_bomb_at_player(p: CharacterBody2D) -> void:
	var cell: Vector2i = tile_map.local_to_map(tile_map.to_local(p.global_position))
	if cell.x < 0 or cell.x >= grid_width or cell.y < 0 or cell.y >= grid_height:
		return
	if _bombs_by_cell.has(cell):
		return
	if not p.can_place_bomb():
		return
	var bomb := BOMB_SCENE.instantiate()
	bomb.position = tile_map.transform * tile_map.map_to_local(cell)
	add_child(bomb)
	_bombs_by_cell[cell] = bomb
	p.register_bomb()
	bomb.tree_exited.connect(func() -> void: _bombs_by_cell.erase(cell))
	bomb.tree_exited.connect(func() -> void:
		if is_instance_valid(p):
			p.release_bomb())
	bomb.setup(p, p.power)


func _try_drop_powerup(cell: Vector2i) -> void:
	if _powerups_by_cell.has(cell):
		return
	if randf() >= powerup_spawn_chance:
		return
	var powerup := POWERUP_SCENE.instantiate()
	powerup.type = POWERUP_SCRIPT.DROPPABLE_TYPES[randi() % POWERUP_SCRIPT.DROPPABLE_TYPES.size()]
	powerup.position = tile_map.transform * tile_map.map_to_local(cell)
	add_child(powerup)
	_powerups_by_cell[cell] = powerup
	powerup.tree_exited.connect(func() -> void: _powerups_by_cell.erase(cell))


func spawn_explosion(center_cell: Vector2i, power: int) -> void:
	if center_cell.x < 0 or center_cell.x >= grid_width or center_cell.y < 0 or center_cell.y >= grid_height:
		return
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.position = tile_map.transform * tile_map.map_to_local(center_cell)
	add_child(explosion)
	explosion.setup(self, center_cell, power)


func cell_has_pillar(cell: Vector2i) -> bool:
	return tile_map.get_cell_source_id(cell) == SOLID_SOURCE_ID and tile_map.get_cell_atlas_coords(cell) == SOLID_ATLAS


func wall_at_cell(cell: Vector2i):
	return _walls_by_cell.get(cell)


func bomb_at_cell(cell: Vector2i):
	return _bombs_by_cell.get(cell)


func powerup_at_cell(cell: Vector2i):
	return _powerups_by_cell.get(cell)


func cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height
