## 玩家控制器
## @ai-author Claude (2026-04-06)
## @ai-task 实现玩家移动系统

class_name Player
extends CharacterBody2D

# 信号
signal health_changed(old_value: int, new_value: int)
signal died

# 常量
const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0

# 导出属性
@export var speed: float = 150.0
@export var jump_force: float = 350.0
@export_range(0.1, 1.0) var acceleration: float = 0.2
@export_range(0.1, 1.0) var friction: float = 0.15

# 公共变量
var health: int = MAX_HEALTH
var is_facing_right: bool = true

# 私有变量
var _is_jumping: bool = false

# 状态枚举
enum State { IDLE, WALKING, JUMPING, FALLING, DEAD }
var current_state: State = State.IDLE

# @onready 变量
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ray_cast: RayCast2D = $RayCast2D


func _ready() -> void:
	_initialize()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_update_state()
	_update_animation()
	
	move_and_slide()


func _initialize() -> void:
	health = MAX_HEALTH
	current_state = State.IDLE
	
	# 配置 RayCast 用于检测地面
	if ray_cast:
		ray_cast.target_position = Vector2(0, 20)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		# 加速移动
		velocity.x = lerp(velocity.x, direction * speed, acceleration)
		# 更新朝向
		is_facing_right = direction > 0
		sprite.flip_h = not is_facing_right
	else:
		# 摩擦减速
		velocity.x = lerp(velocity.x, 0.0, friction)


func _handle_jump() -> void:
	if is_on_floor():
		_is_jumping = false
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force
			_is_jumping = true
	elif _is_jumping:
		# 变量跳跃高度（松开跳跃键提前停止）
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= 0.5


func _update_state() -> void:
	if is_on_floor():
		if abs(velocity.x) > 10:
			current_state = State.WALKING
		else:
			current_state = State.IDLE
	else:
		if velocity.y < 0:
			current_state = State.JUMPING
		else:
			current_state = State.FALLING


func _update_animation() -> void:
	match current_state:
		State.IDLE:
			animation_player.play("idle")
		State.WALKING:
			animation_player.play("walk")
		State.JUMPING:
			animation_player.play("jump")
		State.FALLING:
			animation_player.play("fall")
		State.DEAD:
			animation_player.play("die")


# 公共方法
func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	
	var old_health := health
	health = max(0, health - amount)
	emit_signal("health_changed", old_health, health)
	
	if health <= 0:
		die()


func heal(amount: int) -> void:
	var old_health := health
	health = min(MAX_HEALTH, health + amount)
	emit_signal("health_changed", old_health, health)


func die() -> void:
	current_state = State.DEAD
	emit_signal("died")
	# 等待死亡动画播放完成后删除
	await animation_player.animation_finished
	queue_free()


# 获取玩家状态信息（供外部调用）
func get_state_name() -> String:
	return State.keys()[current_state]
