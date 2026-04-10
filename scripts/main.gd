## 主场景控制器
## 只负责管理触摸控件

extends Node2D

@onready var touch_controls: TouchControls = $TouchControls


func _ready() -> void:
	print("[Main] Open-MOChai 游戏启动")
	_connect_touch_controls()


func _connect_touch_controls() -> void:
	if touch_controls:
		touch_controls.move_input.connect(_on_move_input)
		touch_controls.float_pressed.connect(_on_float_pressed)


func _on_move_input(direction: Vector2) -> void:
	# 通过信号转发给场景中的玩家
	get_tree().call_group("player", "set_touch_direction", direction)


func _on_float_pressed() -> void:
	get_tree().call_group("player", "set_touch_float", true)
	await get_tree().create_timer(2.0).timeout
	get_tree().call_group("player", "set_touch_float", false)
