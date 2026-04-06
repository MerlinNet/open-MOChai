## 动作按钮 - 触摸控制
## @ai-author Claude (2026-04-06)
## @ai-task 实现移动端动作按钮

class_name ActionButton
extends TextureButton

# 信号
signal action_pressed(action_name: String)
signal action_released(action_name: String)

# 导出属性
@export var action_name: String = "interact"
@export var cooldown: float = 0.0

# 状态
var _is_pressed: bool = false
var _touch_index: int = -1
var _cooldown_timer: float = 0.0


func _ready() -> void:
	# 设置按钮属性
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	toggle_mode = false
	
	# 创建默认样式（如果没有纹理）
	if texture_normal == null:
		_create_default_texture()


func _process(delta: float) -> void:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta
		modulate.a = 0.5
	else:
		modulate.a = 1.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var local_pos := get_local_mouse_position()
	var is_inside := _is_inside_button(local_pos)
	
	if event.pressed:
		if is_inside and _touch_index == -1 and _cooldown_timer <= 0:
			_is_pressed = true
			_touch_index = event.index
			modulate.a = 0.7
			emit_signal("action_pressed", action_name)
	else:
		if event.index == _touch_index:
			_is_pressed = false
			_touch_index = -1
			modulate.a = 1.0
			emit_signal("action_released", action_name)
			
			# 启动冷却
			if cooldown > 0:
				_cooldown_timer = cooldown


func _is_inside_button(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= size.x and pos.y >= 0 and pos.y <= size.y


func _create_default_texture() -> void:
	# 创建简单的圆形按钮纹理
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制圆形
	for x in range(64):
		for y in range(64):
			var dist := Vector2(x - 32, y - 32).length()
			if dist <= 28:
				image.set_pixel(x, y, Color(0.3, 0.3, 0.3, 0.8))
			elif dist <= 30:
				image.set_pixel(x, y, Color(0.5, 0.5, 0.5, 0.9))
	
	var texture := ImageTexture.create_from_image(image)
	texture_normal = texture


# 检查按钮是否被按下
func is_action_pressed() -> bool:
	return _is_pressed
