extends Node

var health: int = 100
var max_health: int = 100
var god_blessing: bool = false
var boss_defeated: bool = false

func reset() -> void:
	health = max_health
