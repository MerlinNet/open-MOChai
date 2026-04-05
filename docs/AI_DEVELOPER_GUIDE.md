# Open-MOChai AI 开发者指南

> 本文档专为 AI 开发者设计，涵盖项目架构、Godot 引擎核心概念、MCP 工具使用规范及协作约定。

---

## 目录

1. [项目概述](#项目概述)
2. [Godot 引擎核心概念](#godot-引擎核心概念)
3. [Godot MCP Pro 工具参考](#godot-mcp-pro-工具参考)
4. [GDScript 编码规范](#gdscript-编码规范)
5. [AI 协作约定](#ai-协作约定)
6. [项目结构约定](#项目结构约定)
7. [常见开发模式](#常见开发模式)
8. [问题排查清单](#问题排查清单)

---

## 项目概述

### 基本信息

| 属性 | 值 |
|------|-----|
| 引擎版本 | Godot 4.6 |
| 渲染器 | Forward Plus |
| 物理引擎 | Jolt Physics (3D) |
| 脚本语言 | GDScript |
| MCP 工具数量 | 163 |

### 开发原则

本项目由多个 AI 协作开发，遵循以下原则：

1. **文档驱动** — 所有设计决策和约定必须记录在文档中
2. **模块化设计** — 功能独立、低耦合、高内聚
3. **类型安全** — GDScript 使用静态类型注解
4. **可测试性** — 关键逻辑需可通过 MCP 工具测试
5. **版本控制** — 每个功能模块完成后立即提交

---

## Godot 引擎核心概念

### 1. 节点系统 (Node System)

节点是 Godot 的基本构建块。每个节点提供特定功能。

```
Node                    # 基类，无特定功能
├── Node2D             # 2D 变换节点
│   ├── Sprite2D       # 2D 精灵渲染
│   ├── AnimatedSprite2D # 2D 动画精灵
│   ├── CharacterBody2D  # 2D 角色物理体
│   ├── StaticBody2D     # 2D 静态物理体
│   ├── Area2D           # 2D 区域检测
│   └── Camera2D         # 2D 摄像机
├── Node3D             # 3D 变换节点
│   ├── MeshInstance3D   # 3D 网格实例
│   ├── CharacterBody3D  # 3D 角色物理体
│   ├── RigidBody3D      # 3D 刚体
│   ├── Area3D           # 3D 区域检测
│   └── Camera3D         # 3D 摄像机
├── Control           # UI 控件基类
│   ├── Button         # 按钮
│   ├── Label          # 文本标签
│   ├── TextureRect    # 纹理矩形
│   └── Container      # 容器基类
├── Resource          # 资源基类
│   ├── Texture2D      # 2D 纹理
│   ├── ShaderMaterial # 着色器材质
│   └── AudioStream    # 音频流
└── AnimationPlayer   # 动画播放器
```

**关键属性**：
- `name`: 节点名称（场景内唯一）
- `owner`: 场景根节点引用
- `process_mode`: 处理模式（继承/暂停/总是）
- `process_priority`: 处理优先级

**生命周期回调**：
```gdscript
func _init():           # 构造函数，最早调用
func _enter_tree():     # 进入场景树时
func _ready():          # 节点及其子节点都就绪后
func _process(delta):   # 每帧调用（与帧率相关）
func _physics_process(delta): # 物理帧调用（固定时间步长）
func _exit_tree():      # 离开场景树时
```

### 2. 场景系统 (Scene System)

场景是节点的集合，可保存为 `.tscn` 文件并实例化。

```
场景 (.tscn)
├── 根节点
│   ├── 子节点1
│   ├── 子节点2
│   └── 子节点3
└── 继承的脚本 (.gd)
```

**场景实例化**：
```gdscript
# 预加载（编译时加载）
const PREFAB = preload("res://scenes/enemy.tscn")
var instance = PREFAB.instantiate()
add_child(instance)

# 动态加载
var scene = load("res://scenes/item.tscn")
var item = scene.instantiate()
add_child(item)
```

**场景继承**：
- 继承场景可复用和扩展父场景
- 子场景可添加新节点、修改属性、覆盖方法

### 3. 信号系统 (Signal System)

信号是 Godot 的观察者模式实现，用于节点间通信。

**定义信号**：
```gdscript
# 无参数信号
signal health_depleted

# 带参数信号
signal health_changed(old_value: int, new_value: int)
signal item_collected(item_name: String, count: int)
```

**发射信号**：
```gdscript
emit_signal("health_changed", old_hp, new_hp)
```

**连接信号**：
```gdscript
# 方式1：在代码中连接
enemy.died.connect(_on_enemy_died)
button.pressed.connect(_on_button_pressed)

# 方式2：通过编辑器连接（自动在 _ready 中处理）

# 带参数绑定
enemy.damaged.connect(_on_damaged.bind(enemy.id))
```

**信号回调**：
```gdscript
func _on_enemy_died():
    update_score()

func _on_damaged(amount: int, enemy_id: String):
    print("Enemy %s took %d damage" % [enemy_id, amount])
```

### 4. 脚本系统 (Script System)

Godot 支持 GDScript、C#、VisualScript 等脚本语言。

**GDScript 特点**：
- Python 风格语法
- 可选静态类型
- 内置 Godot API 访问
- 自动加载（Autoload）单例

**脚本模板**：
```gdscript
class_name Player                    # 类名（可选，用于类型提示）
extends CharacterBody2D              # 继承的基类

# 信号定义
signal health_changed(value: int)

# 导出属性（在检查器中可见）
@export var speed: float = 200.0
@export_range(0, 100) var health: int = 100
@export_file("*.tscn") var death_scene: String

# 类型化变量
var velocity: Vector2 = Vector2.ZERO
var is_jumping: bool = false

# 引用节点（使用 @onready 延迟初始化）
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    # 初始化逻辑
    pass

func _physics_process(delta: float) -> void:
    # 物理逻辑
    _apply_movement(delta)
    move_and_slide()

func _apply_movement(delta: float) -> void:
    # 辅助方法
    pass

func take_damage(amount: int) -> void:
    health -= amount
    emit_signal("health_changed", health)
    if health <= 0:
        die()

func die() -> void:
    queue_free()  # 删除节点
```

### 5. 资源系统 (Resource System)

资源是可复用的数据对象，保存为 `.tres` 文件。

**常用资源类型**：
```
Resource
├── Texture2D          # 纹理
│   ├── CompressedTexture2D
│   └── ImageTexture2D
├── Shader             # 着色器代码
├── ShaderMaterial     # 着色器材质
├── FontFile           # 字体
├── AudioStream        # 音频
│   ├── AudioStreamWAV
│   └── AudioStreamOggVorbis
├── Theme              # UI 主题
└── TileSet            # 瓦片集
```

**创建自定义资源**：
```gdscript
class_name ItemData
extends Resource

@export var name: String = ""
@export var icon: Texture2D
@export var description: String = ""
@export var stackable: bool = false
```

### 6. 输入系统 (Input System)

**InputMap 配置**：
- 在项目设置中定义动作名称
- 绑定键位、鼠标按钮、手柄按键

**检测输入**：
```gdscript
func _physics_process(delta: float) -> void:
    # 动作检测
    if Input.is_action_just_pressed("jump"):
        jump()
    
    if Input.is_action_pressed("move_left"):
        velocity.x -= speed
    
    # 直接检测按键
    if Input.is_key_pressed(KEY_SPACE):
        pass
    
    # 鼠标位置
    var mouse_pos: Vector2 = get_global_mouse_position()

func _input(event: InputEvent) -> void:
    # 处理单次事件
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            toggle_pause()
```

### 7. 物理系统 (Physics System)

**碰撞层/掩码**：
- 32 个物理层（0-31）
- Layer: 此物体所在的层
- Mask: 此物体检测的层

```gdscript
# 设置碰撞层
collision_layer = 1  # 第1层
collision_mask = 3   # 检测第1和第2层

# 常用设置方式
collision_layer = 0b0001  # 二进制
collision_mask = 0b0011
```

**物理体类型**：
| 类型 | 说明 |
|------|------|
| StaticBody2D/3D | 静态物体，不移动 |
| RigidBody2D/3D | 刚体，受物理引擎控制 |
| CharacterBody2D/3D | 角色体，自定义移动逻辑 |
| Area2D/3D | 区域，检测重叠 |

**Area 检测**：
```gdscript
# Area2D 信号
signal body_entered(body: Node2D)
signal body_exited(body: Node2D)
signal area_entered(area: Area2D)
signal area_exited(area: Area2D)

func _on_area_2d_body_entered(body: Node2D) -> void:
    if body is Player:
        body.take_damage(10)
```

---

## Godot MCP Pro 工具参考

### 工具分类总览

| 分类 | 工具数量 | 主要功能 |
|------|----------|----------|
| 场景操作 | scene_commands, scene_3d_commands | 创建/管理场景和节点 |
| 脚本操作 | script_commands | 创建/编辑 GDScript |
| 动画系统 | animation_commands, animation_tree_commands | 动画和状态机 |
| 物理系统 | physics_commands | 碰撞和物理配置 |
| 输入系统 | input_commands, input_map_commands | 输入模拟和映射 |
| 音频系统 | audio_commands | 音频总线和播放器 |
| UI系统 | theme_commands | 主题和UI样式 |
| 瓦片地图 | tilemap_commands | TileMap 操作 |
| 导航系统 | navigation_commands | 寻路配置 |
| 着色器 | shader_commands | Shader 编写和参数 |
| 粒子系统 | particle_commands | 粒子效果 |
| 分析工具 | analysis_commands | 性能和依赖分析 |
| 测试工具 | test_commands | 自动化测试 |
| 批处理 | batch_commands | 批量操作 |
| 运行时 | runtime_commands | 游戏运行时操作 |
| 导出 | export_commands | 项目导出 |
| 调试 | profiling_commands | 性能分析 |

### 核心工具详解

#### 1. 项目信息获取

```javascript
// 获取项目基本信息
get_project_info()
// 返回: { name, godot_version, renderer, viewport_size }

// 获取文件系统结构
get_filesystem_tree({ filter: "*.tscn" })  // 仅场景文件
get_filesystem_tree({ filter: "*.gd" })    // 仅脚本文件

// 获取当前场景树
get_scene_tree()

// 获取项目设置
get_project_settings()
```

#### 2. 场景创建与管理

```javascript
// 创建新场景
create_scene({
    root_type: "CharacterBody2D",  // 根节点类型
    path: "res://scenes/player.tscn"
})

// 添加子节点
add_node({
    parent_path: "Player",
    node_type: "Sprite2D",
    node_name: "Sprite",
    properties: {
        texture: "res://assets/player.png",
        position: "Vector2(0, 0)"
    }
})

// 更新节点属性
update_property({
    node_path: "Player/Sprite",
    property: "modulate",
    value: "Color(1, 0.5, 0.5, 1)"
})

// 保存场景
save_scene({ path: "res://scenes/player.tscn" })

// 设置主场景
set_main_scene({ path: "res://scenes/main.tscn" })
```

#### 3. 脚本操作

```javascript
// 创建脚本
create_script({
    path: "res://scripts/player.gd",
    content: `extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()`
})

// 编辑脚本 - 替换模式
edit_script({
    path: "res://scripts/player.gd",
    replacements: [
        { search: "speed: float = 200.0", replace: "speed: float = 300.0" }
    ]
})

// 编辑脚本 - 插入模式
edit_script({
    path: "res://scripts/player.gd",
    insert_at_line: 5,
    text: "var jump_force: float = 400.0"
})

// 验证脚本语法
validate_script({ path: "res://scripts/player.gd" })

// 附加脚本到节点
attach_script({
    node_path: "Player",
    script_path: "res://scripts/player.gd"
})
```

#### 4. 运行时测试

```javascript
// 启动游戏
play_scene({ mode: "current" })  // "current" | "main" | 文件路径

// 获取游戏截图
get_game_screenshot({ save_path: "screenshot.png" })

// 捕获多帧动画
capture_frames({
    count: 30,
    interval: 0.1,
    save_dir: "captures/"
})

// 获取运行时场景树
get_game_scene_tree()

// 获取节点运行时属性
get_game_node_properties({
    node_path: "Player",
    properties: ["position", "velocity", "health"]
})

// 设置运行时属性
set_game_node_property({
    node_path: "Player",
    property: "health",
    value: 100
})

// 模拟按键
simulate_key({
    key: "KEY_W",
    duration: 0.5  // 秒
})

// 模拟鼠标点击
simulate_mouse_click({
    position: [100, 200],
    button: "left",
    auto_release: true
})

// 模拟 InputMap 动作
simulate_action({
    action: "jump",
    duration: 0.3
})

// 停止游戏
stop_scene()
```

#### 5. 动画系统

```javascript
// 创建动画
create_animation({
    player_path: "AnimationPlayer",
    animation_name: "walk",
    length: 1.0,
    loop_mode: 1  // 0=无循环, 1=循环
})

// 添加动画轨道
add_animation_track({
    player_path: "AnimationPlayer",
    animation_name: "walk",
    track_path: "Sprite:position",
    track_type: "value"  // "value" | "transform" | "method"
})

// 设置关键帧
set_animation_keyframe({
    player_path: "AnimationPlayer",
    animation_name: "walk",
    track_index: 0,
    time: 0.0,
    value: "Vector2(0, 0)"
})
```

#### 6. 碰撞配置

```javascript
// 设置物理层名称
set_physics_layers({
    layers: {
        1: "player",
        2: "enemy",
        3: "environment",
        4: "collectible"
    }
})

// 配置碰撞层
setup_collision({
    node_path: "Player",
    collision_layer: ["player"],
    collision_mask: ["enemy", "collectible"]
})
```

#### 7. 项目配置

```javascript
// 设置项目设置
set_project_setting({
    section: "display/window/size",
    key: "viewport_width",
    value: 1920
})

// 添加输入动作
set_input_action({
    action_name: "jump",
    events: [{ type: "key", key: "KEY_SPACE" }]
})

// 添加自动加载单例
add_autoload({
    name: "GameManager",
    path: "res://singletons/game_manager.gd"
})
```

### 属性值格式规范

通过 MCP 工具设置属性时，值必须使用字符串格式：

| 类型 | 格式示例 |
|------|----------|
| Vector2 | `"Vector2(100, 200)"` |
| Vector3 | `"Vector3(1, 2, 3)"` |
| Color | `"Color(1, 0, 0, 1)"` 或 `"#ff0000"` |
| Rect2 | `"Rect2(0, 0, 100, 100)"` |
| bool | `"true"` 或 `"false"` |
| int | `"42"` |
| float | `"3.14"` |
| 枚举 | 使用整数值 `"0"`, `"1"` |
| 数组 | `"[1, 2, 3]"` |
| 字典 | `"{"key": "value"}"` |

---

## GDScript 编码规范

### 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 类名 | PascalCase | `PlayerController`, `HealthComponent` |
| 节点名 | PascalCase | `Player`, `EnemySpawner`, `UI_Canvas` |
| 函数/方法 | snake_case | `take_damage()`, `get_health()` |
| 变量 | snake_case | `move_speed`, `is_jumping` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_HEALTH`, `GRAVITY` |
| 信号 | snake_case | `health_changed`, `item_collected` |
| 枚举 | PascalCase (枚举名), SCREAMING_SNAKE_CASE (值) | `enum State { IDLE, WALKING, JUMPING }` |

### 文件组织

```gdscript
## 文件描述（可选）
## @author AI Developer
## @version 1.0

# 01. 类名和继承
class_name Player
extends CharacterBody2D

# 02. 信号
signal health_changed(old_value: int, new_value: int)
signal died

# 03. 枚举
enum State { IDLE, WALKING, JUMPING, DEAD }

# 04. 常量
const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0

# 05. 导出变量
@export var speed: float = 200.0
@export_range(0.1, 1.0) var acceleration: float = 0.5

# 06. 公共变量
var current_state: State = State.IDLE
var health: int = MAX_HEALTH

# 07. 私有变量
var _velocity: Vector2 = Vector2.ZERO
var _is_invincible: bool = false

# 08. @onready 变量
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 09. 虚方法/内置方法
func _ready() -> void:
    _initialize()

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_movement()
    move_and_slide()

# 10. 公共方法
func take_damage(amount: int) -> void:
    if _is_invincible:
        return
    
    var old_health := health
    health = max(0, health - amount)
    emit_signal("health_changed", old_health, health)
    
    if health <= 0:
        die()

func heal(amount: int) -> void:
    var old_health := health
    health = min(MAX_HEALTH, health + amount)
    emit_signal("health_changed", old_health, health)

func die() -> void:
    current_state = State.DEAD
    emit_signal("died")
    queue_free()

# 11. 私有方法
func _initialize() -> void:
    health = MAX_HEALTH
    current_state = State.IDLE

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        _velocity.y += GRAVITY * delta

func _handle_movement() -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    _velocity.x = direction.x * speed

# 12. 信号回调
func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("projectile"):
        take_damage(area.damage)
```

### 类型注解规则

```gdscript
# 必须使用类型注解的场景

# 函数参数和返回值
func move_to(target: Vector2) -> void:
    pass

func get_damage() -> int:
    return 10

# 类成员变量
var health: int = 100
var velocity: Vector2 = Vector2.ZERO

# 局部变量（使用 := 进行类型推断）
var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
var sprite := $Sprite2D as Sprite2D

# 数组类型
var inventory: Array[ItemData] = []
var enemies: Array[Node] = []

# 字典类型
var stats: Dictionary = {
    "strength": 10,
    "agility": 5
}

# 无类型数组的 for 循环必须显式注解
var items: Array = []  # 无类型数组

# 错误做法
for item in items:
    var name := item.name  # 类型推断失败

# 正确做法
for i in range(items.size()):
    var item: Dictionary = items[i]
    var name: String = item.get("name", "")
```

### 注释规范

```gdscript
## 类文档注释（双#）
## 用于描述类的用途和用法
## 
## 示例:
##     var player = Player.new()

# 单行注释（单#）
# 用于代码说明

# TODO: 待办事项
# FIXME: 需要修复的问题
# HACK: 临时解决方案
# NOTE: 重要说明

func complex_calculation() -> float:
    # 步骤1: 初始化
    var result: float = 0.0
    
    # 步骤2: 计算
    result = _calculate_base() * _calculate_multiplier()
    
    # 返回结果
    return result
```

---

## AI 协作约定

### 开发流程

```
1. 接收任务
   ↓
2. 阅读本文档和相关代码
   ↓
3. 使用 MCP 工具探索项目现状
   - get_project_info()
   - get_filesystem_tree()
   - get_scene_tree()
   ↓
4. 制定实现计划
   ↓
5. 实现功能
   - 创建/修改场景
   - 编写/修改脚本
   - 配置资源
   ↓
6. 测试验证
   - play_scene()
   - simulate_input()
   - get_game_screenshot()
   ↓
7. 提交代码
   - git add
   - git commit
```

### Git 提交规范

**Commit Message 格式**：
```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型 (type)**：
| 类型 | 说明 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| refactor | 重构（不改变功能） |
| docs | 文档更新 |
| style | 代码格式调整 |
| test | 测试相关 |
| chore | 构建/工具变动 |

**示例**：
```
feat(player): 添加二段跳功能

- 添加 jump_count 属性追踪跳跃次数
- 实现 _handle_jump() 方法
- 配置 InputMap 的 jump 动作

Closes #42
```

### 代码所有权标记

为便于追溯，建议在关键文件添加 AI 作者标记：

```gdscript
## @ai-author Claude (2026-04-05)
## @ai-task 实现玩家移动系统
```

### 冲突解决原则

1. **后提交者优先** - 后提交的 AI 负责解决冲突
2. **保留最佳实践** - 冲突时选择符合规范的版本
3. **通知人类** - 严重冲突需通知用户确认

---

## 项目结构约定

### 推荐目录结构

```
project_root/
├── project.godot           # 项目配置（勿直接编辑）
├── icon.svg                # 项目图标
│
├── scenes/                 # 场景文件
│   ├── main.tscn          # 主场景
│   ├── player/
│   │   └── player.tscn    # 玩家场景
│   ├── enemies/
│   │   ├── basic_enemy.tscn
│   │   └── boss_enemy.tscn
│   ├── levels/
│   │   ├── level_01.tscn
│   │   └── level_02.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── menu.tscn
│       └── pause_menu.tscn
│
├── scripts/                # 脚本文件
│   ├── player/
│   │   └── player.gd
│   ├── enemies/
│   │   └── base_enemy.gd
│   ├── ui/
│   │   └── hud.gd
│   └── singletons/        # 自动加载单例
│       ├── game_manager.gd
│       └── audio_manager.gd
│
├── assets/                 # 资源文件
│   ├── sprites/
│   │   ├── player/
│   │   └── enemies/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   ├── fonts/
│   └── shaders/
│
├── resources/              # 自定义资源
│   ├── items/
│   │   └── sword_data.tres
│   └── themes/
│       └── default_theme.tres
│
├── addons/                 # 插件目录
│   └── godot_mcp/
│
└── docs/                   # 文档目录
    ├── AI_DEVELOPER_GUIDE.md
    └── DESIGN_DECISIONS.md
```

### 文件命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 场景 | snake_case.tscn | `player.tscn`, `main_menu.tscn` |
| 脚本 | snake_case.gd | `player.gd`, `enemy_spawner.gd` |
| 资源 | snake_case.tres | `sword_data.tres` |
| 纹理 | snake_case.png | `player_idle.png` |
| 音频 | snake_case.wav/ogg | `jump_sound.wav` |

---

## 常见开发模式

### 1. 组件模式 (Component Pattern)

将功能拆分为独立组件：

```gdscript
# scripts/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(old_value: int, new_value: int)
signal died

@export var max_health: int = 100

var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    var old := current_health
    current_health = max(0, current_health - amount)
    emit_signal("health_changed", old, current_health)
    if current_health <= 0:
        emit_signal("died")

func heal(amount: int) -> void:
    var old := current_health
    current_health = min(max_health, current_health + amount)
    emit_signal("health_changed", old, current_health)
```

```gdscript
# scripts/enemies/base_enemy.gd
class_name BaseEnemy
extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
    health.died.connect(_on_died)

func _on_died() -> void:
    queue_free()
```

### 2. 状态机模式 (State Machine Pattern)

```gdscript
# scripts/state_machine/state.gd
class_name State
extends Node

var state_machine: NodeStateMachine
var parent: Node

func enter() -> void:
    pass

func exit() -> void:
    pass

func physics_process(delta: float) -> void:
    pass

func process(delta: float) -> void:
    pass
```

```gdscript
# scripts/state_machine/state_machine.gd
class_name NodeStateMachine
extends Node

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self
            child.parent = owner
    
    if states.size() > 0:
        current_state = states.values()[0]
        current_state.enter()

func change_state(state_name: String) -> void:
    var new_state := states.get(state_name.to_lower()) as State
    if new_state == null or new_state == current_state:
        return
    
    current_state.exit()
    current_state = new_state
    current_state.enter()

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_process(delta)
```

### 3. 单例管理器模式 (Singleton Manager Pattern)

```gdscript
# scripts/singletons/game_manager.gd
extends Node

# 信号
signal score_changed(new_score: int)
signal game_started
signal game_over

# 数据
var score: int = 0
var is_game_active: bool = false

func add_score(points: int) -> void:
    score += points
    emit_signal("score_changed", score)

func start_game() -> void:
    score = 0
    is_game_active = true
    emit_signal("game_started")

func end_game() -> void:
    is_game_active = false
    emit_signal("game_over")

func restart_game() -> void:
    get_tree().reload_current_scene()
```

使用方式：
```gdscript
# 在其他脚本中访问
GameManager.add_score(100)
GameManager.game_over.connect(_on_game_over)
```

### 4. 信号总线模式 (Signal Bus Pattern)

```gdscript
# scripts/singletons/event_bus.gd
extends Node

# 游戏事件
signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node)
signal player_died
signal level_completed
signal item_collected(item_name: String)
```

使用方式：
```gdscript
# 发射事件
EventBus.enemy_killed.emit(self)

# 监听事件
EventBus.enemy_killed.connect(_on_enemy_killed)
```

### 5. 对象池模式 (Object Pool Pattern)

```gdscript
# scripts/utils/object_pool.gd
class_name ObjectPool
extends Node

@export var pool_size: int = 10
@export var prefab: PackedScene

var _pool: Array[Node] = []
var _active: Array[Node] = []

func _ready() -> void:
    for i in pool_size:
        var instance := prefab.instantiate()
        instance.set_process(false)
        instance.hide()
        add_child(instance)
        _pool.append(instance)

func acquire() -> Node:
    if _pool.is_empty():
        return null
    
    var obj := _pool.pop_back()
    obj.set_process(true)
    obj.show()
    _active.append(obj)
    return obj

func release(obj: Node) -> void:
    if obj in _active:
        _active.erase(obj)
        obj.set_process(false)
        obj.hide()
        _pool.append(obj)

func release_all() -> void:
    for obj in _active.duplicate():
        release(obj)
```

---

## 问题排查清单

### 常见错误及解决方案

#### 1. 脚本错误

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `Parser Error: Typed array lacks type.` | 数组缺少类型注解 | 使用 `Array[Type]` 格式 |
| `Invalid get index 'xxx' (on base: 'nil')` | 节点引用失败 | 检查节点路径，使用 `has_node()` |
| `Can't change to this state` | AnimationTree 过渡条件未满足 | 检查过渡条件参数 |
| `Attempt to call function 'xxx' in base 'null'` | 对象为 null | 添加 null 检查 |

#### 2. 物理问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 穿墙 | 碰撞检测频率不足 | 使用 `move_and_slide()` |
| 碰撞不触发 | Layer/Mask 配置错误 | 检查 collision_layer 和 collision_mask |
| Area 不检测 | 信号未连接 | 调用 `connect()` 连接信号 |

#### 3. MCP 工具问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 脚本修改未生效 | 未重新加载项目 | 调用 `reload_project()` |
| 属性设置失败 | 值格式错误 | 使用正确的字符串格式 |
| 模拟输入无响应 | 输入未映射 | 使用 `set_input_action()` 配置 |

### 调试工具使用

```javascript
// 检查编辑器错误
get_editor_errors()

// 查看输出日志
get_output_log()

// 分析场景复杂度
analyze_scene_complexity({ scene_path: "res://scenes/main.tscn" })

// 检测循环依赖
detect_circular_dependencies()

// 性能监控
get_performance_monitors()
```

---

## 快速参考卡片

### 常用 MCP 工具速查

| 任务 | 工具 |
|------|------|
| 获取项目信息 | `get_project_info()` |
| 创建场景 | `create_scene()` |
| 添加节点 | `add_node()` |
| 创建脚本 | `create_script()` |
| 编辑脚本 | `edit_script()` |
| 启动游戏 | `play_scene()` |
| 截图 | `get_game_screenshot()` |
| 模拟按键 | `simulate_key()` |
| 模拟动作 | `simulate_action()` |
| 获取运行时属性 | `get_game_node_properties()` |
| 设置运行时属性 | `set_game_node_property()` |
| 保存场景 | `save_scene()` |

### GDScript 快速语法

```gdscript
# 变量
var name: String = "Player"
var health: int = 100
var speed: float = 200.0
var is_alive: bool = true
var position: Vector2 = Vector2.ZERO

# 常量
const MAX_ITEMS: int = 10

# 导出
@export var damage: int = 10
@export_range(0, 100) var chance: float = 50.0

# 信号
signal died
signal damaged(amount: int)

# 函数
func take_damage(amount: int) -> void:
    emit_signal("damaged", amount)

# 获取节点
@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = get_node("Timer")

# 信号连接
func _ready() -> void:
    button.pressed.connect(_on_button_pressed)

# 输入
func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("jump"):
        jump()
    var direction := Input.get_vector("left", "right", "up", "down")
```

---

## 附录

### A. 节点类型速查

#### 2D 节点
| 节点 | 用途 |
|------|------|
| Node2D | 2D 变换基类 |
| Sprite2D | 显示纹理 |
| AnimatedSprite2D | 帧动画 |
| CharacterBody2D | 角色物理体 |
| StaticBody2D | 静态物体 |
| RigidBody2D | 刚体 |
| Area2D | 区域检测 |
| Camera2D | 2D 摄像机 |
| TileMap | 瓦片地图 |
| ParallaxBackground | 视差背景 |

#### 3D 节点
| 节点 | 用途 |
|------|------|
| Node3D | 3D 变换基类 |
| MeshInstance3D | 显示 3D 模型 |
| CharacterBody3D | 角色物理体 |
| RigidBody3D | 刚体 |
| Area3D | 区域检测 |
| Camera3D | 3D 摄像机 |
| DirectionalLight3D | 平行光 |
| OmniLight3D | 点光源 |

#### UI 节点
| 节点 | 用途 |
|------|------|
| Control | UI 控件基类 |
| Button | 按钮 |
| Label | 文本 |
| TextureRect | 图像 |
| ProgressBar | 进度条 |
| Container | 容器基类 |
| VBoxContainer | 垂直布局 |
| HBoxContainer | 水平布局 |

### B. 内置类型速查

| 类型 | 说明 |
|------|------|
| Vector2 | 2D 向量 |
| Vector3 | 3D 向量 |
| Color | 颜色 (RGBA) |
| Rect2 | 2D 矩形 |
| Transform2D | 2D 变换 |
| Transform3D | 3D 变换 |
| Quaternion | 四元数 |
| Basis | 3D 基矩阵 |
| Array | 数组 |
| Dictionary | 字典 |
| String | 字符串 |
| int | 整数 |
| float | 浮点数 |
| bool | 布尔值 |

### C. 参考链接

- [Godot 4.6 官方文档](https://docs.godotengine.org/en/4.6/)
- [GDScript 语法参考](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/index.html)
- [Godot API 参考](https://docs.godotengine.org/en/4.6/classes/index.html)
- [Godot MCP Pro 技能文档](../addons/godot_mcp/skills.md)

---

*文档版本: 1.0*
*最后更新: 2026-04-05*
