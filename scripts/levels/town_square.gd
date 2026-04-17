## 城镇广场主城场景控制器
## @ai-author Claude (2026-04-09)
## @ai-task 创建城镇广场主城场景脚本，基于精美城堡城镇图片
## @ai-update 2026-04-17 集成昼夜交替系统

class_name TownSquare
extends Node2D

# 信号
signal npc_interacted(npc_name: String)
signal portal_entered(portal_name: String)
signal player_spawned(spawn_position: Vector2)

# 节点引用
@onready var player_spawn: Marker2D = $Markers/PlayerSpawn
@onready var npc_points: Node2D = $Markers/NPCPoints
@onready var portals: Node2D = $Markers/Portals
@onready var background: Sprite2D = $Background
@onready var player: Node2D = $Player
@onready var touch_controls: CanvasLayer = $TouchControls
@onready var lights_node: Node2D = $Lights
@onready var sun_light: DirectionalLight2D = $SunLight
@onready var ambient_light: PointLight2D = $Lights/AmbientLight

# NPC 位置字典 (供外部查询)
var npc_positions: Dictionary = {}
# 传送点位置字典
var portal_positions: Dictionary = {}

# 场景配置
@export var scene_name: String = "TownSquare"
@export var ambient_light_color: Color = Color(0.8, 0.75, 0.9, 0.3)

# 昼夜系统配置
@export_group("昼夜系统")
@export var enable_day_night_cycle: bool = true  ## 是否启用昼夜循环
@export var start_hour: float = 8.0  ## 初始时间（小时）
@export var time_speed: float = 1.0  ## 时间流逝速度倍率


func _ready() -> void:
	_cache_npc_positions()
	_cache_portal_positions()
	_print_scene_info()
	_setup_player()
	_connect_touch_controls()
	_setup_day_night_cycle()
	GameLogger.info("TownSquare", "城镇广场已加载")
	GameLogger.debug("TownSquare", "玩家出生点: %s" % get_spawn_position())


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
	if player:
		# 使用 Markers/PlayerSpawn 作为出生点
		var spawn_marker = get_node_or_null("Markers/PlayerSpawn")
		if spawn_marker:
			player.global_position = spawn_marker.global_position
			GameLogger.info("TownSquare", "玩家已放置到出生点: %s" % spawn_marker.global_position)
		else:
			player.global_position = Vector2(720, 660)
			GameLogger.info("TownSquare", "使用默认出生点")

	# 验证所有碰撞体
	_verify_collisions()


## 缓存所有 NPC 标记点位置
func _cache_npc_positions() -> void:
	if npc_points == null:
		push_warning("[TownSquare] NPCPoints 节点未找到")
		return

	for child in npc_points.get_children():
		if child is Marker2D:
			npc_positions[child.name] = child.global_position
	GameLogger.info("TownSquare", "已缓存 %d 个 NPC 位置" % npc_positions.size())


## 缓存所有传送点位置
func _cache_portal_positions() -> void:
	if portals == null:
		push_warning("[TownSquare] Portals 节点未找到")
		return

	for child in portals.get_children():
		if child is Marker2D:
			portal_positions[child.name] = child.global_position
	GameLogger.info("TownSquare", "已缓存 %d 个传送点位置" % portal_positions.size())


## 打印场景信息
func _print_scene_info() -> void:
	if background and background.texture:
		var tex_size: Vector2 = background.texture.get_size()
		GameLogger.info("TownSquare", "背景纹理尺寸: %dx%d" % [tex_size.x, tex_size.y])


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
		GameLogger.info("TownSquare", "玩家与 %s 交互" % npc_name)
	else:
		push_warning("[TownSquare] 尝试与不存在的 NPC 交互: %s" % npc_name)


## 模拟进入传送点 (供玩家脚本调用)
## @param portal_name: 传送点名称
func enter_portal(portal_name: String) -> void:
	if portal_positions.has(portal_name):
		emit_signal("portal_entered", portal_name)
		GameLogger.info("TownSquare", "玩家进入传送点: %s" % portal_name)
	else:
		push_warning("[TownSquare] 尝试进入不存在的传送点: %s" % portal_name)


## 触发玩家出生
func spawn_player() -> void:
	var spawn_pos: Vector2 = get_spawn_position()
	emit_signal("player_spawned", spawn_pos)
	GameLogger.info("TownSquare", "玩家已出生在: %s" % spawn_pos)


## 验证场景中所有碰撞体配置
func _verify_collisions() -> void:
	var collisions_node = get_node_or_null("Collisions")
	if not collisions_node:
		push_warning("[TownSquare] Collisions 节点未找到!")
		return
	
	var count = 0
	for body in collisions_node.get_children():
		# 递归检查所有子节点
		_check_body(body, count)
		for sub_body in body.get_children():
			_check_body(sub_body, count)
	
	GameLogger.info("TownSquare", "共验证 %d 个碰撞体" % count)


func _check_body(body: Node, count: int) -> void:
	if body is StaticBody2D:
		count += 1
		var col_shape = body.get_node_or_null("CollisionShape2D")
		var shape_info = "无"
		var is_disabled = true
		if col_shape and col_shape.shape:
			shape_info = str(col_shape.shape)
			is_disabled = col_shape.disabled
		GameLogger.info("TownSquare", "碰撞体 %s: layer=%d mask=%d shape=%s disabled=%s" % [
			body.name, body.collision_layer, body.collision_mask, shape_info, is_disabled])
		if body.collision_layer == 0:
			push_warning("[TownSquare] 碰撞体 %s 的 collision_layer 为 0!" % body.name)


# ==================== 昼夜系统集成 ====================

## 初始化昼夜系统
func _setup_day_night_cycle() -> void:
	if not enable_day_night_cycle:
		GameLogger.info("TownSquare", "昼夜循环已禁用")
		return
	
	# 设置初始时间
	DayNightCycle.set_time(start_hour)
	DayNightCycle.set_time_speed(time_speed)
	
	# 注册环境光
	if ambient_light:
		DayNightCycle.set_ambient_light(ambient_light)
	
	# 注册太阳光（用于阴影）
	if sun_light:
		DayNightCycle.register_light(sun_light)
	
	# 注册所有场景灯光
	if lights_node:
		_register_scene_lights()
	
	# 连接昼夜信号
	DayNightCycle.time_changed.connect(_on_time_changed)
	DayNightCycle.period_changed.connect(_on_period_changed)
	DayNightCycle.dawn_started.connect(_on_dawn_started)
	DayNightCycle.dusk_started.connect(_on_dusk_started)
	DayNightCycle.night_started.connect(_on_night_started)
	
	GameLogger.info("TownSquare", "昼夜系统已初始化，初始时间: %s" % DayNightCycle.get_time_string())


## 注册场景中的所有灯光
func _register_scene_lights() -> void:
	if not lights_node:
		return
	
	for child in lights_node.get_children():
		if child is PointLight2D and child.name != "AmbientLight":
			DayNightCycle.register_light(child)
	
	GameLogger.info("TownSquare", "已注册场景灯光到昼夜系统")


## 时间变化回调
func _on_time_changed(hour: float, minute: float) -> void:
	# 可以在这里添加时间相关的逻辑
	pass


## 时间段变化回调
func _on_period_changed(new_period: DayNightCycle.TimePeriod, old_period: DayNightCycle.TimePeriod) -> void:
	var period_name: String = DayNightCycle.get_period_name()
	GameLogger.info("TownSquare", "时间段变化: %s" % period_name)
	
	# 更新背景色调（可选）
	_update_background_tint()


## 黎明开始回调
func _on_dawn_started() -> void:
	GameLogger.info("TownSquare", "黎明降临，城镇苏醒...")
	# 可以触发 NPC 开始活动等


## 黄昏开始回调
func _on_dusk_started() -> void:
	GameLogger.info("TownSquare", "黄昏时分，街灯点亮...")
	# 可以触发街灯亮起等


## 夜晚开始回调
func _on_night_started() -> void:
	GameLogger.info("TownSquare", "夜幕降临，城镇入眠...")
	# 可以触发 NPC 回家等


## 更新背景色调
func _update_background_tint() -> void:
	if not background:
		return
	
	# 根据时间段调整背景颜色
	var tint_color: Color
	match DayNightCycle.current_period:
		DayNightCycle.TimePeriod.DAWN:
			tint_color = Color(1.0, 0.9, 0.85, 1.0)
		DayNightCycle.TimePeriod.MORNING, DayNightCycle.TimePeriod.NOON, DayNightCycle.TimePeriod.AFTERNOON:
			tint_color = Color(1.0, 1.0, 1.0, 1.0)
		DayNightCycle.TimePeriod.DUSK:
			tint_color = Color(1.0, 0.85, 0.8, 1.0)
		DayNightCycle.TimePeriod.NIGHT:
			tint_color = Color(0.7, 0.75, 0.9, 1.0)
	
	background.modulate = tint_color


## 设置时间（供外部调用）
func set_time_of_day(hour: float, minute: float = 0.0) -> void:
	DayNightCycle.set_time(hour, minute)


## 设置时间流逝速度
func set_time_speed(speed: float) -> void:
	DayNightCycle.set_time_speed(speed)


## 获取当前时间字符串
func get_current_time_string() -> String:
	return DayNightCycle.get_time_string()


## 获取当前时间段
func get_current_period() -> DayNightCycle.TimePeriod:
	return DayNightCycle.current_period
