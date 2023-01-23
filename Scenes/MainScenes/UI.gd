extends CanvasLayer

signal times_up()

onready var hp_bar = get_node("HUD/InfoBar/H/HP")
onready var hp_bar_tween = get_node("HUD/InfoBar/H/HP/Tween")
onready var money = get_node("HUD/InfoBar/H/Money")
onready var start_wave = get_node("HUD/StartWave")
onready var round_timer = get_node("HUD/InfoBar/H/TimeRemaining/Timer")
onready var round_timer_label = get_node("HUD/InfoBar/H/TimeRemaining")

var round_time = 30
var wave_started = false

func set_tower_preview(tower_type, mouse_position):
	var drag_tower = load("res://Scenes/Turrets/" + tower_type + ".tscn").instance()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("ad54ff3c")
	
	var range_texture = Sprite.new()
	range_texture.position = Vector2(32, 32)
	var scaling = GameData.tower_data[tower_type].range / 600.0
	range_texture.scale = Vector2(scaling, scaling)
	var texture = load("res://Assets/UI/range_overlay.png")
	range_texture.texture = texture
	range_texture.modulate = Color("ad54ff3c")
	
	var control = Control.new()
	control.add_child(drag_tower, true)
	control.add_child(range_texture, true)
	control.rect_position = mouse_position
	control.set_name("TowerPreview")
	add_child(control, true)
	move_child(get_node("TowerPreview"), 0)

func update_tower_preview(new_position, color):
	get_node("TowerPreview").rect_position = new_position
	if get_node("TowerPreview/DragTower").modulate != Color(color):
		get_node("TowerPreview/DragTower").modulate = Color(color)
		get_node("TowerPreview/Sprite").modulate = Color(color)

##
## Game Control Functions
##
func _on_PausePlay_pressed():
	if get_parent().build_mode:
		get_parent().cancel_build_mode()
	if get_tree().is_paused():
		get_tree().paused = false
	else:
		get_tree().paused = true


func _on_SpeedUp_pressed():
	if get_parent().build_mode:
		get_parent().cancel_build_mode()
	if Engine.get_time_scale() == 2.0:
		Engine.set_time_scale(1.0)
	else:
		Engine.set_time_scale(2.0)

func update_health_bar(base_health):
	hp_bar_tween.interpolate_property(hp_bar, 'value', hp_bar.value, base_health, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	hp_bar_tween.start()
	if base_health >= 60:
		hp_bar.set_tint_progress("0efd28")
	elif base_health <= 60 and base_health >= 25:
		hp_bar.set_tint_progress("e1be32")
	else:
		hp_bar.set_tint_progress("e11e1e")

func update_money(current_money):
	money.text = str(current_money)
	

func _on_Replay_pressed():
	get_parent().current_wave == 0
	get_parent().start_next_wave()


func _on_StartWave_pressed():
	wave_started = true
	start_wave.visible = not visible
	get_parent().current_wave += 1
	get_parent().start_next_wave()
	round_timer.start()

func end_wave():
	wave_started = false
	start_wave.visible = visible
	round_time = 30
	round_timer_label.text = str(round_time)
	

func _on_Timer_timeout():
	if !wave_started:
		return
	if round_time >= 1:
		round_time -= 1
		round_timer_label.text = str(round_time)
		if round_time == 0:
			end_wave()
			emit_signal("times_up")
