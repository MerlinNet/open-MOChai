## 输入管理器
## @ai-author Claude (2026-04-06)
## @ai-task 动态配置 InputMap

extends Node


func _ready() -> void:
	_setup_input_map()


func _setup_input_map() -> void:
	# 移动 - WASD 和 方向键
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	
	# 跳跃 - 空格键
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	
	# 动作/交互 - E键和回车
	_add_action("interact", [KEY_E, KEY_ENTER])
	
	# 攻击 - J键和鼠标左键
	_add_action("attack", [KEY_J])
	_add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	
	# 冲刺 - Shift键
	_add_action("dash", [KEY_SHIFT])
	
	print("[InputManager] InputMap 配置完成")


func _add_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)


func _add_mouse_action(action_name: String, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)
