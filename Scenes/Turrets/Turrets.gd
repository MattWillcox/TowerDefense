extends Node2D

var type
var enemy_array = []
var built = false
var enemy
var ready = true
var category

func _ready():
	if built:
		self.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * GameData.tower_data[type].range

func _physics_process(_delta):
	if enemy_array.size() != 0 and built:
		select_enemy()
		if category == "projectile" && not get_node("AnimationPlayer").is_playing():
			turn()
		elif category == "missile":
			turn()
		if ready:
			fire()
	else:
		enemy = null
	
func turn():
	get_node("Turret").look_at(enemy.position)

func select_enemy():
	enemy = enemy_array[0]
	
func fire():
	ready = false
	if category == "projectile":
		fire_gun()
		enemy.on_hit(GameData.tower_data[type]["damage"], "projectile")
	elif category == "missile":
		fire_missile()
	yield(get_tree().create_timer(GameData.tower_data[type]["rof"]), "timeout")
	ready = true
	
	
func fire_gun():
	get_node("AnimationPlayer").play("Fire")
	get_node("AudioStreamPlayer").play()
	
func fire_missile():
	var projectiles_node = get_node("../../Projectiles")
	var map_node = projectiles_node.get_parent()
	var missile = load("res://Scenes/Projectiles/MissileProjectile.tscn").instance()
	var current_tile = map_node.get_node("TowerExclusion").world_to_map(get_node("Turret").global_position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_world(current_tile)
	missile.position = tile_position
	missile.position = position + Vector2(32, 32)
	missile.look_at(enemy.position)
	missile.target = enemy
	missile.on_route = true
	missile.damage = GameData.tower_data[type]["damage"]
	get_node("../../Projectiles").add_child(missile, true)
	get_node("AudioStreamPlayer").play()

func _on_Range_area_entered(area):
	if area.is_in_group("Enemies"):
		enemy_array.append(area.get_parent())

func _on_Range_area_exited(area):
	if area.is_in_group("Enemies"):
		enemy_array.erase(area.get_parent())
