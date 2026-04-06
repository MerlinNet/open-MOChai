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
@export var button_color: Color = Color(0.3, 0.6, 0.9, 0.7)

# 状态
var _is_pressed: bool = false
var _touch_index: int = -1
var _cooldown_timer: float = 0.0


func _ready() -> void:
	# 设置按钮属性
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	toggle_mode = false
	
	# 创建圆形按钮纹理
	_create_circle_texture()


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
			modulate.a = 0.6
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
	# 圆形检测
	var center := size / 2
	var dist := pos.distance_to(center)
	return dist <= size.x / 2


func _create_circle_texture() -> void:
	# 创建圆形按钮纹理
	var size := 90
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0 - 2
	
	# 绘制外圈
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius and dist > radius - 4:
				# 外圈
				image.set_pixel(x, y, Color(1, 1, 1, 0.9))
			elif dist <= radius - 4:
				# 内部填充
				var alpha := 0.7 - (dist / radius) * 0.2
				image.set_pixel(x, y, Color(button_color.r, button_color.g, button_color.b, alpha))
	
	var texture := ImageTexture.create_from_image(image)
	texture_normal = texture
	
	# 创建按下状态的纹理
	var pressed_image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	pressed_image.fill(Color.TRANSPARENT)
	
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha := 0.9 - (dist / radius) * 0.3
				pressed_image.set_pixel(x, y, Color(button_color.r * 0.7, button_color.g * 0.7, button_color.b * 0.7, alpha))
	
	texture_pressed = ImageTexture.create_from_image(pressed_image)


# 检查按钮是否被按下
func is_action_pressed() -> bool:
	return _is_pressed