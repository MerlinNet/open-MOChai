## 输入管理器 - 俯视角RPG
## @ai-author Claude (2026-04-06)
## @ai-task 动态配置 InputMap

extends Node


func _ready() -> void:
	_setup_input_map()


func _setup_input_map() -> void:
	# 四方向移动 - WASD 和 方向键
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	
	# 浮空 - 空格键
	_add_action("float", [KEY_SPACE])
	
	# 动作/交互 - E键
	_add_action("interact", [KEY_E])
	
	print("[InputManager] InputMap 配置完成 (俯视角RPG)")


func _add_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)