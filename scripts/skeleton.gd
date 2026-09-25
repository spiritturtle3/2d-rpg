extends CharacterBody2D
signal died

# ---------------------------------------------------------
# STATS
# ---------------------------------------------------------

const SPEED: int = 120
const MAX_HEALTH: int = 150
const STRENGTH: int = 25
const KNOCKBACK_FORCE: int = 100
var can_damage_player: bool = false

var health: int = MAX_HEALTH
var target: Node2D = null

var is_alive: bool = true
var is_attacking: bool = false
var target_in_range: bool = false

var last_direction: Vector2 = Vector2.DOWN
var is_knocked_back: bool = false
var knockback_timer: float = 0.0

const KNOCKBACK_SPEED: float = 220.0
const KNOCKBACK_DURATION: float = 0.4


# ---------------------------------------------------------
# NODES
# ---------------------------------------------------------

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer

@onready var skeleton_health_bar: Sprite2D = $HealthBar/Health
@onready var skeleton_health_bar_width: float = $HealthBar/Health.region_rect.size.x
@onready var skeleton_health_bar_height: float = $HealthBar/Health.region_rect.size.y


# ---------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------


func _physics_process(_delta: float) -> void:

	if not is_alive:
		return
	if is_knocked_back:
		move_and_slide()

		knockback_timer -= _delta

		if knockback_timer <= 0.0:
			is_knocked_back = false
			velocity = Vector2.ZERO

		return
	# Don't move while attacking
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Chase the player
	if target:
		if target_in_range:
			velocity = Vector2.ZERO
			update_direction((target.position - position).normalized())
		else:
			chase_player()
	else:
		velocity = Vector2.ZERO
		play_idle()

	move_and_slide()


# ---------------------------------------------------------
# CHASING
# ---------------------------------------------------------

func chase_player() -> void:

	var direction := (target.position - position).normalized()

	velocity = direction * SPEED

	update_direction(direction)
	play_run()


# ---------------------------------------------------------
# DIRECTION
# ---------------------------------------------------------

func update_direction(direction: Vector2) -> void:

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			last_direction = Vector2.RIGHT
		else:
			last_direction = Vector2.LEFT

	else:

		if direction.y > 0:
			last_direction = Vector2.DOWN
		else:
			last_direction = Vector2.UP


# ---------------------------------------------------------
# IDLE ANIMATION
# ---------------------------------------------------------

func play_idle() -> void:

	if last_direction.x != 0:

		animated_sprite_2d.flip_h = last_direction.x < 0
		animated_sprite_2d.play("idle_right")

	elif last_direction == Vector2.UP:

		animated_sprite_2d.play("idle_up")

	else:

		animated_sprite_2d.play("idle_down")


# ---------------------------------------------------------
# RUN ANIMATION
# ---------------------------------------------------------

func play_run() -> void:

	if last_direction.x != 0:

		animated_sprite_2d.flip_h = last_direction.x < 0
		animated_sprite_2d.play("run_right")

	elif last_direction == Vector2.UP:

		animated_sprite_2d.play("run_up")

	else:

		animated_sprite_2d.play("run_down")


# ---------------------------------------------------------
# ATTACK
# ---------------------------------------------------------

func attack() -> void:

	if not is_alive:
		return

	if is_attacking:
		return

	if not target:
		return

	is_attacking = true
	velocity = Vector2.ZERO

	# Face the player
	update_direction((target.position - position).normalized())

	play_attack()

	# Damage player once per attack
	if target_in_range:
		target.take_damage(STRENGTH)
	
   


# ---------------------------------------------------------
# ATTACK ANIMATION
# ---------------------------------------------------------

func play_attack() -> void:

	if last_direction.x != 0:

		animated_sprite_2d.flip_h = last_direction.x < 0
		animated_sprite_2d.play("attack_right")

	elif last_direction == Vector2.UP:

		animated_sprite_2d.play("attack_up")

	else:

		animated_sprite_2d.play("attack_down")


# ---------------------------------------------------------
# ANIMATION FINISHED
# ---------------------------------------------------------

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation.begins_with("attack"):
		is_attacking = false
		can_damage_player = false

		attack_timer.start()

		if target and target_in_range:
			await attack_timer.timeout

			if target and target_in_range and is_alive:
				attack()
		else:
			play_idle()

	elif animated_sprite_2d.animation == "die":
		animated_sprite_2d.pause()
	


# ---------------------------------------------------------
# SIGHT
# ---------------------------------------------------------

func _on_sight_body_entered(body: Node2D) -> void:

	if body.name == "Player":
		target = body


func _on_sight_body_exited(body: Node2D) -> void:

	if body.name == "Player":

		target = null
		target_in_range = false

		if is_alive and not is_attacking:
			play_idle()


# ---------------------------------------------------------
# HITBOX
# ---------------------------------------------------------

func _on_hitbox_body_entered(body: Node2D) -> void:

	if body.name == "Player":
		target_in_range = true

		if is_attacking and can_damage_player:
			body.take_damage(STRENGTH)
			can_damage_player = false

		elif not is_attacking:
			attack()


func _on_hitbox_body_exited(body: Node2D) -> void:

	if body.name == "Player":

		target_in_range = false


# ---------------------------------------------------------
# ATTACK TIMER
# ---------------------------------------------------------

func _on_attack_timer_timeout() -> void:

	if not is_alive:
		return

	if target and target_in_range:
		attack()


# ---------------------------------------------------------
# DAMAGE
# ---------------------------------------------------------

func take_damage(damage: int, attacker_position: Vector2) -> void:

	if not is_alive:
		return

	health -= damage

	var health_ratio = float(health) / MAX_HEALTH
	var new_width = skeleton_health_bar_width * health_ratio

	skeleton_health_bar.region_rect = Rect2(
	0,
	0,
	new_width,
	skeleton_health_bar_height
)

	if health <= 0:

		die()
		return

	take_damage_sound.play()

	# Knockback
	var knockback_direction := (position - attacker_position).normalized()

	velocity = knockback_direction * KNOCKBACK_SPEED
	is_knocked_back = true
	knockback_timer = KNOCKBACK_DURATION


# ---------------------------------------------------------
# DEATH
# ---------------------------------------------------------

func die() -> void:

	if not is_alive:
		return

	is_alive = false
	is_attacking = false
	target = null
	velocity = Vector2.ZERO

	animated_sprite_2d.play("die")

	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()

	# Disable collisions
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	health_bar.visible = false
	$ObjectiveMarker.visible = false
	died.emit()
func show_objective_marker() -> void:
	$ObjectiveMarker.visible = true

func hide_objective_marker() -> void:
	$ObjectiveMarker.visible = false
