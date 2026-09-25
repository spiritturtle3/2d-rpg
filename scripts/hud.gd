extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var hearts_container: HBoxContainer = $Hearts

@onready var prayer_popup: PanelContainer = $PrayerPopup
@onready var prayer_yes: Button = $PrayerPopup/DialogueContent/Yes
@onready var prayer_no: Button = $PrayerPopup/DialogueContent/No



var player
var prayer_open := false
var blessing_playing := false

const HEART_FULL = preload("res://assets/images/ui/Heart_Full.png")
const HEART_HALF = preload("res://assets/images/ui/Heart_Half.png")
const HEART_EMPTY = preload("res://assets/images/ui/Heart_Empty.png")
const HEART_SIZE: int = 20

func _ready() -> void:
	prayer_popup.hide()

	prayer_yes.pressed.connect(_on_prayer_yes)
	prayer_no.pressed.connect(_on_prayer_no)

	process_mode = Node.PROCESS_MODE_ALWAYS

func fade(to_alpha: float) -> void:
	var tween:= create_tween()
	tween.tween_property(color_rect, "modulate:a", to_alpha, 1.5)
	await tween.finished
	

func set_player(p) -> void:
	player = p
	if player:
		player.health_changed.connect(_update_health)
		_update_health(player.health)

func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = len(hearts)
	var full = int(new_health / HEART_SIZE)
	var half = 1 if (new_health % HEART_SIZE) > 0 else 0
	var empty = max_hearts - (full + half)
	for i in full:
		hearts[i].texture = HEART_FULL
	if half:
		hearts[full].texture = HEART_HALF
	for i in empty:
		hearts[len(hearts) - 1 - i].texture = HEART_EMPTY
	
func show_prayer_dialogue() -> void:
	if prayer_open:
		return

	# Don't show the prayer again after receiving the blessing
	if PlayerStats.god_blessing:
		return

	prayer_open = true
	prayer_popup.show()

	if player:
		player.dialogue_open = true


func hide_prayer_dialogue() -> void:
	prayer_popup.hide()
	prayer_open = false

	if player:
		player.dialogue_open = false


func _on_prayer_yes() -> void:
	if blessing_playing:
		return

	blessing_playing = true

	print("Player chose YES")
	print("God's blessing ceremony beginning...")

	# Give the player the blessing.
	PlayerStats.god_blessing = true

	# Close the prayer dialogue first.
	hide_prayer_dialogue()

	# Play the blessing cutscene over the current level.
	var cutscene_scene = preload(
		"res://cutscenes/lvl3/blessing_cutscene.tscn"
	)

	var cutscene = cutscene_scene.instantiate()

	# Add it to the HUD so it appears over the game.
	add_child(cutscene)

	# Wait until the blessing cutscene finishes.
	await cutscene.finished

	cutscene.queue_free()

	blessing_playing = false

	print("God's blessing ceremony finished.")


func _on_prayer_no() -> void:
	print("Player chose NO")
	hide_prayer_dialogue()
	
