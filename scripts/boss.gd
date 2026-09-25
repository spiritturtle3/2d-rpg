extends CharacterBody2D

signal health_changed(new_health: int)
signal died

const STRENGTH: int = 16
const SPEED: float = 120.0
const TELEPORT_DISTANCE: float = 500.0
const TELEPORT_INTERVAL: float = 8.0
const TELEPORT_OFFSET: float = 120.0

var is_teleporting: bool = false
var teleport_timer: float = 0.0
var target: Node2D = null
var is_alive: bool = true
var is_attacking: bool = false
var target_in_range: bool = false
var hitbox_offset: Vector2
var last_attack_frame: int = -1
const MAX_HEALTH: int = 750
var health: int = MAX_HEALTH

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D

@onready var boss_health_bar = get_tree().current_scene.get_node("HUD/BossHealthBar")


func _ready() -> void:
	hitbox_offset = hitbox.position
	teleport_timer = TELEPORT_INTERVAL



func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Teleport cooldown
	if teleport_timer > 0.0:
		teleport_timer -= delta

	# Don't do anything while teleporting
	if is_teleporting:
		velocity = Vector2.ZERO
		return

	# Check teleport distance
	if target and teleport_timer <= 0.0:
		var distance: float = global_position.distance_to(target.global_position)

		if distance >= TELEPORT_DISTANCE:
			teleport_beside_player()
			return

	if is_attacking:
		velocity = Vector2.ZERO

		if animated_sprite_2d.frame != last_attack_frame:
			last_attack_frame = animated_sprite_2d.frame

			if animated_sprite_2d.frame == 3 or animated_sprite_2d.frame == 9:
				deal_attack_damage()

		return

	if target:
		if target_in_range:
			velocity = Vector2.ZERO

			if $AttackTimer.time_left <= 0.0:
				attack()
		else:
			chase_player()
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.play("idle2")

	move_and_slide()


func chase_player() -> void:
	
	var direction: Vector2 = (
		target.global_position - global_position
	).normalized()

	velocity = direction * SPEED

	if target.global_position.x < global_position.x:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false

	update_hitbox()
	update_body_collision()
	animated_sprite_2d.play("idle2")


func teleport_beside_player() -> void:
	if not target:
		return

	if teleport_timer > 0.0:
		return

	if is_teleporting:
		return

	is_teleporting = true
	velocity = Vector2.ZERO

	# Start teleport animation
	animated_sprite_2d.play("skill1")

	# Wait until frame 7
	while animated_sprite_2d.frame < 7:
		await animated_sprite_2d.frame_changed

	# Let frame 7 actually be displayed at the old position
	await get_tree().process_frame

	# --------------------------------
	# TELEPORT
	# --------------------------------

	var directions: Array[Vector2] = [
		Vector2.LEFT,
		Vector2.RIGHT
	]

	directions.shuffle()

	for direction in directions:
		var teleport_position: Vector2 = (
			target.global_position + direction * TELEPORT_OFFSET
		)

		if not _position_is_blocked(teleport_position):
			global_position = teleport_position

			if direction == Vector2.LEFT:
				animated_sprite_2d.flip_h = false
			else:
				animated_sprite_2d.flip_h = true

			update_hitbox()
			update_body_collision()
			break

	# --------------------------------
	# FINISH SKILL1
	# --------------------------------

	await animated_sprite_2d.animation_finished

	is_teleporting = false
	teleport_timer = TELEPORT_INTERVAL


func _position_is_blocked(position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = collision_mask
	query.exclude = [self]

	return space_state.intersect_point(query).size() > 0

func update_hitbox() -> void:
	if animated_sprite_2d.flip_h:
		hitbox.position.x = -hitbox_offset.x
	else:
		hitbox.position.x = hitbox_offset.x


func update_body_collision() -> void:
	if animated_sprite_2d.flip_h:
		body_collision.position.x = 32.0
	else:
		body_collision.position.x = -32.0


func take_damage(amount: int, _attacker_position: Vector2) -> void:
	if not is_alive:
		return

	health -= amount
	health_changed.emit(health)

	if boss_health_bar:
		boss_health_bar.update_health(health)

	if health <= 0:
		die()

func die() -> void:
	if not is_alive:
		return

	is_alive = false
	PlayerStats.boss_defeated = true
	is_attacking = false
	target = null
	velocity = Vector2.ZERO
	if boss_health_bar:
		boss_health_bar.hide_bar()

	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	
	animated_sprite_2d.play("death")
	died.emit()

func attack() -> void:
	if not is_alive:
		return

	if is_attacking:
		return

	if not target:
		return

	if $AttackTimer.time_left > 0.0:
		return

	is_attacking = true
	last_attack_frame = -1
	velocity = Vector2.ZERO

	if target.global_position.x < global_position.x:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false

	update_hitbox()
	update_body_collision()

	animated_sprite_2d.play("attacking")
		
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "attacking":
		is_attacking = false

		$AttackTimer.start()

		if not target or not target_in_range:
			animated_sprite_2d.play("idle2")

func deal_attack_damage() -> void:
	if not is_alive:
		return

	if target and target_in_range:
		target.take_damage(STRENGTH)

func _on_attack_timer_timeout() -> void:
	if not is_alive:
		return

	if target and target_in_range:
		attack()
		
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

		if boss_health_bar:
			boss_health_bar.show_bar()



func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = true
			

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		
