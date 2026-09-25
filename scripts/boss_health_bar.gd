extends Node2D

@export var max_health: int = 750

@onready var health_bar: Sprite2D = $over

var default_scale_x: float
var default_position: Vector2


func _ready() -> void:
	visible = false

	health_bar.centered = false

	default_scale_x = health_bar.scale.x
	default_position = health_bar.position

	update_health(max_health)


func show_bar() -> void:
	visible = true


func hide_bar() -> void:
	visible = false


func update_health(new_health: int) -> void:
	new_health = clamp(new_health, 0, max_health)

	var health_percent := float(new_health) / float(max_health)

	health_bar.position = default_position
	health_bar.scale.x = default_scale_x * health_percent

func reset_bar() -> void:
	update_health(max_health)
	hide_bar()
