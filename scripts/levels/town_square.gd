## 城镇广场主城场景控制器
## @ai-author Claude (2026-04-09)
## @ai-task 创建城镇广场主城场景脚本，基于精美城堡城镇图片

class_name TownSquare
extends Node2D

# 信号
signal npc_interacted(npc_name: String)
signal portal_entered(portal_name: String)
signal player_spawned(spawn_position: Vector2)

# 节点引用
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var npc_points: Node2D = $NPCPoints
@onready var portals: Node2D = $Portals
@onready var background: Sprite2D = $Background
@onready var player: Node2D = $Player
@onready var touch_controls: CanvasLayer = $TouchControls

# NPC 位置字典 (供外部查询)
var npc_positions: Dictionary = {}
# 传送点位置字典
var portal_positions: Dictionary = {}

# 场景配置
@export var scene_name: String = "TownSquare"
@export var ambient_light_color: Color = Color(0.8, 0.75, 0.9, 0.3)


func _ready() -> void:
	_cache_npc_positions()
	_cache_portal_positions()
	_print_scene_info()
	_setup_player()
	_connect_touch_controls()
	print("[TownSquare] 城镇广场已加载")
	print("[TownSquare] 玩家出生点: %s" % get_spawn_position())


## 连接触摸控件信号
func _connect_touch_controls() -> void:
	if touch_controls:
		touch_controls.move_input.connect(_on_touch_move)
		touch_controls.float_pressed.connect(_on_touch_float)


func _on_touch_move(direction: Vector2) -> void:
	if player and player.has_method("set_touch_direction"):
		player.set_touch_direction(direction)


func _on_touch_float() -> void:
	if player and player.has_method("set_touch_float"):
		player.set_touch_float(true)


## 设置玩家初始位置
func _setup_player() -> void:
	if player and player_spawn:
		player.global_position = player_spawn.global_position
		print("[TownSquare] 玩家已放置到出生点")


## 缓存所有 NPC 标记点位置
func _cache_npc_positions() -> void:
	if npc_points == null:
		push_warning("[TownSquare] NPCPoints 节点未找到")
		return

	for child in npc_points.get_children():
		if child is Marker2D:
			npc_positions[child.name] = child.global_position
	print("[TownSquare] 已缓存 %d 个 NPC 位置" % npc_positions.size())


## 缓存所有传送点位置
func _cache_portal_positions() -> void:
	if portals == null:
		push_warning("[TownSquare] Portals 节点未找到")
		return

	for child in portals.get_children():
		if child is Marker2D:
			portal_positions[child.name] = child.global_position
	print("[TownSquare] 已缓存 %d 个传送点位置" % portal_positions.size())


## 打印场景信息
func _print_scene_info() -> void:
	if background and background.texture:
		var tex_size: Vector2 = background.texture.get_size()
		print("[TownSquare] 背景纹理尺寸: %dx%d" % [tex_size.x, tex_size.y])


## 获取玩家出生坐标
func get_spawn_position() -> Vector2:
	if player_spawn != null:
		return player_spawn.global_position
	return Vector2(720, 1000)


## 获取指定 NPC 的位置
## @param npc_name: NPC 名称 (如 "NPC_Shopkeeper")
## @return: NPC 的世界坐标，如果不存在返回 Vector2.ZERO
func get_npc_position(npc_name: String) -> Vector2:
	if npc_positions.has(npc_name):
		return npc_positions[npc_name]
	push_warning("[TownSquare] 未找到 NPC: %s" % npc_name)
	return Vector2.ZERO


## 获取所有 NPC 位置
func get_all_npc_positions() -> Dictionary:
	return npc_positions.duplicate()


## 获取指定传送点的位置
## @param portal_name: 传送点名称 (如 "Portal_Tree")
## @return: 传送点的世界坐标，如果不存在返回 Vector2.ZERO
func get_portal_position(portal_name: String) -> Vector2:
	if portal_positions.has(portal_name):
		return portal_positions[portal_name]
	push_warning("[TownSquare] 未找到传送点: %s" % portal_name)
	return Vector2.ZERO


## 获取所有传送点位置
func get_all_portal_positions() -> Dictionary:
	return portal_positions.duplicate()


## 获取城镇中心位置 (喷泉位置)
func get_center_position() -> Vector2:
	return Vector2(720, 528)


## 模拟 NPC 交互 (供玩家脚本调用)
## @param npc_name: NPC 名称
func interact_with_npc(npc_name: String) -> void:
	if npc_positions.has(npc_name):
		emit_signal("npc_interacted", npc_name)
		print("[TownSquare] 玩家与 %s 交互" % npc_name)
	else:
		push_warning("[TownSquare] 尝试与不存在的 NPC 交互: %s" % npc_name)


## 模拟进入传送点 (供玩家脚本调用)
## @param portal_name: 传送点名称
func enter_portal(portal_name: String) -> void:
	if portal_positions.has(portal_name):
		emit_signal("portal_entered", portal_name)
		print("[TownSquare] 玩家进入传送点: %s" % portal_name)
	else:
		push_warning("[TownSquare] 尝试进入不存在的传送点: %s" % portal_name)


## 触发玩家出生
func spawn_player() -> void:
	var spawn_pos: Vector2 = get_spawn_position()
	emit_signal("player_spawned", spawn_pos)
	print("[TownSquare] 玩家已出生在: %s" % spawn_pos)
