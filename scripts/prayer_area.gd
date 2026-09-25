extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var hud = get_tree().get_first_node_in_group("hud")

		if hud:
			hud.show_prayer_dialogue()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		var hud = get_tree().get_first_node_in_group("hud")

		if hud:
			hud.hide_prayer_dialogue()
