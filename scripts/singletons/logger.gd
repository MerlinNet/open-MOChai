## 日志管理器 - 统一日志输出
## @ai-author Claude (2026-04-17)
## @ai-task 创建统一的日志系统，支持控制台和文件输出

extends Node

## 日志级别
enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

## 配置
@export var min_log_level: LogLevel = LogLevel.DEBUG
@export var write_to_file: bool = true
@export var max_log_files: int = 5
@export var show_timestamp: bool = true
@export var show_level: bool = true
@export var show_category: bool = true

## 日志文件路径
var _log_dir: String = "user://logs/"
var _current_log_file: String = ""
var _log_buffer: Array[String] = []

## 信号
signal log_added(level: int, category: String, message: String)


func _ready() -> void:
	_setup_log_directory()
	_create_new_log_file()
	print("[Logger] 日志系统已初始化，日志文件: %s" % _current_log_file)


func _setup_log_directory() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
	_cleanup_old_logs()


func _create_new_log_file() -> void:
	var datetime := Time.get_datetime_dict_from_system()
	_current_log_file = "%04d-%02d-%02d_%02d-%02d-%02d.log" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	_write_to_file("=== 日志开始 === %s" % _current_log_file)


func _cleanup_old_logs() -> void:
	var dir := DirAccess.open(_log_dir)
	if dir == null:
		return
	
	var log_files: PackedStringArray = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".log"):
			log_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# 按修改时间排序，删除最旧的
	if log_files.size() >= max_log_files:
		log_files.sort()
		while log_files.size() >= max_log_files:
			var oldest := log_files[0]
			dir.remove(oldest)
			log_files.remove_at(0)


## 格式化日志消息
func _format_message(level: LogLevel, category: String, message: String) -> String:
	var parts: Array[String] = []
	
	if show_timestamp:
		var time := Time.get_time_string_from_system()
		parts.append("[%s]" % time)
	
	if show_level:
		var level_name: String = ["DEBUG", "INFO", "WARN", "ERROR"][level]
		parts.append("[%s]" % level_name)
	
	if show_category and not category.is_empty():
		parts.append("[%s]" % category)
	
	parts.append(message)
	return " ".join(parts)


## 写入日志文件
func _write_to_file(content: String) -> void:
	if not write_to_file:
		return
	
	var file_path := _log_dir + _current_log_file
	var file := FileAccess.open(file_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(content)


## 核心日志方法
func _log(level: LogLevel, category: String, message: String) -> void:
	if level < min_log_level:
		return
	
	var formatted := _format_message(level, category, message)
	
	# 控制台输出
	print(formatted)
	
	# 文件输出
	_write_to_file(formatted)
	
	# 缓存（供UI查看）
	_log_buffer.append(formatted)
	if _log_buffer.size() > 1000:
		_log_buffer.pop_front()
	
	# 发射信号
	emit_signal("log_added", level, category, message)


## 便捷方法
func debug(category: String, message: String) -> void:
	_log(LogLevel.DEBUG, category, message)


func info(category: String, message: String) -> void:
	_log(LogLevel.INFO, category, message)


func warn(category: String, message: String) -> void:
	_log(LogLevel.WARNING, category, message)


func error(category: String, message: String) -> void:
	_log(LogLevel.ERROR, category, message)


## 异常日志（带堆栈）
func exception(category: String, message: String) -> void:
	var stack := get_stack()
	var stack_str := ""
	if stack.size() > 0:
		for frame in stack:
			stack_str += "\n  at %s:%d in %s" % [frame.source, frame.line, frame.function]
	_log(LogLevel.ERROR, category, message + stack_str)


## 获取日志缓存
func get_log_buffer() -> Array[String]:
	return _log_buffer.duplicate()


## 清空日志缓存
func clear_buffer() -> void:
	_log_buffer.clear()


## 导出日志到文件
func export_log(export_path: String) -> bool:
	var file := FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		return false
	
	for line in _log_buffer:
		file.store_line(line)
	
	return true


## 获取当前日志文件路径
func get_log_file_path() -> String:
	return _log_dir + _current_log_file
