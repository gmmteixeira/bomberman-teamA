extends CharacterBody2D


@export var lifetime: float = 3.0

const _MIN_LIFETIME: float = 0.05

@onready var placer_area: Area2D = $PlacerArea

var _placer: CharacterBody2D = null


func _ready() -> void:
	placer_area.body_exited.connect(_on_placer_area_body_exited)
	var effective_lifetime: float = maxf(lifetime, _MIN_LIFETIME)
	get_tree().create_timer(effective_lifetime).timeout.connect(_expire, CONNECT_ONE_SHOT)


func _expire() -> void:
	queue_free()


func setup(placer: CharacterBody2D) -> void:
	_placer = placer
	add_collision_exception_with(placer)


func _on_placer_area_body_exited(body: Node2D) -> void:
	if _placer == null or body != _placer:
		return
	remove_collision_exception_with(_placer)
	_placer = null
