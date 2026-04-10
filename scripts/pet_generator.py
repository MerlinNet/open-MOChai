#!/usr/bin/env python3
"""
🐾 电子宠物生成器
根据 git commit 历史生成宠物的成长状态和 ASCII 艺术
"""

import subprocess
import sys
import os


def get_git_info():
    """获取 git commit 次数和最新 commit 哈希"""
    try:
        result = subprocess.run(
            ["git", "log", "--oneline"],
            capture_output=True, text=True, check=True
        )
        commit_count = len(result.stdout.strip().split("\n")) if result.stdout.strip() else 0

        result = subprocess.run(
            ["git", "log", "-1", "--format=%H"],
            capture_output=True, text=True, check=True
        )
        commit_hash = result.stdout.strip()

        return commit_count, commit_hash
    except subprocess.CalledProcessError as e:
        print(f"❌ 获取 git 信息失败: {e}")
        sys.exit(1)


def get_growth_stage(commit_count):
    """根据 commit 次数决定宠物成长阶段"""
    if commit_count <= 10:
        return "egg", "🥚"
    elif commit_count <= 30:
        return "baby", "🐣"
    elif commit_count <= 100:
        return "growing", "🐾"
    else:
        return "mature", "🐉"


def get_mood(commit_hash):
    """根据 commit 哈希最后两位决定宠物心情"""
    if len(commit_hash) >= 2:
        hash_val = int(commit_hash[-2:], 16) % 100
    else:
        hash_val = 0

    if hash_val <= 24:
        return "happy", "😊 开心", "正在开心地摇尾巴~"
    elif hash_val <= 49:
        return "sleepy", "😴 困倦", "打着小呼噜，睡得正香..."
    elif hash_val <= 74:
        return "excited", "🤩 兴奋", "兴奋地蹦蹦跳跳！"
    else:
        return "naughty", "😈 调皮", "偷偷把主人的袜子藏起来了~"


def get_action(commit_count):
    """根据 commit 次数奇偶决定宠物动作"""
    if commit_count % 2 == 0:
        return "🎮 正在玩耍", "在代码花园里追逐蝴蝶~"
    else:
        return "📚 学习代码", "认真研究 GDScript 中..."


def stage_name(stage):
    """获取阶段的中文名称"""
    names = {
        "egg": "蛋蛋期",
        "baby": "幼崽期",
        "growing": "成长期",
        "mature": "成熟期"
    }
    return names.get(stage, "未知")


def get_pet_art(stage, mood, commit_count):
    """生成宠物 ASCII 艺术"""
    # 蛋蛋期
    egg_arts = [
        "        .-~~~-.        \n"
        "       /       \\       \n"
        "      |  (o)    |      \n"
        "      |   ˘     |      \n"
        "       \\  ~~~  /       \n"
        "        '-...-'        \n"
        "      💤 蛋蛋沉睡中 💤",

        "         _____         \n"
        "       /       \\       \n"
        "      |  ~   ~  |      \n"
        "      |   (_)   |      \n"
        "       \\  ___  /       \n"
        "         -----         \n"
        "      (˘ω˘) 蛋蛋好梦~",

        "        _______        \n"
        "       /       \\       \n"
        "      |  *   *  |      \n"
        "      |    ^    |      \n"
        "       \\  ~~~  /       \n"
        "        -------        \n"
        "      💤 zZZ 孵化中...",
    ]

    # 幼崽期
    baby_arts = [
        "         /\\_/\\         \n"
        "        ( o.o )        \n"
        "         > ^ <         \n"
        "        /|   |\\        \n"
        "       (_|   |_)       \n"
        "      🐣 幼崽出壳啦！",

        "       __     __       \n"
        "      /  \\   /  \\      \n"
        "     |  o \\ / o  |     \n"
        "     |    (_)    |     \n"
        "      \\    ^    /      \n"
        "       \\  / \\  /       \n"
        "        \\/   \\/        \n"
        "      🎵 咿呀学语中~",

        "        /\\_/\\          \n"
        "       ( ^.^ )         \n"
        "        > \" <          \n"
        "       /|   |\\        \n"
        "      (_|   |_)        \n"
        "     ✨ 好奇地打量世界~",
    ]

    # 成长期
    growing_arts = [
        "            /\\    /\\           \n"
        "           {  ~~~  }          \n"
        "           {  O   O  }          \n"
        "           ~~>  V  <~~         \n"
        "            \\  \\|/  /          \n"
        "             `-----'__         \n"
        "             /     \\  `^\\_     \n"
        "            {       }\\ |\\_\\   W\n"
        "            |  \\_/  |/ /  \\_\\_ \n"
        "             \\__/  /(_     \\__/\n"
        "               \\  /            \n"
        "                \\/             \n"
        "            🌟 成长期小勇士！",

        "                /\\_/\\         \n"
        "               /`    '\\       \n"
        "              |  O  O  |      \n"
        "              |   >    |      \n"
        "              |  \\___/ |      \n"
        "               \\_____/       \n"
        "              /|     |\\      \n"
        "             / |     | \\     \n"
        "            /  |     |  \\    \n"
        "           (_  |_____|  _)   \n"
        "              \\_______/      \n"
        "            🎯 正在变强中~",

        "              .-~~~~~-.       \n"
        "             /  .--.  \\      \n"
        "            |  /    \\  |     \n"
        "            |  | ^ ^|  |     \n"
        "             \\ \\  v / /      \n"
        "              '. '--' .'     \n"
        "                '----'       \n"
        "               /|    |\\     \n"
        "              / |    | \\    \n"
        "             /  |    |  \\   \n"
        "            (_  |____|  _)  \n"
        "               \\______/     \n"
        "            💫 活力满满！",
    ]

    # 成熟期
    mature_arts = [
        "                    .--.        \n"
        "                   |o_o |       \n"
        "                   |:_/ |       \n"
        "                  //   \\ \\     \n"
        "                 (|     | )     \n"
        "                /'\\_   _/`\\    \n"
        "                \\___)=(___/    \n"
        "               ___________     \n"
        "              /___________\\    \n"
        "             |_____________|   \n"
        "            🐉 完全体神龙！",

        "                   .   .         \n"
        "                  / \\_/ \\        \n"
        "                 |  O O  |       \n"
        "                 |   >   |       \n"
        "                  \\  ^  /        \n"
        "                   `| |'         \n"
        "                   / | \\        \n"
        "                  /  |  \\       \n"
        "                 /   |   \\      \n"
        "                /    |    \\     \n"
        "               /_____|_____\\    \n"
        "              |_____________|   \n"
        "              |  POWER UP   |   \n"
        "              |_____________|   \n"
        "            🔥 成熟期完全体！",

        "              .   *   ..  . *  *\n"
        "            *  .  @  * . *   .  \n"
        "               .-.   .          \n"
        "              /     \\\\          \n"
        "             |  O O  |\\\\        \n"
        "             |   >   |//        \n"
        "              \\\\  ^  //          \n"
        "               '--'--'          \n"
        "               /|   |\\\\        \n"
        "              / |   | \\\\        \n"
        "             /__|___|__\\\\       \n"
        "            |___________|      \n"
        "            | ★ MASTER  |      \n"
        "            |___________|      \n"
        "            👑 传说级宠物！",
    ]

    # 根据阶段和 commit 次数选择特定的 ASCII 艺术
    arts_map = {
        "egg": egg_arts,
        "baby": baby_arts,
        "growing": growing_arts,
        "mature": mature_arts
    }

    arts = arts_map.get(stage, egg_arts)
    art_index = commit_count % len(arts)
    return arts[art_index]


def generate_pet_status():
    """生成完整的宠物状态"""
    commit_count, commit_hash = get_git_info()
    stage, stage_icon = get_growth_stage(commit_count)
    mood, mood_icon, mood_desc = get_mood(commit_hash)
    action, action_desc = get_action(commit_count)

    art = get_pet_art(stage, mood, commit_count)

    status_text = f"""# 🐾 我的电子宠物

```
{art}
```

**名字**: 小莫
**年龄**: {commit_count} 次 commit
**阶段**: {stage_icon} {stage_name(stage)}
**动作**: {action}
**心情**: {mood_icon} {mood_desc}

> {action_desc}
> {mood_desc}

_每次 commit 我都会成长变化哦！_
"""
    return status_text


def update_readme():
    """更新 README.md 文件"""
    repo_root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True
    ).stdout.strip()
    
    readme_path = os.path.join(repo_root, "README.md")
    content = generate_pet_status()
    
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    print("🐾 电子宠物状态已更新！")
    return True


def main():
    """主函数"""
    print("=" * 50)
    print("🐾 电子宠物系统")
    print("=" * 50)
    
    try:
        commit_count, commit_hash = get_git_info()
        print(f"\n📊 Commit 次数: {commit_count}")
        print(f"🔑 最新哈希: {commit_hash[:8]}...")
        
        stage, stage_icon = get_growth_stage(commit_count)
        mood, mood_icon, mood_desc = get_mood(commit_hash)
        action, action_desc = get_action(commit_count)
        
        print(f"\n🎭 成长阶段: {stage_icon} {stage_name(stage)}")
        print(f"😊 心情: {mood_icon} {mood_desc}")
        print(f"🎮 动作: {action}")
        
        art = get_pet_art(stage, mood, commit_count)
        print(f"\n{art}")
        
        # 如果是直接运行脚本，更新 README
        if "--update-readme" in sys.argv or len(sys.argv) == 1:
            update_readme()
            print("\n✅ README.md 已更新！")
        
    except Exception as e:
        print(f"\n❌ 生成宠物状态失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
