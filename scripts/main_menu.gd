extends Control

var starting := false
var fade_rect: ColorRect

@onready var press_any_button: Label = $PressAnyButton

func _ready() -> void:
	MusicManager.play_menu_music()
	
	# ------------------------------------------
	# BLACK FADE-IN FROM ENDING
	# ------------------------------------------

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 1.0

	fade_rect.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fade_rect)

	await get_tree().process_frame

	var fade_in := create_tween()

	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)

	fade_in.tween_property(
		fade_rect,
		"color:a",
		0.0,
		1.5
	)

	await fade_in.finished

	fade_rect.queue_free()
	_flicker_press_button()


func _flicker_press_button() -> void:
	while not starting:
		var tween := create_tween()

		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(
			press_any_button,
			"modulate:a",
			0.25,
			0.8
		)

		tween.tween_property(
			press_any_button,
			"modulate:a",
			1.0,
			0.8
		)

		await tween.finished

		await get_tree().create_timer(0.4).timeout

func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed:
			return

		starting = true
		start_game()

	elif event is InputEventMouseButton and event.pressed:
		starting = true
		start_game()


func start_game() -> void:
	var fade := ColorRect.new()

	fade.color = Color.BLACK
	fade.color.a = 0.0

	fade.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fade)

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade,
		"color:a",
		1.0,
		1.0
	)

	await tween.finished

	get_tree().change_scene_to_file(
		"res://scenes/opening_cutscene.tscn"
	)
