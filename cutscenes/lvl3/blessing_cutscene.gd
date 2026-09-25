extends CanvasLayer

signal finished

@onready var texture_rect: TextureRect = $TextureRect

var fade_rect: ColorRect


func _ready() -> void:
	layer = 100

	# ------------------------------------------
	# SETUP CUTSCENE
	# ------------------------------------------

	texture_rect.texture = preload(
		"res://cutscenes/lvl3/ct_1.png"
	)

	texture_rect.position = Vector2.ZERO
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate = Color.WHITE


	# ------------------------------------------
	# BLACK OVERLAY
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
	# FADE INTO CT1
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


	# ------------------------------------------
	# DISPLAY CT1
	# ------------------------------------------

	await get_tree().create_timer(3.0).timeout


	# ------------------------------------------
	# FADE CT1 TO BLACK
	# ------------------------------------------

	var fade_to_black := create_tween()

	fade_to_black.set_trans(Tween.TRANS_SINE)
	fade_to_black.set_ease(Tween.EASE_IN_OUT)

	fade_to_black.tween_property(
		fade_rect,
		"color:a",
		1.0,
		0.8
	)

	await fade_to_black.finished


	# ------------------------------------------
	# CHANGE TO CT2 WHILE SCREEN IS BLACK
	# ------------------------------------------

	texture_rect.texture = preload(
		"res://cutscenes/lvl3/ct_2.png"
	)


	# ------------------------------------------
	# FADE CT2 IN
	# ------------------------------------------

	var fade_ct2_in := create_tween()

	fade_ct2_in.set_trans(Tween.TRANS_SINE)
	fade_ct2_in.set_ease(Tween.EASE_IN_OUT)

	fade_ct2_in.tween_property(
		fade_rect,
		"color:a",
		0.0,
		0.8
	)

	await fade_ct2_in.finished


	# ------------------------------------------
	# DISPLAY CT2
	# 8 SECONDS FOR ORACLE TEXT
	# ------------------------------------------

	await get_tree().create_timer(8.0).timeout


	# ------------------------------------------
	# FADE OUT
	# ------------------------------------------

	var final_fade := create_tween()

	final_fade.set_trans(Tween.TRANS_SINE)
	final_fade.set_ease(Tween.EASE_IN_OUT)

	final_fade.tween_property(
		fade_rect,
		"color:a",
		1.0,
		1.0
	)

	await final_fade.finished


	# ------------------------------------------
	# CUTSCENE COMPLETE
	# ------------------------------------------

	finished.emit()
