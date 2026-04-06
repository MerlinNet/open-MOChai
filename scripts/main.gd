## 主场景控制器
## @ai-author Claude (2026-04-06)
## @ai-task 创建主场景，管理关卡切换、触摸控件和全局状态

extends Node2D

# 当前关卡引用
@onready var current_level_container: Node2D = $CurrentLevel
@onready var player: Player = $Player
@onready var touch_controls: TouchControls = $TouchControls


func _ready() -> void:
	print("[Main] Open-MOChai 游戏启动")
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


## 切换到指定关卡
func load_level(level_path: String) -> void:
	# 清理当前关卡
	for child in current_level_container.get_children():
		child.queue_free()
	
	# 加载新关卡
	var level_scene: PackedScene = load(level_path)
	if level_scene == null:
		push_error("[Main] 无法加载关卡: %s" % level_path)
		return
	
	var level_instance := level_scene.instantiate()
	current_level_container.add_child(level_instance)
	print("[Main] 已加载关卡: %s" % level_path)