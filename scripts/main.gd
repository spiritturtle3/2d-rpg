extends Node2D
@onready var hud: CanvasLayer = $HUD

var level: int = 1
var current_level_root: Node = null
var objective_completed: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_level_root = get_node("LevelRoot")

	_load_level(level)
	
	

#-----------------------------------------------------------------
#LEVEL MANAGEMENT
#-----------------------------------------------------------------

func _load_level(level_number: int) -> void:
	#objective_completed = not _level_has_objective(level_number)
	if current_level_root:
		current_level_root.queue_free()
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	if level_number == 5:
		MusicManager.play_level_music(5)
	_setup_level(current_level_root)

func _play_level_2_cutscene() -> void:
	var cutscene_scene = preload("res://cutscenes/lvl2/lvl_2_cutscene.tscn")
	var cutscene = cutscene_scene.instantiate()
	
	MusicManager.play_level_music(2)
	
	add_child(cutscene)

	# Wait until the cutscene finishes.
	# The cutscene should emit a "finished" signal when it reaches
	# the end of its final image.
	await cutscene.finished

	cutscene.queue_free()

	_load_level(2)

func _play_level_3_cutscene() -> void:
	var cutscene_scene = preload("res://cutscenes/lvl3/lvl_3_cutscene.tscn")
	var cutscene = cutscene_scene.instantiate()

	MusicManager.play_level_music(3)
	
	add_child(cutscene)

	await cutscene.finished

	cutscene.queue_free()

	_load_level(3)

func _play_god_blessing_cutscene() -> void:
	var cutscene_scene = preload(
		"res://cutscenes/lvl3/blessing_cutscene.tscn"
	)

	var cutscene = cutscene_scene.instantiate()

	# Add the cutscene on top of the currently running Level 3.
	add_child(cutscene)

	# Wait until the blessing cutscene finishes.
	await cutscene.finished

	# Remove only the cutscene.
	# Level 3 remains exactly where it was.
	cutscene.queue_free()

func _play_level_4_cutscene() -> void:
	var cutscene_scene = preload("res://cutscenes/lvl4/lvl_4_cutscene.tscn")

	var cutscene = cutscene_scene.instantiate()
	
	MusicManager.play_level_music(4)
	
	add_child(cutscene)

	# Wait until the Level 4 cutscene finishes.
	await cutscene.finished

	cutscene.queue_free()

	_load_level(4)

func _play_ending_cutscene() -> void:
	var cutscene_scene = preload(
		"res://cutscenes/lvl5/lvl_5_cutscene.tscn"
		
	)

	var cutscene = cutscene_scene.instantiate()
	
	add_child(cutscene)

	# Wait until the ending cutscene finishes.
	await cutscene.finished

	# Keep the cutscene on screen.
	# It has already faded completely to black.
	_complete_game()

func _setup_level(level_root: Node) -> void:
	
	var player = level_root.get_node("Player")
	$HUD.set_player(player)
	player.died.connect(_on_player_died)
	
	# Boss already defeated this playthrough
	if PlayerStats.boss_defeated:
		var boss = level_root.get_node_or_null("Enemies/Boss")

		if boss:
			boss.queue_free()
	
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
		
	var target = _get_level_target(level_root)

	if target:
		objective_completed = false
		target.died.connect(_on_target_died)

		# Only show the objective marker if this enemy supports it.
		if target.has_method("show_objective_marker"):
			target.show_objective_marker()
	else:
		objective_completed = true

		if exit:
			exit.unlock(player)


func _get_level_target(level_root: Node) -> Node:
	match level:
		1:
			return level_root.get_node("Enemies/Slime17")

		2:
			return level_root.get_node("Enemies/Skeleton_Big")

		4:
			if PlayerStats.boss_defeated:
				return null

			return level_root.get_node("Enemies/Boss")

		_:
			return null


#------------------------------------------------------------------
#SIGNAL HANDLER
#-----------------------------------------------------------------

func _on_exit_body_entered(body: Node2D) -> void:
	if body.name != "Player" or not objective_completed:
		return

	# Stop this exit from being triggered repeatedly.
	var exit = current_level_root.get_node_or_null("Exit")
	if exit:
		exit.set_deferred("monitoring", false)

	# Stop enemies from chasing/attacking while the transition happens.
	var enemies = current_level_root.get_node_or_null("Enemies")
	if enemies:
		enemies.process_mode = Node.PROCESS_MODE_DISABLED

	# Level 5 is the final level.
	if level == 5:
		call_deferred("_play_ending_cutscene")
		return

	level += 1

	# Play the appropriate cutscene before loading the next level.
	if level == 2:
		call_deferred("_play_level_2_cutscene")
	elif level == 3:
		call_deferred("_play_level_3_cutscene")
	elif level == 4:
		call_deferred("_play_level_4_cutscene")
	else:
		call_deferred("_load_level", level)

func _complete_game() -> void:
	print("GAME COMPLETE!")

	get_tree().paused = false

	# Give the ending cutscene a moment to settle on black.
	await get_tree().create_timer(1.0).timeout

	get_tree().change_scene_to_file(
		"res://scenes/main_menu.tscn"
	)

func _on_player_died() -> void:
	await hud.fade(1.0)

	# Reset boss health bar
	var boss_health_bar = $HUD.get_node("BossHealthBar")
	boss_health_bar.hide_bar()
	boss_health_bar.update_health(750)

	
	PlayerStats.reset()
	_load_level(level)

	await hud.fade(0.0)


func _on_target_died() -> void:
	objective_completed = true
	
	var exit = current_level_root.get_node("Exit")
	var player = current_level_root.get_node("Player")

	exit.unlock(player)
