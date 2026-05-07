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
	# 使用 StyleBoxFlat 替代逐像素绘制，性能更优
	var style := StyleBoxFlat.new()
	style.bg_color = button_color
	style.set_corner_radius_all(45)  # 圆角半径 = size/2
	style.set_border_width_all(2)
	style.border_color = Color(1, 1, 1, 0.9)

	# 使用 TextureRect 渲染 StyleBox
	var size := Vector2(90, 90)

	# 创建普通状态纹理
	var normal_image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	normal_image.fill(Color.TRANSPARENT)
	var normal_texture := ImageTexture.create_from_image(normal_image)
	texture_normal = normal_texture

	# 创建按下状态纹理
	var pressed_image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	pressed_image.fill(Color.TRANSPARENT)
	texture_pressed = ImageTexture.create_from_image(pressed_image)

	# 存储样式供绘制使用
	_button_style = style
	_button_size = size


var _button_style: StyleBoxFlat
var _button_size: Vector2


func _draw() -> void:
	if _button_style:
		var is_pressed_state := _is_pressed or (texture_pressed and texture_pressed == texture_normal)
		var draw_style := _button_style.duplicate()
		if is_pressed_state:
			draw_style.bg_color = Color(button_color.r * 0.7, button_color.g * 0.7, button_color.b * 0.7, 0.9)
		else:
			draw_style.bg_color = button_color
		draw_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, _button_size))


# 检查按钮是否被按下
func is_action_pressed() -> bool:
	return _is_pressed