## 虚拟摇杆 - 触摸控制
## @ai-author Claude (2026-04-06)
## @ai-task 实现移动端虚拟摇杆

class_name VirtualJoystick
extends Control

# 信号
signal joystick_moved(direction: Vector2)

# 导出属性
@export var deadzone: float = 0.2
@export var max_distance: float = 50.0

# 节点引用
@onready var knob: Control = $Knob
@onready var background: Control = $Background

# 状态
var _is_pressed: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _output: Vector2 = Vector2.ZERO


func _ready() -> void:
	_center = size / 2
	_reset_knob()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# 检查触摸是否在摇杆区域内
		var local_pos := get_local_mouse_position() if event.index == 0 else _get_touch_position(event.index)
		if _is_in_joystick_area(local_pos) and _touch_index == -1:
			_is_pressed = true
			_touch_index = event.index
			_update_knob_position(local_pos)
	else:
		if event.index == _touch_index:
			_is_pressed = false
			_touch_index = -1
			_reset_knob()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index and _is_pressed:
		var local_pos := _get_touch_position(event.index)
		_update_knob_position(local_pos)


func _get_touch_position(index: int) -> Vector2:
	# 获取触摸位置（相对于摇杆中心）
	var touches := Input.get_connected_joypads()
	for touch in touches:
		var pos := Input.get_joy_axis(touch, JOY_AXIS_LEFT_X)
	# 简化处理：使用全局鼠标位置
	return get_global_mouse_position() - global_position


func _is_in_joystick_area(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= size.x and pos.y >= 0 and pos.y <= size.y


func _update_knob_position(touch_pos: Vector2) -> void:
	var direction := touch_pos - _center
	var distance := direction.length()
	
	if distance < deadzone * max_distance:
		_output = Vector2.ZERO
		_reset_knob()
	else:
		# 限制在最大距离内
		if distance > max_distance:
			direction = direction.normalized() * max_distance
		
		# 更新摇杆位置
		knob.position = _center + direction - knob.size / 2
		
		# 计算输出值 (-1 到 1)
		_output = direction / max_distance
		_output = _output.clamp(-1, 1)
	
	emit_signal("joystick_moved", _output)


func _reset_knob() -> void:
	knob.position = _center - knob.size / 2
	_output = Vector2.ZERO
	emit_signal("joystick_moved", Vector2.ZERO)


# 获取当前方向
func get_direction() -> Vector2:
	return _output
