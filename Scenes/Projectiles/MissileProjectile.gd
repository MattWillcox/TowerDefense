extends KinematicBody2D

var target
var target_last_pos
var speed = 500
var damage = 500
var on_route = false

func _physics_process(delta):
	if is_instance_valid(target) && target.position:
		target_last_pos = target.position
	move(delta)

func move(delta):
	self.look_at(target_last_pos)
	position = position.move_toward(target_last_pos, delta * speed)
	if position.distance_to(target_last_pos) <= 4:
		on_route = false
		queue_free()
