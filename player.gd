extends CharacterBody2D

@export var SPEED: int = 350
@export var Gravity: int = 1200
@export var JUMP_FORCE: int = 650
@export var Dash_Speed: int = 900
const wall_jump_pushback = 1000
const wall_slide = 100
const ACCELERATION = 10000
const DECELERATION = 10000
var is_wall_sliding = false
var last_facing_direction = 1
var velocity_x = 0.0
var Ledge_Grab = false
var Jumping = false
var Falling = false
var Running = false

func _physics_process(delta):
	var direction = Input.get_axis("left", "right")
	
	if direction != 0:
		velocity_x += direction * ACCELERATION * delta
		velocity_x = clamp(velocity_x, -SPEED, SPEED)
		velocity.x = velocity_x
		
		if is_on_floor():
			Jumping = false
			Falling = false
			Ledge_Grab = false
			Running = true
			is_wall_sliding = false
			$AnimatedSprite2D.play("Run")
		last_facing_direction = direction
	else:
		velocity_x = move_velocity_x(velocity_x, delta)
		velocity.x = velocity_x
		
		if is_on_floor():
			Jumping = false
			Falling = false
			Running = false
			Ledge_Grab = false
			is_wall_sliding = false
			$AnimatedSprite2D.play("Idle")
	$AnimatedSprite2D.flip_h = last_facing_direction == -1

	if not is_on_floor():
		velocity.y += Gravity * delta
		if velocity.y > 0:
			Falling = true
			$AnimatedSprite2D.play("Fall")
	check_ledge_grab(delta)
	jump(delta)
	wall_sliding(delta)
	move_and_slide()

func move_velocity_x(vel_x, delta):
	if vel_x > 0:
		return max(vel_x - DECELERATION * delta, 0)
	elif vel_x < 0:
		return min(vel_x + DECELERATION * delta, 0)
	return vel_x

func jump(delta):
	velocity.y += Gravity * delta
	if Input.is_action_just_pressed("jump"):
		$WallHang.disabled = false
		Jumping = true
		
		if is_on_floor():
			$AnimatedSprite2D.play("Jump")
			velocity.y = -JUMP_FORCE
		
func wall_sliding(delta):
	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("slide_down"):
			$WallHang.disabled = true
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
	
	if is_wall_sliding:
		$AnimatedSprite2D.play("Wall_Slide")
		velocity.y += wall_slide * delta
		velocity.y = min(velocity.y, wall_slide)

func check_ledge_grab(delta):
	if $WallCheck.is_colliding() and not $FloorCheck.is_colliding() and velocity.y == 0:
		Ledge_Grab = true
		if $LeftCheck.is_colliding():
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("Wall_Hang")
		elif $RightCheck.is_colliding():
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.play("Wall_Hang")

		if Input.is_action_just_pressed("slide_down"):
			Ledge_Grab = false
			is_wall_sliding = true
			$WallHang.disabled = true

		if Input.is_action_just_pressed("JumpUp") and (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
			ledge_climb(delta)
func ledge_climb(delta):
	velocity.y += Gravity * delta
	Ledge_Grab = false
	$WallHang.disabled = true
	velocity.y = -JUMP_FORCE

	var push_force = SPEED * 10  # Horizontal push force

	if $LeftCheck.is_colliding():
		$AnimatedSprite2D.flip_h = false
		velocity.x -= push_force  # Push to the right
		$AnimatedSprite2D.play("Ledge_Climb")
	elif $RightCheck.is_colliding():
		$AnimatedSprite2D.flip_h = true
		velocity.x += push_force  # Push to the left
		$AnimatedSprite2D.play("Ledge_Climb")
