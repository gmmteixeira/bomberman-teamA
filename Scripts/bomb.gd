extends CharacterBody2D


@export var lifetime: float = 3.0

var power: int = 1

const _MIN_LIFETIME: float = 0.05

@onready var placer_area: Area2D = $PlacerArea

var _placer: CharacterBody2D = null
var _is_detonating: bool = false
var _lifetime_timer: SceneTreeTimer = null


func _ready() -> void:
	add_to_group("bombs")
	placer_area.body_exited.connect(_on_placer_area_body_exited)
	var effective_lifetime: float = maxf(lifetime, _MIN_LIFETIME)
	_lifetime_timer = get_tree().create_timer(effective_lifetime)
	_lifetime_timer.timeout.connect(_detonate, CONNECT_ONE_SHOT)


func setup(placer: CharacterBody2D, bomb_power: int = 1) -> void:
	_placer = placer
	power = bomb_power
	add_collision_exception_with(placer)


func detonate_now() -> void:
	_detonate()


func _detonate() -> void:
	if _is_detonating:
		return
	_is_detonating = true
	var level := get_parent()
	if level != null and level.has_method("spawn_explosion"):
		var cell: Vector2i = level.tile_map.local_to_map(level.tile_map.to_local(global_position))
		level.spawn_explosion(cell, power)
	queue_free()


func _on_placer_area_body_exited(body: Node2D) -> void:
	if _placer == null or body != _placer:
		return
	remove_collision_exception_with(_placer)
	_placer = null
