extends CharacterBody2D
signal died


const SPEED: int = 150
var target: Node2D = null
var health: int = 100
var is_alive: bool = true
var strength: int = 10
var target_in_range: bool = false

var is_knocked_back: bool = false
var knockback_timer: float = 0.0

const KNOCKBACK_SPEED: float = 220.0
const KNOCKBACK_DURATION: float = 0.4

const DROP_CHANCE: float = 0.7
var health_pickup_scene = preload("res://scenes/health_pickup.tscn")


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer




func _physics_process(delta: float) -> void:

	if not is_alive:
		return

	# Knockback
	if is_knocked_back:
		move_and_slide()

		knockback_timer -= delta

		if knockback_timer <= 0.0:
			is_knocked_back = false
			velocity = Vector2.ZERO

		return

	# Chase the player
	if target:
		_attack(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()    


func _attack(_delta: float) -> void:
	var direction := (target.position - position).normalized()

	velocity = direction * SPEED

	animated_sprite_2d.play("attack")

func take_damage(damage: int, attacker_position: Vector2) -> void:
	health -= damage
	health_bar.update_health(health)
	if health <= 0:
		_die()
	else:
		take_damage_sound.play()
		# Knockback
		var knockback_direction := (position - attacker_position).normalized()

		velocity = knockback_direction * KNOCKBACK_SPEED
		is_knocked_back = true
		knockback_timer = KNOCKBACK_DURATION
	

func _die() -> void:
	is_alive = false
	$ObjectiveMarker.visible = false
	animated_sprite_2d.play("die")
	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false
	
	if randf() <= DROP_CHANCE:
		drop_item()
	died.emit()
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body


func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = null
		animated_sprite_2d.play("idle")


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = true
		body.take_damage(strength)
		attack_timer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if target and target_in_range:
		target.take_damage(strength)
		

func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.position = position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)

func show_objective_marker() -> void:
	$ObjectiveMarker.visible = true


func hide_objective_marker() -> void:
	$ObjectiveMarker.visible = false
