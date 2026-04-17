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
	# 等待场景加载完成后获取玩家引用
	await get_tree().process_frame
	_update_player_reference()


## 更新玩家引用
func _update_player_reference() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("[GameManager] 已获取玩家引用: %s" % player.name)
	else:
		push_warning("[GameManager] 未找到玩家节点 (确保玩家在 'player' 组中)")


## 注册玩家 (供外部调用)
func register_player(p: Node) -> void:
	player = p
	print("[GameManager] 玩家已注册: %s" % p.name)


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
