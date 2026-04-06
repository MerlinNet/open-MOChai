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

# 生成的玩家实例
var _player_instance: Node2D = null

func _ready() -> void:
	# 摄像机由 main.tscn 管理，本场景只负责环境
	_try_spawn_player()

## 尝试生成玩家（若玩家场景已存在且 main.tscn 未管理玩家）
func _try_spawn_player() -> void:
	if player_scene_path.is_empty():
		return
	
	if not ResourceLoader.exists(player_scene_path):
		return
	
	# main.tscn 已经实例化了 Player，不需要重复生成
	# 仅提供出生坐标给 main.tscn 使用
	print("[SpawnPoint] 出生点坐标: %s" % get_spawn_position())

## 获取玩家出生坐标（供外部接口调用）
## 返回地图本地坐标 (400, 500)，main.tscn 会将 SpawnPointLevel 放在 (0,0)
## 所以实际世界坐标也是 (400, 500)
func get_spawn_position() -> Vector2:
	if player_spawn != null:
		return player_spawn.global_position
	return Vector2(400, 500)

## 重生玩家（死亡后调用）
func respawn_player() -> void:
	if _player_instance != null and is_instance_valid(_player_instance):
		_player_instance.global_position = get_spawn_position()
		print("[SpawnPoint] 玩家已重生至出生点")
	else:
		_try_spawn_player()
