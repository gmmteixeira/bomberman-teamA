extends CharacterBody2D


@onready var placer_area: Area2D = $PlacerArea

var _placer: CharacterBody2D = null


func _ready() -> void:
	placer_area.body_exited.connect(_on_placer_area_body_exited)


func setup(placer: CharacterBody2D) -> void:
	_placer = placer
	add_collision_exception_with(placer)


func _on_placer_area_body_exited(body: Node2D) -> void:
	if _placer == null or body != _placer:
		return
	remove_collision_exception_with(_placer)
	_placer = null
