extends Node2D

signal game_finished(result)

var map_node

var build_mode = false
var build_valid = false
var build_tile
var build_location
var build_type

var current_wave = 0
var enemies_in_wave = 0

var base_health = 20

var current_money = 100

func _ready():
	map_node = get_node("Map1")
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])
	get_node("Music").play()
	get_node("UI/HUD/BuildBar/Gun/Cost").text = "$" + str(GameData.tower_data.GunT1.cost)
	get_node("UI/HUD/BuildBar/Missile/Cost").text = "$" + str(GameData.tower_data.MissileT1.cost)
	get_node("UI").connect("times_up", self, "on_times_up")
	
func _process(delta):
	if build_mode:
		update_tower_preview()

func _unhandled_input(event):
	if event.is_action_released("ui_cancel") and build_mode == true:
		cancel_build_mode()
	if event.is_action_released("ui_accept") and build_mode == true:
		verify_and_build()
		cancel_build_mode()

##
## Wave Functions
##
func start_next_wave():
	var wave_data = retrieve_wave_data()
	var preview_sprite = get_node("UI/HUD/InfoBar/H/NextWaveTexture")
	if current_wave < EnemyData.enemy_data.size():
		preview_sprite.texture = load(EnemyData.enemy_data[current_wave].sprite)
	else:
		preview_sprite.texture = load("res://icon.png")
	yield(get_tree().create_timer(0.2), "timeout") ## padding between waves so they do not start insta
	spawn_enemies(wave_data)

func retrieve_wave_data():
	var enemy_data = EnemyData.enemy_data[current_wave - 1]
	var wave_data = []
	var wave_enemies = enemy_data.total_enemies
	for i in (enemy_data.total_enemies - 1):
		wave_data.append([enemy_data.name, enemy_data.spawn_rate, enemy_data.money_reward, enemy_data.hp, enemy_data.sprite])
	enemies_in_wave = wave_data.size()
	return wave_data

func spawn_enemies(wave_data):
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i[0] + ".tscn").instance()
		new_enemy.get_node("Sprite").texture = load(i[4])
		new_enemy.connect("base_damage", self, "on_base_damage")
		new_enemy.connect("increase_money", self, "on_increase_money", [i[2]])
		new_enemy.connect("enemy_killed", self, "on_enemy_killed")
		new_enemy.hp = i[3]
		map_node.get_node("Path").add_child(new_enemy, true)
		yield(get_tree().create_timer(i[1]), "timeout")

##
## Building Functions
##
func initiate_build_mode(tower_type):
	if build_mode:
		cancel_build_mode()
	build_type = tower_type + "T1"
	build_mode = true
	get_node("UI").set_tower_preview(build_type, get_global_mouse_position())
	
func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	var current_tile = map_node.get_node("TowerExclusion").world_to_map(mouse_position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_world(current_tile)
	var cost = GameData.tower_data[build_type].cost
	
	if map_node.get_node("TowerExclusion").get_cellv(current_tile) == -1 && current_money >= cost:
		get_node("UI").update_tower_preview(tile_position, "ad54ff3c")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		get_node("UI").update_tower_preview(tile_position, "adff4545")
		build_valid = false
		
func cancel_build_mode():
	build_mode = false
	build_valid = false
	get_node("UI/TowerPreview").free()
	
func verify_and_build():
	if build_valid:
		var cost = GameData.tower_data[build_type].cost
		if current_money >= cost:
			var new_tower = load("res://Scenes/Turrets/" + build_type + ".tscn").instance()
			new_tower.position = build_location
			new_tower.built = true
			new_tower.type = build_type
			new_tower.category = GameData.tower_data[build_type].category
			map_node.get_node("Turrets").add_child(new_tower, true)
			map_node.get_node("TowerExclusion").set_cellv(build_tile, 5)
			current_money -= cost
			get_node("UI").update_money(current_money)


##
## Handlers
##
func on_times_up():
	if enemies_in_wave > 0:
		print("enemies_in_wave", enemies_in_wave)
		on_base_damage(enemies_in_wave)
	for i in map_node.get_node("Path").get_children():
		i.queue_free()
	
func on_base_damage(damage):
	base_health -= damage
	if base_health <= 0:
		get_node("UI").update_health_bar(0)
		get_node("UI").game_over = true
		get_node("UI/HUD/GameOver").visible = true
		
		yield(get_tree().create_timer(10), "timeout")
		emit_signal("game_finished", false)
	else:
		get_node("UI").update_health_bar(base_health)
		
func on_increase_money(amount):
	current_money += amount
	get_node("UI").update_money(current_money)

func on_enemy_killed():
	enemies_in_wave -= 1
	if enemies_in_wave == 0:
		get_node("UI").end_wave()
