extends CanvasLayer

@onready var texture_rect: TextureRect = $TextureRect

var images = [
	preload("res://cutscenes/opening/op_1.png"),
	preload("res://cutscenes/opening/op_2.png"),
	preload("res://cutscenes/opening/op_3.png"),
	preload("res://cutscenes/opening/op_4.png"),
	preload("res://cutscenes/opening/op_5.png"),
	preload("res://cutscenes/opening/op_6.png")
]

var current_image: int = 0
var skipping: bool = false
var fade_rect: ColorRect
var input_enabled: bool = false

func _ready() -> void:
	MusicManager.play_level_music(1)

	texture_rect.texture = images[0]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 0.0

	# BLACK TRANSITION OVERLAY
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0

	fade_rect.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fade_rect)

	# Allow the new scene to finish loading.
	await get_tree().process_frame

	# Fade OP_1 in.
	var opening_fade := create_tween()

	opening_fade.set_trans(Tween.TRANS_SINE)
	opening_fade.set_ease(Tween.EASE_IN_OUT)

	opening_fade.tween_property(
		texture_rect,
		"modulate:a",
		1.0,
		1.5
	)

	await opening_fade.finished

	# Only NOW accept keyboard/mouse input.
	input_enabled = true

	# Start the actual opening sequence.
	play_opening()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if skipping:
		return

	if event is InputEventKey and event.pressed and not event.echo:

		# ALT is ignored so Alt+F4 still works normally.
		if event.keycode == KEY_ALT:
			return

		if current_image < 5:
			skip_to_controls()

		elif current_image == 5:
			skipping = true

			await fade_to_black(0.5)

			start_game()

	elif event is InputEventMouseButton and event.pressed:

		if current_image < 5:
			skip_to_controls()

		elif current_image == 5:
			skipping = true

			await fade_to_black(0.5)

			start_game()


func play_opening() -> void:

	# ==========================================
	# OP_1
	# ESTABLISHING SHOT
	# ==========================================

	current_image = 0

	texture_rect.texture = images[0]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		texture_rect,
		"modulate:a",
		0.96,
		2.5
	)

	tween.tween_property(
		texture_rect,
		"modulate:a",
		1.0,
		2.5
	)

	await tween.finished

	if skipping:
		return


	# ==========================================
	# OP_2
	# DIALOGUE
	# ==========================================

	current_image = 1

	texture_rect.texture = images[1]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0

	await get_tree().create_timer(5.5).timeout

	if skipping:
		return


	# ==========================================
	# OP_3
	# TELEPORTATION ACTIVATES
	# ==========================================

	current_image = 2

	texture_rect.texture = images[2]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0

	await get_tree().create_timer(1.0).timeout

	if skipping:
		return


	# ==========================================
	# OP_3 → WHITEOUT
	# ==========================================

	current_image = 3

	var white := ColorRect.new()

	white.color = Color.WHITE
	white.color.a = 0.0

	white.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(white)

	var tween_white := create_tween()

	tween_white.set_trans(Tween.TRANS_SINE)
	tween_white.set_ease(Tween.EASE_IN)

	tween_white.tween_property(
		white,
		"color:a",
		1.0,
		2.0
	)

	await tween_white.finished

	if skipping:
		white.queue_free()
		return


	# ==========================================
	# OP_4
	# COMPLETE WHITEOUT
	# ==========================================

	texture_rect.texture = images[3]

	await get_tree().create_timer(0.8).timeout

	if skipping:
		white.queue_free()
		return


	# ==========================================
	# OP_4 → OP_5
	# TELEPORTATION FINISHES
	# ==========================================

	current_image = 4

	texture_rect.texture = images[4]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE

	var reveal := create_tween()

	reveal.set_trans(Tween.TRANS_SINE)
	reveal.set_ease(Tween.EASE_OUT)

	reveal.tween_property(
		white,
		"color:a",
		0.0,
		2.0
	)

	await reveal.finished

	white.queue_free()

	if skipping:
		return


	# ==========================================
	# OP_5
	# AFTER TELEPORTATION
	# ==========================================

	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0

	var breathe := create_tween()

	breathe.set_trans(Tween.TRANS_SINE)
	breathe.set_ease(Tween.EASE_IN_OUT)

	breathe.tween_property(
		texture_rect,
		"modulate:a",
		0.97,
		1.5
	)

	breathe.tween_property(
		texture_rect,
		"modulate:a",
		1.0,
		1.5
	)

	await breathe.finished

	if skipping:
		return

	await get_tree().create_timer(1.5).timeout

	if skipping:
		return


	# ==========================================
	# OP_6
	# CONTROLS / OBJECTIVE
	# ==========================================

	show_controls()


func skip_to_controls() -> void:
	if skipping:
		return

	skipping = true

	# Fade the entire screen to black.
	await fade_to_black(0.5)

	# Show controls while the screen is black.
	show_controls()

	# Fade the controls image back in.
	await fade_from_black(0.5)


func show_controls() -> void:
	current_image = 5

	texture_rect.texture = images[5]
	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0

	# Automatically start the game after 8 seconds.
	_auto_start_after_controls()


func _auto_start_after_controls() -> void:
	await get_tree().create_timer(8.0).timeout

	# If the player hasn't manually started the game,
	# fade smoothly to black and start it.
	if current_image == 5:
		skipping = true

		await fade_to_black(0.5)

		start_game()


func fade_to_black(duration: float) -> void:
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		duration
	)

	await tween.finished


func fade_from_black(duration: float) -> void:
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_rect,
		"color:a",
		0.0,
		duration
	)

	await tween.finished


func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
