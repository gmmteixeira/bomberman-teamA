extends Area2D
class_name Powerup


enum Type { FIRE, BOMB }

const _ANIMATIONS := {
	Type.FIRE: &"fire",
	Type.BOMB: &"bomb",
}

const DROPPABLE_TYPES: Array = [Type.FIRE, Type.BOMB]

@export var type: Type = Type.FIRE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	animated_sprite.play(_ANIMATIONS[type])


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("players"):
		return
	_collected = true
	match type:
		Type.FIRE:
			body.power += 1
		Type.BOMB:
			body.max_bombs += 1
	queue_free()
