## 玩家控制器 - 俯视角RPG
## @ai-author Claude (2026-04-06)
## @ai-task 实现俯视角RPG玩家移动系统

class_name Player
extends CharacterBody2D

# 信号
signal health_changed(old_value: int, new_value: int)
signal died

# 常量
const MAX_HEALTH: int = 100

# 导出属性
@export var speed: float = 120.0
@export_range(0.1, 1.0) var acceleration: float = 0.15
@export_range(0.1, 1.0) var friction: float = 0.2

# 公共变量
var health: int = MAX_HEALTH

# 朝向枚举 (俯视角四方向)
enum Direction { DOWN, LEFT, RIGHT, UP }
var facing_direction: Direction = Direction.DOWN

# 状态枚举
enum State { IDLE, WALKING, FLOATING, DEAD }
var current_state: State = State.IDLE

# 浮空计时
var float_timer: float = 0.0
var is_floating: bool = false

# @onready 变量
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_initialize()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	_handle_movement()
	_handle_float(delta)
	_update_state()
	_update_sprite()
	
	move_and_slide()


func _initialize() -> void:
	health = MAX_HEALTH
	current_state = State.IDLE
	facing_direction = Direction.DOWN


func _handle_movement() -> void:
	# 获取四方向输入
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	# 归一化对角移动
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	
	if input_dir != Vector2.ZERO:
		# 加速移动
		velocity = velocity.lerp(input_dir * speed, acceleration)
		
		# 更新朝向 (优先左右，因为俯视角中左右更常见)
		if abs(input_dir.x) > abs(input_dir.y):
			facing_direction = Direction.RIGHT if input_dir.x > 0 else Direction.LEFT
		else:
			facing_direction = Direction.DOWN if input_dir.y > 0 else Direction.UP
	else:
		# 摩擦减速
		velocity = velocity.lerp(Vector2.ZERO, friction)


func _handle_float(delta: float) -> void:
	# 按跳跃键进入浮空状态
	if Input.is_action_just_pressed("jump") and current_state != State.FLOATING:
		is_floating = true
		float_timer = 0.0
	
	if is_floating:
		float_timer += delta
		# 浮空持续 2 秒
		if float_timer > 2.0:
			is_floating = false
			float_timer = 0.0


func _update_state() -> void:
	if current_state == State.DEAD:
		return
	
	if is_floating:
		current_state = State.FLOATING
	elif velocity.length() > 5:
		current_state = State.WALKING
	else:
		current_state = State.IDLE


func _update_sprite() -> void:
	# 根据朝向和状态选择精灵
	# 文件命名: 1=下, 2=左, 3=右, 4=上
	# 正常: Xghost.png, 浮空: XXghost.png
	
	var dir_num: int = facing_direction + 1  # 1-4
	var texture_path: String
	
	if current_state == State.FLOATING:
		texture_path = "res://assets/sprites/player/%d%dghost.png" % [dir_num, dir_num]
	else:
		texture_path = "res://assets/sprites/player/%dghost.png" % dir_num
	
	# 加载纹理
	var tex := load(texture_path)
	if tex:
		sprite.texture = tex


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
	queue_free()


# 获取玩家状态信息（供外部调用）
func get_state_name() -> String:
	return State.keys()[current_state]


func get_direction_name() -> String:
	return Direction.keys()[facing_direction]