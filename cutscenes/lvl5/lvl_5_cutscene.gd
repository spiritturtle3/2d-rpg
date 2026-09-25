extends CanvasLayer

signal finished

@onready var texture_rect: TextureRect = $TextureRect

var skipping: bool = false
var fade_rect: ColorRect


func _ready() -> void:
	# ------------------------------------------
	# SETUP ENDING CUTSCENE IMAGE
	# ------------------------------------------

	texture_rect.texture = preload(
		"res://cutscenes/lvl5/lvl5.png"
		
	)

	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate = Color.WHITE


	# ------------------------------------------
	# BLACK FADE OVERLAY
	# ------------------------------------------

	fade_rect = ColorRect.new()

	fade_rect.color = Color.BLACK
	fade_rect.color.a = 1.0

	fade_rect.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fade_rect)


	# ------------------------------------------
	# FADE INTO ENDING
	# ------------------------------------------

	var fade_in := create_tween()

	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)

	fade_in.tween_property(
		fade_rect,
		"color:a",
		0.0,
		1.0
	)

	await fade_in.finished

	if skipping:
		return


	# ------------------------------------------
	# DISPLAY ENDING
	# ------------------------------------------

	await get_tree().create_timer(7.0).timeout

	if skipping:
		return


	# ------------------------------------------
	# FADE TO BLACK
	# ------------------------------------------

	await fade_to_black(2.0)

	if skipping:
		return

	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not skipping:
		skipping = true

		await fade_to_black(1.0)

		finished.emit()


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
