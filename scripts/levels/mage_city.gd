## 魔法师城主城 / 新手村场景控制器
## @ai-author Claude (2026-04-09)
## @ai-task 创建主城地图场景脚本，提供 NPC 位置、传送点等接口

class_name MageCity
extends Node2D

# 信号
signal npc_interacted(npc_name: String)
signal portal_entered(portal_name: String)

# 节点引用
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var npc_points: Node2D = $NPCPoints
@onready var portals: Node2D = $Portals

# NPC 位置字典 (供外部查询)
var npc_positions: Dictionary = {}
# 传送点位置字典
var portal_positions: Dictionary = {}


func _ready() -> void:
	_cache_npc_positions()
	_cache_portal_positions()
	_setup_area2d_triggers()
	print("[MageCity] 魔法师城主城已加载")
	print("[MageCity] 玩家出生点: %s" % get_spawn_position())


## 缓存所有 NPC 标记点位置
func _cache_npc_positions() -> void:
	for child in npc_points.get_children():
		if child is Marker2D:
			npc_positions[child.name] = child.global_position
	print("[MageCity] 已缓存 %d 个 NPC 位置" % npc_positions.size())


## 缓存所有传送点位置
func _cache_portal_positions() -> void:
	for child in portals.get_children():
		if child is Marker2D:
			portal_positions[child.name] = child.global_position
	print("[MageCity] 已缓存 %d 个传送点位置" % portal_positions.size())


## 设置 Area2D 触发器 (用于传送点和 NPC 交互)
func _setup_area2d_triggers() -> void:
	# 可以在这里动态创建 Area2D 节点用于检测玩家进入触发区域
	# 目前使用 Marker2D 作为位置参考，交互逻辑由玩家脚本处理
	pass


## 获取玩家出生坐标
func get_spawn_position() -> Vector2:
	if player_spawn != null:
		return player_spawn.global_position
	return Vector2(400, 560)


## 获取指定 NPC 的位置
## @param npc_name: NPC 名称 (如 "NPC_Merchant")
## @return: NPC 的世界坐标，如果不存在返回 Vector2.ZERO
func get_npc_position(npc_name: String) -> Vector2:
	if npc_positions.has(npc_name):
		return npc_positions[npc_name]
	push_warning("[MageCity] 未找到 NPC: %s" % npc_name)
	return Vector2.ZERO


## 获取所有 NPC 位置
func get_all_npc_positions() -> Dictionary:
	return npc_positions.duplicate()


## 获取指定传送点的位置
## @param portal_name: 传送点名称 (如 "Portal_Dungeon")
## @return: 传送点的世界坐标，如果不存在返回 Vector2.ZERO
func get_portal_position(portal_name: String) -> Vector2:
	if portal_positions.has(portal_name):
		return portal_positions[portal_name]
	push_warning("[MageCity] 未找到传送点: %s" % portal_name)
	return Vector2.ZERO


## 获取所有传送点位置
func get_all_portal_positions() -> Dictionary:
	return portal_positions.duplicate()


## 获取主城中心位置 (喷泉位置)
func get_center_position() -> Vector2:
	return Vector2(400, 320)


## 模拟 NPC 交互 (供玩家脚本调用)
## @param npc_name: NPC 名称
func interact_with_npc(npc_name: String) -> void:
	if npc_positions.has(npc_name):
		emit_signal("npc_interacted", npc_name)
		print("[MageCity] 玩家与 %s 交互" % npc_name)
	else:
		push_warning("[MageCity] 尝试与不存在的 NPC 交互: %s" % npc_name)


## 模拟进入传送点 (供玩家脚本调用)
## @param portal_name: 传送点名称
func enter_portal(portal_name: String) -> void:
	if portal_positions.has(portal_name):
		emit_signal("portal_entered", portal_name)
		print("[MageCity] 玩家进入传送点: %s" % portal_name)
	else:
		push_warning("[MageCity] 尝试进入不存在的传送点: %s" % portal_name)
