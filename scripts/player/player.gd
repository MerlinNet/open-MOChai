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
const CHARACTER_SKIN_NAMES := ["晨星", "樱歌", "澜音"]

# 导出属性
@export var speed: float = 200.0
@export_range(0.1, 1.0) var acceleration: float = 0.15
@export_range(0.1, 1.0) var friction: float = 0.2
@export_enum("晨星", "樱歌", "澜音") var character_skin_index: int = 0

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
@onready var player_glow: PointLight2D = $PlayerGlow


func _ready() -> void:
	_initialize()
	_apply_character_skin(CHARACTER_SKIN_NAMES[clamp(character_skin_index, 0, CHARACTER_SKIN_NAMES.size() - 1)])
	# 俯视角模式：无重力，自由四方向移动
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# 碰撞层和掩码 (层1=玩家, 层2=敌人, 层3=环境, 层4=收集品)
	collision_layer = 1  # 玩家在层 1
	collision_mask = 15  # 检测层 1+2+3+4 (全部层，确保碰撞万无一失)
	# 增大安全边距，防止高速移动时穿透薄墙
	safe_margin = 2.0




func _apply_character_skin(skin_name: String) -> void:
	if not anim_sprite:
		return

	var sprite_frames := SpriteFrames.new()
	for n in ["down", "left", "right", "up"]:
		sprite_frames.add_animation(n)

	match skin_name:
		"晨星":
			_add_two_frame_direction(sprite_frames, "down", "res://assets/sprites/player/hero_orange_down_0.png", "res://assets/sprites/player/hero_orange_down_1.png")
			_add_two_frame_direction(sprite_frames, "left", "res://assets/sprites/player/hero_orange_left_0.png", "res://assets/sprites/player/hero_orange_left_1.png")
			_add_two_frame_direction(sprite_frames, "right", "res://assets/sprites/player/hero_orange_right_0.png", "res://assets/sprites/player/hero_orange_right_1.png")
			_add_two_frame_direction(sprite_frames, "up", "res://assets/sprites/player/hero_orange_up_0.png", "res://assets/sprites/player/hero_orange_up_1.png")
		"樱歌":
			_add_two_frame_direction(sprite_frames, "down", "res://assets/sprites/player/hero_pink_down_0.png", "res://assets/sprites/player/hero_pink_down_1.png")
			_add_two_frame_direction(sprite_frames, "left", "res://assets/sprites/player/hero_pink_left_0.png", "res://assets/sprites/player/hero_pink_left_1.png")
			_add_two_frame_direction(sprite_frames, "right", "res://assets/sprites/player/hero_pink_right_0.png", "res://assets/sprites/player/hero_pink_right_1.png")
			_add_two_frame_direction(sprite_frames, "up", "res://assets/sprites/player/hero_pink_up_0.png", "res://assets/sprites/player/hero_pink_up_1.png")
		"澜音":
			_add_two_frame_direction(sprite_frames, "down", "res://assets/sprites/player/hero_blue_down_0.png", "res://assets/sprites/player/hero_blue_down_1.png")
			_add_two_frame_direction(sprite_frames, "left", "res://assets/sprites/player/hero_blue_left_0.png", "res://assets/sprites/player/hero_blue_left_1.png")
			_add_two_frame_direction(sprite_frames, "right", "res://assets/sprites/player/hero_blue_right_0.png", "res://assets/sprites/player/hero_blue_right_1.png")
			_add_two_frame_direction(sprite_frames, "up", "res://assets/sprites/player/hero_blue_up_0.png", "res://assets/sprites/player/hero_blue_up_1.png")
		_:
			_add_two_frame_direction(sprite_frames, "down", "res://assets/sprites/player/hero_orange_down_0.png", "res://assets/sprites/player/hero_orange_down_1.png")
			_add_two_frame_direction(sprite_frames, "left", "res://assets/sprites/player/hero_orange_left_0.png", "res://assets/sprites/player/hero_orange_left_1.png")
			_add_two_frame_direction(sprite_frames, "right", "res://assets/sprites/player/hero_orange_right_0.png", "res://assets/sprites/player/hero_orange_right_1.png")
			_add_two_frame_direction(sprite_frames, "up", "res://assets/sprites/player/hero_orange_up_0.png", "res://assets/sprites/player/hero_orange_up_1.png")
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.animation = "down"
	anim_sprite.frame = 0


func _add_walk_direction(frames: SpriteFrames, animation_name: String, path_prefix: String) -> void:
	for i in range(4):
		var tex := load("%s%d.png" % [path_prefix, i]) as Texture2D
		if tex:
			frames.add_frame(animation_name, tex)


func _add_two_frame_direction(frames: SpriteFrames, animation_name: String, path_a: String, path_b: String) -> void:
	var tex_a := load(path_a) as Texture2D
	var tex_b := load(path_b) as Texture2D
	if tex_a:
		frames.add_frame(animation_name, tex_a)
	if tex_b:
		frames.add_frame(animation_name, tex_b)


func set_character_skin(skin_name: String) -> void:
	var idx := CHARACTER_SKIN_NAMES.find(skin_name)
	if idx == -1:
		idx = 0
	character_skin_index = idx
	_apply_character_skin(CHARACTER_SKIN_NAMES[character_skin_index])

func _enable_glow(enabled: bool) -> void:
	if player_glow:
		player_glow.enabled = enabled


func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return

	_handle_movement()
	move_and_slide()
	_handle_collision_response()
	_update_state()
	_update_animation()


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

	if input_dir.length() > 0.1:
		# 加速移动
		velocity = velocity.lerp(input_dir * speed, acceleration)

		# 更新朝向 (优先左右，增加阈值防止对角移动时抖动)
		if abs(input_dir.x) > abs(input_dir.y):
			facing_direction = Direction.RIGHT if input_dir.x > 0 else Direction.LEFT
		else:
			facing_direction = Direction.DOWN if input_dir.y > 0 else Direction.UP
	else:
		# 摩擦减速
		velocity = velocity.lerp(Vector2.ZERO, friction)


## 碰撞后响应：滑墙时沿碰撞面滑动
func _handle_collision_response() -> void:
	# move_and_slide() 已自动处理滑墙
	# 这里根据碰撞信息做额外处理
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider == null:
			continue
		# 检测是否碰到敌人层 (layer 2)
		if collider.collision_layer & 2:
			take_damage(10)
		# 检测是否碰到收集品层 (layer 4)
		elif collider.collision_layer & 8:
			pass  # 收集逻辑待实现


func _update_state() -> void:
	if current_state == State.DEAD:
		return

	if velocity.length() > 5:
		current_state = State.WALKING
	else:
		current_state = State.IDLE


func _update_animation() -> void:
	var anim_name: String = Direction.keys()[facing_direction].to_lower()
	
	if current_state == State.WALKING:
		# 走路时：切换动画或继续播放
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)
		elif not anim_sprite.is_playing():
			anim_sprite.play(anim_name)
	else:
		# 空闲时：停止动画保持当前朝向帧
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)
			anim_sprite.stop()
		elif anim_sprite.is_playing():
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
