extends CharacterBody2D

signal health_changed(new_health: int)
signal died

const SPEED = 300
var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var alive: bool = true
var max_health: int 
var health: int 
var strength: float = 20
var dialogue_open: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sword: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $Hitbox
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	health = PlayerStats.health
	max_health = PlayerStats.max_health
	hitbox_offset = hitbox.position
	

func _physics_process(_delta: float) -> void:
	if not alive:
		return
	
	if dialogue_open:
		velocity = Vector2.ZERO
		process_animation()
		return
	
	hitbox.monitoring = false

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if is_attacking:
		velocity = Vector2.ZERO
		return

	process_movement()
	process_animation()
	move_and_slide()
	
	
	
#------------------------------------------------------
#MOVEMENT AND ANIMATION
#------------------------------------------------------

func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right","up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_offset()
	else:
		velocity = Vector2.ZERO
	
	
func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
	
	
#-----------------------------------------------------------
#ATTACKING
#------------------------------------------------------------

func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swing_sword.play()
	play_animation("attack", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false



#----------------------------------------------------------------
#HITBOX
#----------------------------------------------------------------

func update_hitbox_offset() -> void:
	var x:= hitbox_offset.x
	var y:= hitbox_offset.y
	
	if last_direction == Vector2.LEFT:
		hitbox.position = Vector2(-x, y)
	elif last_direction == Vector2.RIGHT:
		hitbox.position = Vector2(x, y)
	elif last_direction == Vector2.DOWN:
		hitbox.position = Vector2(-y, x)
	elif last_direction == Vector2.UP:
		hitbox.position = Vector2(y, -x)	


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(get_attack_damage(), position)


func heal(amount: int) -> void:
	
	PlayerStats.health += amount
	if PlayerStats.health >= max_health:
		PlayerStats.health = max_health
	emit_signal("health_changed", PlayerStats.health)

func take_damage(amount: int) -> void:
	if alive:
		if damage_cooldown.time_left > 0:
			return

		var final_damage: float = amount

		if PlayerStats.god_blessing:
			final_damage *= 0.75

		PlayerStats.health -= int(final_damage)

		emit_signal("health_changed", PlayerStats.health)
		take_damage_sound.play()

		if PlayerStats.health <= 0:
			die()

		damage_cooldown.start()

func die() -> void:
	animated_sprite_2d.play("dying")
	alive = false
	await animated_sprite_2d.animation_finished
	await get_tree().create_timer(1.0).timeout
	died.emit()

func get_attack_damage() -> float:
	if PlayerStats.god_blessing:
		return 56.25

	return strength
