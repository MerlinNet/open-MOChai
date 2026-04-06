## 触摸控件管理器
## @ai-author Claude (2026-04-06)
## @ai-task 管理移动端触摸控件

class_name TouchControls
extends CanvasLayer

# 信号
signal move_input(direction: Vector2)
signal float_pressed()
signal interact_pressed()

# 节点引用
@onready var joystick: VirtualJoystick = $Control/Joystick
@onready var float_button: ActionButton = $Control/FloatButton
@onready var interact_button: ActionButton = $Control/InteractButton

# 是否启用
var is_enabled: bool = true:
	set(value):
		is_enabled = value
		visible = value

# 按钮状态
var _is_float_held: bool = false


func _ready() -> void:
	# 检测是否为移动设备
	if OS.has_feature("mobile") or OS.has_feature("android"):
		is_enabled = true
	else:
		# 在桌面端默认隐藏（可手动开启测试）
		is_enabled = false
	
	_connect_signals()


func _connect_signals() -> void:
	if joystick:
		joystick.joystick_moved.connect(_on_joystick_moved)
	
	if float_button:
		float_button.action_pressed.connect(_on_float_pressed)
		float_button.action_released.connect(_on_float_released)
	
	if interact_button:
		interact_button.action_pressed.connect(_on_interact_pressed)


func _on_joystick_moved(direction: Vector2) -> void:
	emit_signal("move_input", direction)


func _on_float_pressed() -> void:
	_is_float_held = true
	emit_signal("float_pressed")


func _on_float_released() -> void:
	_is_float_held = false


func _on_interact_pressed() -> void:
	emit_signal("interact_pressed")


# 获取移动方向
func get_move_direction() -> Vector2:
	if joystick:
		return joystick.get_direction()
	return Vector2.ZERO


# 检查浮空按钮是否按住
func is_float_held() -> bool:
	return _is_float_held
