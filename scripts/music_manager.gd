extends Node

var music_player: AudioStreamPlayer


func _ready() -> void:
	print("MUSIC MANAGER IS RUNNING")

	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)



func play_menu_music() -> void:
	var music = load("res://assets/audio/music/main_menu.mp3")

	if music == null:
		push_error("Main menu music not found")
		return

	music_player.stream = music
	music_player.volume_db = -12.0
	music_player.play()

func play_level_music(level_number: int) -> void:
	var music_path := "res://assets/audio/music/lvl%d.mp3" % level_number

	print("Trying to load: ", music_path)

	var music = load(music_path)

	if music == null:
		print("ERROR: MUSIC FILE NOT FOUND")
		return

	print("Music loaded successfully: ", music)

	# If music is already playing, fade it out first.
	if music_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(
			music_player,
			"volume_db",
			-30.0,
			1.5
		)

		await fade_out.finished

	# Change to the new song.
	music_player.stream = music
	music_player.volume_db = -30.0
	music_player.play()

	# Fade the new song in.
	var fade_in := create_tween()
	fade_in.tween_property(
		music_player,
		"volume_db",
		-12.0,
		1.5
	)

	print("Music playback started")
