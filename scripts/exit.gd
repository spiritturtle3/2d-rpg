extends Area2D

@onready var blocker: StaticBody2D = $Blocker
@onready var blocker_collision: CollisionShape2D = $Blocker/CollisionShape2D

func unlock(player: Node2D) -> void:
	if player:
		blocker.add_collision_exception_with(player)
