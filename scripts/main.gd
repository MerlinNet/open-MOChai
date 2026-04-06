## 主游戏控制器
## @ai-author Claude (2026-04-06)
## @ai-task 连接触摸控件和玩家

extends Node2D

@onready var player: Player = $Player
@onready var touch_controls: TouchControls = $TouchControls


func _ready() -> void:
	_connect_touch_controls()


func _connect_touch_controls() -> void:
	if touch_controls and player:
		touch_controls.move_input.connect(_on_move_input)
		touch_controls.float_pressed.connect(_on_float_pressed)


func _on_move_input(direction: Vector2) -> void:
	if player:
		player.set_touch_direction(direction)


func _on_float_pressed() -> void:
	if player:
		player.set_touch_float(true)
		# 短暂延迟后释放
		await get_tree().create_timer(2.0).timeout
		player.set_touch_float(false)
