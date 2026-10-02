class_name Player
extends CharacterBody2D

@export var speed: float = 55.0
@export var animated_sprite: AnimatedSprite2D

var facing_direction := Vector2i.DOWN

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("left", "right", "top", "bottom")
	velocity = input_direction * speed
	move_and_slide()
	update_animation(input_direction)

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		match facing_direction:
			Vector2i.RIGHT: animated_sprite.play("IdleRight")
			Vector2i.LEFT: animated_sprite.play("IdleLeft")
			Vector2i.UP: animated_sprite.play("IdleUp")
			Vector2i.DOWN: animated_sprite.play("IdleDown")
		return

	if abs(direction.x) > abs(direction.y):
		facing_direction = Vector2i.RIGHT if direction.x > 0 else Vector2i.LEFT
		animated_sprite.play("WalkRight" if direction.x > 0 else "WalkLeft")
	else:
		facing_direction = Vector2i.DOWN if direction.y > 0 else Vector2i.UP
		animated_sprite.play("WalkDown" if direction.y > 0 else "WalkUp")
