## 出生点场景控制器
## @ai-author AI Developer (2026-04-06)
## @ai-task 创建出生点场景，提供玩家生成位置接口
##
## 负责管理玩家的初始出生位置，
## 另一位 AI 可通过 PlayerSpawn 节点获取玩家出生坐标。

class_name SpawnPointScene
extends Node2D

# 信号
signal player_spawned(spawn_position: Vector2)

# 玩家场景路径（由负责角色的AI提供）
@export_file("*.tscn") var player_scene_path: String = "res://scenes/player/player.tscn"

# 节点引用
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var camera: Camera2D = $Camera2D
@onready var camera_bounds: Area2D = $CameraBounds

# 生成的玩家实例
var _player_instance: Node2D = null

func _ready() -> void:
	_setup_camera()
	_try_spawn_player()

## 设置摄像机边界
func _setup_camera() -> void:
	if camera == null:
		return
	# 摄像机限制：与关卡边界对应
	camera.limit_left = -620
	camera.limit_right = 620
	camera.limit_top = -340
	camera.limit_bottom = 310

## 尝试生成玩家（若玩家场景已存在）
func _try_spawn_player() -> void:
	if player_scene_path.is_empty():
		# 玩家场景尚未创建，跳过（由另一位AI负责）
		push_warning("[SpawnPoint] 玩家场景路径未设置，跳过自动生成。")
		return
	
	if not ResourceLoader.exists(player_scene_path):
		# 玩家场景文件不存在
		push_warning("[SpawnPoint] 玩家场景未找到: %s" % player_scene_path)
		return
	
	_spawn_player()

## 生成玩家到出生点
func _spawn_player() -> void:
	var player_scene: PackedScene = load(player_scene_path)
	if player_scene == null:
		push_error("[SpawnPoint] 无法加载玩家场景: %s" % player_scene_path)
		return
	
	_player_instance = player_scene.instantiate() as Node2D
	if _player_instance == null:
		push_error("[SpawnPoint] 玩家场景实例化失败")
		return
	
	add_child(_player_instance)
	_player_instance.global_position = get_spawn_position()
	
	# 摄像机跟随玩家
	_follow_player(_player_instance)
	
	emit_signal("player_spawned", get_spawn_position())
	print("[SpawnPoint] 玩家已在位置 %s 生成" % get_spawn_position())

## 获取玩家出生坐标（供外部接口调用）
func get_spawn_position() -> Vector2:
	if player_spawn != null:
		return player_spawn.global_position
	return Vector2.ZERO

## 让摄像机跟随玩家
func _follow_player(player: Node2D) -> void:
	if camera == null or player == null:
		return
	# 将摄像机重新挂载为玩家子节点（或保持跟随）
	# 这里用简单方式：把摄像机设置跟随目标
	# 实际摄像机跟随逻辑建议在玩家脚本中实现
	camera.reparent(player)
	camera.position = Vector2.ZERO

## 重生玩家（死亡后调用）
func respawn_player() -> void:
	if _player_instance != null and is_instance_valid(_player_instance):
		_player_instance.global_position = get_spawn_position()
		print("[SpawnPoint] 玩家已重生至出生点")
	else:
		_try_spawn_player()
