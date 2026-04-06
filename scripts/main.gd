## 主场景控制器
## @ai-author AI Developer (2026-04-06)
## @ai-task 创建主场景，管理关卡切换和全局状态

extends Node2D

# 当前关卡引用
@onready var current_level_container: Node2D = $CurrentLevel

func _ready() -> void:
	print("[Main] Open-MOChai 游戏启动")

## 切换到指定关卡（预留接口）
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
