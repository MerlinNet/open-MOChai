#!/usr/bin/env python3
"""🐾 电子宠物生成器 - 根据 commit 历史生成宠物状态"""

import subprocess
import sys
import os

def get_git_info():
    try:
        r = subprocess.run(["git", "log", "--oneline"], capture_output=True, text=True, check=True)
        count = len([l for l in r.stdout.strip().split("\n") if l]) if r.stdout.strip() else 0
        r = subprocess.run(["git", "log", "-1", "--format=%H"], capture_output=True, text=True, check=True)
        return count, r.stdout.strip()
    except:
        return 0, ""

def get_stage(n):
    if n <= 10: return "egg", "🥚", "蛋蛋期"
    elif n <= 30: return "baby", "🐣", "幼崽期"
    elif n <= 100: return "grow", "🐾", "成长期"
    else: return "mature", "🐉", "成熟期"

def get_mood(h):
    v = int(h[-2:], 16) % 100 if len(h) >= 2 else 0
    if v <= 24: return "😊", "开心", "摇着尾巴转圈圈~"
    elif v <= 49: return "😴", "困倦", "打着小呼噜，睡得正香..."
    elif v <= 74: return "🤩", "兴奋", "兴奋地蹦蹦跳跳！"
    else: return "😈", "调皮", "偷偷把主人的袜子藏起来了~"

def get_action(n):
    if n % 2 == 0: return "🎮", "玩耍中", "在代码花园里追逐蝴蝶~"
    else: return "📚", "学习中", "认真研究 GDScript 中..."

ARTS = {
    "egg": [
        "      ___\n"
        "     /   \\\n"
        "    | o o |\n"
        "    |  ^  |\n"
        "     \\___/\n"
        "   💤 沉睡中...",

        "      .-~-. \n"
        "     /     \\\n"
        "    |  ~ ~  |\n"
        "    |   ^   |\n"
        "     \\___/\n"
        "   (˘ω˘) 好梦~",
    ],
    "baby": [
        "      /\\_/\\\n"
        "     ( o.o )\n"
        "      > ^ <\n"
        "     /|   |\\\n"
        "    (_|   |_)\n"
        "   🐣 出壳啦！",

        "       __\n"
        "      /  \\\n"
        "     | o.o|\n"
        "     |  ^ |\n"
        "      \\__/\n"
        "     /| |\\\n"
        "    🎵 咿呀学语~",
    ],
    "grow": [
        "        /\\_/\\\n"
        "       /`    \\\n"
        "      |  O O  |\n"
        "      |   >   |\n"
        "      |  \\_/\n"
        "       \\____/\n"
        "      /|    |\\\n"
        "     (_|____|_)\n"
        "      🌟 变强中~",

        "         .-~~~-. \n"
        "        /  .-.  \\\n"
        "       |  |   |  |\n"
        "       |  | ^ |  |\n"
        "        \\ |v| /\n"
        "         '---' \n"
        "        /|   |\\\n"
        "       / |   | \\\n"
        "      (_|___|_)\n"
        "      💫 活力满满！",
    ],
    "mature": [
        "          .--.\n"
        "         |o_o |\n"
        "         |:_/ |\n"
        "        //   \\ \\\n"
        "       (|     | )\n"
        "       /'\\_   _/`\\\n"
        "       \\___)=(___/\n"
        "      🐉 完全体神龙！",

        "         *  .  *\n"
        "       .-^---^-.\n"
        "      /  O   O  \\\n"
        "     |     >     |\n"
        "      \\    ^    /\n"
        "       `--| |--'\n"
        "         /| |\\\n"
        "        /_|_|_\\\n"
        "       | ★ 传说 |\n"
        "       |________|\n"
        "      👑 传说级！",
    ],
}

def main():
    n, h = get_git_info()
    stage, icon, sname = get_stage(n)
    micon, mname, mdesc = get_mood(h)
    aicon, aname, adesc = get_action(n)

    arts = ARTS[stage]
    art = arts[n % len(arts)]

    content = f"""# 🐾 我的电子宠物

```
{art}
```

**名字**: 小莫  **年龄**: {n} 次 commit  **阶段**: {icon} {sname}
**动作**: {aicon} {aname}  **心情**: {micon} {mname}

> {adesc}
> {mdesc}

_每次 commit 我都会成长变化哦！_
"""

    path = os.path.join(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip(), "README.md")
    with open(path, "w") as f:
        f.write(content)
    print(f"🐾 小莫已更新！({sname} | {mname} | {aname})")

if __name__ == "__main__":
    main()
