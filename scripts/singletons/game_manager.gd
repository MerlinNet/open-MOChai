## 游戏管理器
## @ai-author Claude (2026-04-06)
## @ai-task 全局游戏状态管理

extends Node

# 信号
signal game_started
signal game_paused
signal game_resumed
signal game_over

# 游戏状态
var is_game_active: bool = false
var is_paused: bool = false
var score: int = 0

# 玩家引用
var player: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_game() -> void:
	is_game_active = true
	is_paused = false
	score = 0
	emit_signal("game_started")


func pause_game() -> void:
	if not is_game_active:
		return
	is_paused = true
	get_tree().paused = true
	emit_signal("game_paused")


func resume_game() -> void:
	if not is_game_active:
		return
	is_paused = false
	get_tree().paused = false
	emit_signal("game_resumed")


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func end_game() -> void:
	is_game_active = false
	is_paused = false
	get_tree().paused = false
	emit_signal("game_over")


func add_score(points: int) -> void:
	score += points


func restart_game() -> void:
	get_tree().reload_current_scene()
	start_game()
