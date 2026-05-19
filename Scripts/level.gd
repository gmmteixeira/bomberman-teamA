extends Node2D


@export var grid_width: int = 13
@export var grid_height: int = 11

const SOLID_ATLAS := Vector2i(3, 3)
const EMPTY_ATLAS := Vector2i(13, 0)
const SOURCE_ID := 0

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $CharacterBody2D


func _ready() -> void:
	_generate_level()
	_place_player()


func _generate_level() -> void:
	tile_map.clear()

	for x in range(-1, grid_width + 1):
		tile_map.set_cell(Vector2i(x, -1), SOURCE_ID, SOLID_ATLAS)
		tile_map.set_cell(Vector2i(x, grid_height), SOURCE_ID, SOLID_ATLAS)
	for y in range(0, grid_height):
		tile_map.set_cell(Vector2i(-1, y), SOURCE_ID, SOLID_ATLAS)
		tile_map.set_cell(Vector2i(grid_width, y), SOURCE_ID, SOLID_ATLAS)

	for iy in range(grid_height):
		for ix in range(grid_width):
			# Bomberman pillar pattern: solid only on odd-odd interior cells so
			# entire rows/cols stay traversable. Swap to `(ix + iy) % 2 == 1`
			# for a literal every-other-tile alternation (brick pattern).
			var is_pillar := ix % 2 == 1 and iy % 2 == 1
			var atlas := SOLID_ATLAS if is_pillar else EMPTY_ATLAS
			tile_map.set_cell(Vector2i(ix, iy), SOURCE_ID, atlas)


func _place_player() -> void:
	var local_pos := tile_map.map_to_local(Vector2i(0, 0))
	player.position = tile_map.transform * local_pos
