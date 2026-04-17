## 昼夜循环管理器单例
## @ai-author Claude (2026-04-17)
## @ai-task 实现完整的昼夜交替系统，支持自动时间流逝、环境光变化、阴影调整
## Note: 此文件作为 autoload 单例注册，通过 DayNightCycle 全局访问

extends Node

## 时间段枚举
enum TimePeriod {
	DAWN,		# 黎明 (5:00 - 7:00)
	MORNING,	# 上午 (7:00 - 12:00)
	NOON,		# 正午 (12:00 - 14:00)
	AFTERNOON,	# 下午 (14:00 - 17:00)
	DUSK,		# 黄昏 (17:00 - 20:00)
	NIGHT		# 夜晚 (20:00 - 5:00)
}

## 时间变化信号
signal time_changed(hour: float, minute: float)
signal period_changed(new_period: TimePeriod, old_period: TimePeriod)
signal day_started(day_count: int)
signal night_started
signal dawn_started
signal dusk_started

## 配置参数
@export_group("时间设置")
@export var cycle_duration_minutes: float = 24.0  ## 完整昼夜周期时长（游戏内分钟数）
@export var real_seconds_per_game_hour: float = 60.0  ## 现实秒数对应游戏内1小时
@export var start_hour: float = 21.0  ## 初始小时 (0-24) - 默认晚上9点
@export var auto_advance: bool = true  ## 是否自动推进时间

@export_group("环境光设置")
@export var dawn_ambient_color: Color = Color(1.0, 0.7, 0.5, 1.0)  ## 黎明环境光
@export var day_ambient_color: Color = Color(0.9, 0.88, 0.85, 1.0)  ## 白天环境光（柔和暖白）
@export var dusk_ambient_color: Color = Color(1.0, 0.5, 0.3, 1.0)  ## 黄昏环境光
@export var night_ambient_color: Color = Color(0.2, 0.25, 0.4, 1.0)  ## 夜晚环境光

@export_group("天空颜色设置")
@export var dawn_sky_color: Color = Color(0.9, 0.6, 0.5, 1.0)
@export var day_sky_color: Color = Color(0.5, 0.7, 1.0, 1.0)
@export var dusk_sky_color: Color = Color(0.8, 0.4, 0.3, 1.0)
@export var night_sky_color: Color = Color(0.05, 0.05, 0.15, 1.0)

@export_group("环境光强度")
@export var dawn_energy: float = 0.5
@export var day_energy: float = 0.55
@export var dusk_energy: float = 0.4
@export var night_energy: float = 0.15

@export_group("阴影设置")
@export var shadow_angle_offset: float = 45.0  ## 阴影角度偏移
@export var max_shadow_length: float = 50.0  ## 最大阴影长度
@export var min_shadow_length: float = 10.0  ## 最小阴影长度

## 当前时间状态
var current_hour: float = 8.0
var current_minute: float = 0.0
var current_period: TimePeriod = TimePeriod.MORNING
var day_count: int = 1

## 时间流逝速度倍率
var time_speed_multiplier: float = 1.0

## 环境引用
var _environment: WorldEnvironment = null
var _ambient_light: Node = null
var _registered_lights: Array[Node] = []


func _ready() -> void:
	current_hour = start_hour
	current_period = _get_period_from_hour(current_hour)
	GameLogger.info("DayNight", "昼夜系统已初始化，当前时间: %02d:%02d" % [int(current_hour), int(current_minute)])


func _process(delta: float) -> void:
	if not auto_advance:
		return

	# 计算时间流逝（delta秒 / 每游戏小时对应现实秒数）
	var hours_elapsed: float = (delta / real_seconds_per_game_hour) * time_speed_multiplier
	current_minute += hours_elapsed * 60.0

	# 处理分钟溢出
	while current_minute >= 60.0:
		current_minute -= 60.0
		current_hour += 1.0

	# 处理跨天
	if current_hour >= 24.0:
		current_hour = fmod(current_hour, 24.0)
		day_count += 1
		emit_signal("day_started", day_count)
		GameLogger.info("DayNight", "新的一天开始！第 %d 天" % day_count)

	# 检查时间段变化
	_check_period_change()

	# 发射时间变化信号
	emit_signal("time_changed", current_hour, current_minute)


# ==================== 公共 API ====================

## 设置当前时间
func set_time(hour: float, minute: float = 0.0) -> void:
	var old_period: TimePeriod = current_period
	current_hour = clamp(hour, 0.0, 23.999)
	current_minute = clamp(minute, 0.0, 59.999)
	current_period = _get_period_from_hour(current_hour)

	if current_period != old_period:
		emit_signal("period_changed", current_period, old_period)
		_on_period_changed(current_period, old_period)
	else:
		# 即使时间段没变，也要更新灯光状态
		_update_registered_lights()

	emit_signal("time_changed", current_hour, current_minute)
	GameLogger.info("DayNight", "时间已设置为: %02d:%02d" % [int(current_hour), int(current_minute)])


## 设置时间流逝速度
func set_time_speed(multiplier: float) -> void:
	time_speed_multiplier = clamp(multiplier, 0.0, 100.0)
	GameLogger.info("DayNight", "时间速度已设置为: %.1fx" % time_speed_multiplier)


## 暂停时间流逝
func pause_time() -> void:
	auto_advance = false
	GameLogger.debug("DayNight", "时间已暂停")


## 恢复时间流逝
func resume_time() -> void:
	auto_advance = true
	GameLogger.debug("DayNight", "时间已恢复")


## 跳转到指定时间段
func jump_to_period(period: TimePeriod) -> void:
	var target_hour: float
	match period:
		TimePeriod.DAWN:
			target_hour = 6.0
		TimePeriod.MORNING:
			target_hour = 9.0
		TimePeriod.NOON:
			target_hour = 12.0
		TimePeriod.AFTERNOON:
			target_hour = 15.0
		TimePeriod.DUSK:
			target_hour = 18.0
		TimePeriod.NIGHT:
			target_hour = 21.0
	
	set_time(target_hour)


## 获取当前时间的格式化字符串
func get_time_string() -> String:
	return "%02d:%02d" % [int(current_hour), int(current_minute)]


## 获取当前时间段名称
func get_period_name() -> String:
	match current_period:
		TimePeriod.DAWN:
			return "黎明"
		TimePeriod.MORNING:
			return "上午"
		TimePeriod.NOON:
			return "正午"
		TimePeriod.AFTERNOON:
			return "下午"
		TimePeriod.DUSK:
			return "黄昏"
		TimePeriod.NIGHT:
			return "夜晚"
	return "未知"


## 是否是夜间
func is_night() -> bool:
	return current_period == TimePeriod.NIGHT or current_period == TimePeriod.DUSK


## 是否是白天
func is_day() -> bool:
	return current_period == TimePeriod.MORNING or current_period == TimePeriod.NOON or current_period == TimePeriod.AFTERNOON


## 设置环境引用
func set_environment(env: WorldEnvironment) -> void:
	_environment = env
	_update_environment()


## 设置环境光引用（用于 2D 场景）
func set_ambient_light(light: Node) -> void:
	_ambient_light = light
	_update_ambient_light()


## 注册灯光节点（用于批量更新）
func register_light(light: Node) -> void:
	if light not in _registered_lights:
		_registered_lights.append(light)
		GameLogger.debug("DayNight", "已注册灯光: %s" % light.name)


## 注销灯光节点
func unregister_light(light: Node) -> void:
	_registered_lights.erase(light)


## 注册场景中所有灯光
func register_all_lights_in_scene(root: Node) -> void:
	var lights: Array[Node] = []
	_find_lights_recursive(root, lights)
	
	for light in lights:
		register_light(light)
	
	GameLogger.debug("DayNight", "共注册 %d 个灯光" % lights.size())


# ==================== 内部方法 ====================

## 递归查找所有灯光节点
func _find_lights_recursive(node: Node, lights: Array[Node]) -> void:
	if node is PointLight2D or node is DirectionalLight2D:
		lights.append(node)
	
	for child in node.get_children():
		_find_lights_recursive(child, lights)


## 从小时获取时间段
func _get_period_from_hour(hour: float) -> TimePeriod:
	if hour >= 5.0 and hour < 7.0:
		return TimePeriod.DAWN
	elif hour >= 7.0 and hour < 12.0:
		return TimePeriod.MORNING
	elif hour >= 12.0 and hour < 14.0:
		return TimePeriod.NOON
	elif hour >= 14.0 and hour < 17.0:
		return TimePeriod.AFTERNOON
	elif hour >= 17.0 and hour < 20.0:
		return TimePeriod.DUSK
	else:
		return TimePeriod.NIGHT


## 检查时间段变化
func _check_period_change() -> void:
	var new_period: TimePeriod = _get_period_from_hour(current_hour)
	
	if new_period != current_period:
		var old_period: TimePeriod = current_period
		current_period = new_period
		emit_signal("period_changed", new_period, old_period)
		_on_period_changed(new_period, old_period)


## 时间段变化处理
func _on_period_changed(new_period: TimePeriod, old_period: TimePeriod) -> void:
	match new_period:
		TimePeriod.DAWN:
			emit_signal("dawn_started")
			GameLogger.info("DayNight", "黎明降临")
		TimePeriod.NIGHT:
			emit_signal("night_started")
			GameLogger.info("DayNight", "夜幕降临")
		TimePeriod.DUSK:
			emit_signal("dusk_started")
			GameLogger.info("DayNight", "黄昏时分")
	
	_update_environment()
	_update_ambient_light()
	_update_registered_lights()


## 更新 3D 环境
func _update_environment() -> void:
	if _environment == null or _environment.environment == null:
		return
	
	var env: Environment = _environment.environment
	var blend_factor: float = _get_blend_factor()
	
	env.ambient_light_color = _get_interpolated_ambient_color(blend_factor)
	env.ambient_light_energy = _get_interpolated_energy(blend_factor)
	
	var sky_material = env.sky.sky_material
	if sky_material is ProceduralSkyMaterial:
		sky_material.sky_top_color = _get_interpolated_sky_color(blend_factor)


## 更新 2D 环境光
func _update_ambient_light() -> void:
	if _ambient_light == null:
		return
	
	var blend_factor: float = _get_blend_factor()
	var target_color: Color = _get_interpolated_ambient_color(blend_factor)
	var target_energy: float = _get_interpolated_energy(blend_factor)
	
	if _ambient_light is PointLight2D:
		_ambient_light.color = target_color
		_ambient_light.energy = target_energy * 0.5
	elif _ambient_light is DirectionalLight2D:
		_ambient_light.color = target_color
		_ambient_light.energy = target_energy
		_update_shadow_direction(_ambient_light)


## 更新所有注册的灯光
func _update_registered_lights() -> void:
	var is_night_time: bool = is_night()
	var is_dusk_time: bool = current_period == TimePeriod.DUSK
	var is_dawn_time: bool = current_period == TimePeriod.DAWN

	for light in _registered_lights:
		if light == null:
			continue

		if light is PointLight2D:
			# 白天关闭点光源，夜晚/黄昏/黎明开启
			if is_night_time:
				light.enabled = true
				light.energy = 1.0
			elif is_dusk_time or is_dawn_time:
				light.enabled = true
				light.energy = 0.5
			else:
				# 白天关闭点光源
				light.energy = 0.0
				light.enabled = false
		elif light is DirectionalLight2D:
			# 太阳光：白天开启，夜晚关闭
			if is_night_time:
				light.enabled = false
			elif is_dusk_time or is_dawn_time:
				light.enabled = true
				light.energy = 0.3
				_update_shadow_direction(light)
			else:
				# 白天
				light.enabled = true
				light.energy = 0.4
				_update_shadow_direction(light)


## 更新阴影方向
func _update_shadow_direction(light: DirectionalLight2D) -> void:
	var sun_angle: float = _calculate_sun_angle()
	light.shadow_angle = sun_angle + shadow_angle_offset
	
	var sun_height: float = sin(deg_to_rad(sun_angle))
	var shadow_length: float = lerp(max_shadow_length, min_shadow_length, clamp(sun_height, 0.0, 1.0))
	light.shadow_opacity = remap(shadow_length, min_shadow_length, max_shadow_length, 0.3, 0.8)


## 计算太阳角度（基于当前时间）
func _calculate_sun_angle() -> float:
	var hour_normalized: float = (current_hour + current_minute / 60.0 - 6.0) / 12.0
	hour_normalized = clamp(hour_normalized, 0.0, 1.0)
	return sin(hour_normalized * PI) * 180.0


## 获取混合因子（用于平滑过渡）
func _get_blend_factor() -> float:
	match current_period:
		TimePeriod.DAWN:
			return (current_hour - 5.0 + current_minute / 60.0) / 2.0
		TimePeriod.MORNING:
			return (current_hour - 7.0 + current_minute / 60.0) / 5.0
		TimePeriod.NOON:
			return (current_hour - 12.0 + current_minute / 60.0) / 2.0
		TimePeriod.AFTERNOON:
			return (current_hour - 14.0 + current_minute / 60.0) / 3.0
		TimePeriod.DUSK:
			return (current_hour - 17.0 + current_minute / 60.0) / 3.0
		TimePeriod.NIGHT:
			if current_hour >= 20.0:
				return (current_hour - 20.0 + current_minute / 60.0) / 4.0
			else:
				return (current_hour + 4.0 + current_minute / 60.0) / 9.0
	return 0.0


## 获取插值后的环境光颜色
func _get_interpolated_ambient_color(factor: float) -> Color:
	var from_color: Color
	var to_color: Color
	
	match current_period:
		TimePeriod.DAWN:
			from_color = night_ambient_color
			to_color = dawn_ambient_color
		TimePeriod.MORNING:
			from_color = dawn_ambient_color
			to_color = day_ambient_color
		TimePeriod.NOON:
			from_color = day_ambient_color
			to_color = day_ambient_color
		TimePeriod.AFTERNOON:
			from_color = day_ambient_color
			to_color = dusk_ambient_color
		TimePeriod.DUSK:
			from_color = dusk_ambient_color
			to_color = night_ambient_color
		TimePeriod.NIGHT:
			from_color = night_ambient_color
			to_color = night_ambient_color
	
	return from_color.lerp(to_color, factor)


## 获取插值后的天空颜色
func _get_interpolated_sky_color(factor: float) -> Color:
	var from_color: Color
	var to_color: Color
	
	match current_period:
		TimePeriod.DAWN:
			from_color = night_sky_color
			to_color = dawn_sky_color
		TimePeriod.MORNING:
			from_color = dawn_sky_color
			to_color = day_sky_color
		TimePeriod.NOON:
			from_color = day_sky_color
			to_color = day_sky_color
		TimePeriod.AFTERNOON:
			from_color = day_sky_color
			to_color = dusk_sky_color
		TimePeriod.DUSK:
			from_color = dusk_sky_color
			to_color = night_sky_color
		TimePeriod.NIGHT:
			from_color = night_sky_color
			to_color = night_sky_color
	
	return from_color.lerp(to_color, factor)


## 获取插值后的能量值
func _get_interpolated_energy(factor: float) -> float:
	var from_energy: float
	var to_energy: float
	
	match current_period:
		TimePeriod.DAWN:
			from_energy = night_energy
			to_energy = dawn_energy
		TimePeriod.MORNING:
			from_energy = dawn_energy
			to_energy = day_energy
		TimePeriod.NOON:
			from_energy = day_energy
			to_energy = day_energy
		TimePeriod.AFTERNOON:
			from_energy = day_energy
			to_energy = dusk_energy
		TimePeriod.DUSK:
			from_energy = dusk_energy
			to_energy = night_energy
		TimePeriod.NIGHT:
			from_energy = night_energy
			to_energy = night_energy
	
	return lerp(from_energy, to_energy, factor)