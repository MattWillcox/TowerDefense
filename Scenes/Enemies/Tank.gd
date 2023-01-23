extends PathFollow2D

signal base_damage(damage)
signal increase_money(amount)
signal enemy_killed()

var speed = 150
var hp
var base_damage = 21

onready var health_bar = get_node("HealthBar")
onready var impact_area = get_node("Impact")
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

func _ready():
	health_bar.max_value = hp
	health_bar.value = hp
	health_bar.set_as_toplevel(true)

func _physics_process(delta):
	move(delta)
	
func move(delta):
	set_offset(get_offset() + speed * delta)
	health_bar.set_position(position - Vector2(30, 30))

func on_hit(damage, category):
	impact(category)
	hp -= damage
	health_bar.value = hp
	if hp <= 0:
		emit_signal("increase_money")
		emit_signal("enemy_killed")
		on_destroy()
		
func impact(category):
	randomize()
	var x_pos = randi() % 31
	randomize()
	var y_pos = randi() % 31
	var impact_location = Vector2(x_pos, y_pos)
	var new_impact = projectile_impact.instance()
	if category == "missile":
		impact_area.scale = Vector2( 1, 1 )
		impact_location = impact_location * Vector2(.2, .2)
	elif category == "projectile":
		impact_area.scale = Vector2( .2, .2 )
		impact_location = Vector2(x_pos, y_pos)
	new_impact.position = impact_location
	impact_area.add_child(new_impact)
	
	
func on_destroy():
	get_node("Area2D").queue_free()
	yield(get_tree().create_timer(0.2), "timeout")
	self.queue_free()


## TODO MW - fix this? somehow
func _on_Area2D_body_entered(body):
	if body.is_in_group("Projectiles"):
		on_hit(body.damage, "missile")
		body.queue_free()
