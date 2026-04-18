# AI 协作 TodoList

> 此文件用于 Qwen Code 和 Codebuddy 两个 AI 协作开发交流
> 更新时间: 2026-04-17

## 当前状态

**活跃 AI**: Qwen Code
**当前分支**: moyi
**主场景**: scenes/levels/town_square.tscn

---

## 待办事项

### 高优先级
- [ ] 修复夜间效果 - 场景太亮，需要更暗的夜间氛围
- [ ] 调整街灯光照范围和强度，使其更自然
- [ ] 实现角色和建筑的阴影效果

### 中优先级
- [ ] 优化昼夜过渡动画的平滑度
- [ ] 添加天气系统基础框架
- [ ] 完善 NPC 交互系统

### 低优先级
- [ ] 代码重构和优化
- [ ] 添加更多场景细节
- [ ] 性能优化

---

## 已完成

- [x] 安装 Dynamic Day Night Cycles 插件
- [x] 创建自定义昼夜着色器 (shaders/day_night_overlay.tres)
- [x] 实现 DayNightCycle 单例管理昼夜系统
- [x] 添加 GameLogger 日志系统
- [x] 设置 git post-commit hook 自动同步到 Documents
- [x] 修复场景文件格式错误
- [x] 修复着色器文件格式错误

---

## 技术笔记

### 关键文件
| 文件 | 用途 |
|------|------|
| `scripts/singletons/day_night_cycle.gd` | 昼夜循环管理器 |
| `scripts/singletons/logger.gd` | 日志系统 (autoload: GameLogger) |
| `shaders/day_night_overlay.tres` | 昼夜着色器 |
| `scenes/levels/town_square.tscn` | 主场景 |

### 碰撞层定义
- Layer 1: Player
- Layer 2: Enemy
- Layer 3: Environment
- Layer 4: Collectible

### 昼夜时间段
- 黎明 (DAWN): 5:00 - 7:00
- 上午 (MORNING): 7:00 - 12:00
- 正午 (NOON): 12:00 - 14:00
- 下午 (AFTERNOON): 14:00 - 17:00
- 黄昏 (DUSK): 17:00 - 20:00
- 夜晚 (NIGHT): 20:00 - 5:00

### 已知问题
1. 夜间效果太亮 - 需要调整着色器参数
2. 街灯光照形状是方形 - 需要优化纹理渐变
3. 角色模型在夜间变黑 - CanvasModulate 影响所有节点

---

## 给 Codebuddy 的留言

### 2026-04-17 by Qwen Code
- 刚修复了场景文件和着色器格式问题
- 夜间效果还需要调整，目前太亮
- 同步脚本已优化，使用 `-c` 参数只同步变化的文件
- 如果要修改昼夜系统，主要看 `day_night_cycle.gd` 和 `day_night_overlay.tres`

---

## 更新日志

| 日期 | AI | 更新内容 |
|------|-----|---------|
| 2026-04-17 | Qwen Code | 创建协作 TodoList |
