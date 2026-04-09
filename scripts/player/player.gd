## 玩家控制器 - 俯视角RPG
## @ai-author Claude (2026-04-06)
## @ai-task 实现俯视角RPG玩家移动系统（支持行走动画）

class_name Player
extends CharacterBody2D

# 信号
signal health_changed(old_value: int, new_value: int)
signal died

# 常量
const MAX_HEALTH: int = 100

# 导出属性
@export var speed: float = 200.0
@export_range(0.1, 1.0) var acceleration: float = 0.15
@export_range(0.1, 1.0) var friction: float = 0.2

# 公共变量
var health: int = MAX_HEALTH

# 朝向枚举 (俯视角四方向)
enum Direction { DOWN, LEFT, RIGHT, UP }
var facing_direction: Direction = Direction.DOWN

# 状态枚举
enum State { IDLE, WALKING, DEAD }
var current_state: State = State.IDLE

# 触摸输入
var touch_direction: Vector2 = Vector2.ZERO

# @onready 变量
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_initialize()
	# 设置碰撞层和掩码
	collision_layer = 1  # 玩家在层 1
	collision_mask = 4   # 只与层 4（环境/障碍物）碰撞


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_handle_movement()
	_update_state()
	_update_animation()

	move_and_slide()


func _initialize() -> void:
	health = MAX_HEALTH
	current_state = State.IDLE
	facing_direction = Direction.DOWN


func _handle_movement() -> void:
	# 获取四方向输入（键盘 + 触摸）
	var input_dir := Vector2.ZERO

	# 键盘输入
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	# 如果没有键盘输入，使用触摸输入
	if input_dir == Vector2.ZERO:
		input_dir = touch_direction

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


func _update_state() -> void:
	if current_state == State.DEAD:
		return

	if velocity.length() > 5:
		current_state = State.WALKING
	else:
		current_state = State.IDLE


func _update_animation() -> void:
	# 根据朝向设置动画
	var anim_name: String = Direction.keys()[facing_direction].to_lower()
	
	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
	
	# 根据状态播放/停止动画
	if current_state == State.WALKING:
		if not anim_sprite.is_playing():
			anim_sprite.play(anim_name)
	else:
		anim_sprite.stop()


# 触摸输入接口
func set_touch_direction(direction: Vector2) -> void:
	touch_direction = direction


func set_touch_float(_pressed: bool) -> void:
	# 预留方法，暂未实现浮空功能
	pass


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
	anim_sprite.stop()
	emit_signal("died")
	queue_free()


# 获取玩家状态信息（供外部调用）
func get_state_name() -> String:
	return State.keys()[current_state]


func get_direction_name() -> String:
	return Direction.keys()[facing_direction]
