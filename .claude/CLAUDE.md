# Open-MOChai 项目上下文

> 本文件由 Claude Code 自动读取，为 AI 提供项目上下文。

## 项目信息

| 属性 | 值 |
|------|-----|
| 项目名称 | Open-MOChai |
| 引擎 | Godot 4.6 |
| 渲染器 | Forward Plus |
| 物理引擎 | Jolt Physics |
| 脚本语言 | GDScript |
| MCP 工具 | 163 个 (Godot MCP Pro) |

## 开发模式

**本项目由多个 AI 协作开发，人类代码将很少或没有。**

## 必读文档

在开始任何开发工作之前，**必须先阅读以下文档**：

1. **AI 开发者指南**: `docs/AI_DEVELOPER_GUIDE.md`
   - Godot 引擎核心概念
   - MCP 工具使用方法
   - GDScript 编码规范
   - AI 协作约定
   - 常见开发模式

2. **Godot MCP Pro 技能文档**: `addons/godot_mcp/skills.zh.md`
   - 163 个 MCP 工具详细说明
   - 工作流示例
   - 重要规则和注意事项

## 开发流程

```
1. 阅读 docs/AI_DEVELOPER_GUIDE.md
2. 使用 MCP 工具探索项目
   - get_project_info()
   - get_filesystem_tree()
   - get_scene_tree()
3. 实现功能
4. 测试验证
5. Git 提交 (每个功能模块完成后)
```

## Git 提交规范

```
<type>(<scope>): <subject>

类型: feat | fix | refactor | docs | style | test | chore
```

## 项目结构

```
open-MOChai/
├── docs/                    # 文档
│   └── AI_DEVELOPER_GUIDE.md
├── scenes/                  # 场景文件
├── scripts/                 # 脚本文件
├── assets/                  # 资源文件
├── resources/               # 自定义资源
├── addons/godot_mcp/        # MCP 插件
└── skills/                  # 技能文档副本
```

## 重要提醒

- 不要直接编辑 `project.godot`，使用 `set_project_setting()`
- 脚本创建后需调用 `reload_project()`
- 属性值使用字符串格式：`"Vector2(100, 200)"`
- 经常保存场景：`save_scene()`

---

*AI 开发者：请始终遵循 `docs/AI_DEVELOPER_GUIDE.md` 中的规范*
