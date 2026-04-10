#!/usr/bin/env python3
"""🐱 Okami 电子猫 - 根据 commit 历史生成猫咪状态"""

import subprocess
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
    if n <= 10: return "egg", "🥚", "沉睡期"
    elif n <= 30: return "kitten", "🐱", "幼猫期"
    elif n <= 100: return "cat", "🐈", "成长期"
    else: return "master", "👑", "猫仙期"

def get_mood(h):
    v = int(h[-2:], 16) % 100 if len(h) >= 2 else 0
    if v <= 24: return "😊", "开心", "呼噜呼噜踩奶中~"
    elif v <= 49: return "😴", "困倦", "蜷成一团睡得正香..."
    elif v <= 74: return "🤩", "兴奋", "追着逗猫棒满屋跑！"
    else: return "😈", "调皮", "把水杯推到了地上~"

def get_action(n):
    if n % 2 == 0: return "🧶", "玩耍中", "和毛线球大战三百回合~"
    else: return "🐟", "干饭中", "认真享用小鱼干中..."

ARTS = {
    "egg": [
        "      ___\n"
        "     /   \\\n"
        "    | z z |\n"
        "    |  ^  |\n"
        "     \\___/\n"
        "   💤 蛋蛋猫沉睡中...",

        "      .-~-. \n"
        "     /     \\\n"
        "    |  ~ ~  |\n"
        "    |   ^   |\n"
        "     \\___/\n"
        "   (˘ω˘) 蛋蛋猫好梦~",
    ],
    "kitten": [
        "      /\\_/\\\n"
        "     ( o.o )\n"
        "      > ^ <\n"
        "     /|   |\\\n"
        "    (_|   |_)\n"
        "   🐱 小奶猫出壳啦！",

        "       /\\_/\\\n"
        "      ( ^.^ )\n"
        "       > \" <\n"
        "      /|   |\\\n"
        "     (_|   |_)\n"
        "   🎵 喵呜喵呜~",
    ],
    "cat": [
        "        /\\_/\\\n"
        "       /`    \\\n"
        "      |  O O  |\n"
        "      |   >   |\n"
        "      |  \\_/ |\n"
        "       \\____/\n"
        "      /|    |\\\n"
        "     (_|____|_)\n"
        "   🐈 优雅大猫咪~",

        "         .-~~~-. \n"
        "        /  .-.  \\\n"
        "       |  |   |  |\n"
        "       |  | ^ |  |\n"
        "        \\ |v| /\n"
        "         '---' \n"
        "        /|   |\\\n"
        "       / |   | \\\n"
        "      (_|___|_)\n"
        "   ✨ 猫咪大人驾到！",
    ],
    "master": [
        "          .--.\n"
        "         |o_o |\n"
        "         |:_/ |\n"
        "        //   \\ \\\n"
        "       (|     | )\n"
        "       /'\\_   _/`\\\n"
        "       \\___)=(___/\n"
        "      👑 九尾猫仙！",

        "         *  .  *\n"
        "       .-^---^-.\n"
        "      /  O   O  \\\n"
        "     |     >     |\n"
        "      \\    ^    /\n"
        "       `--| |--'\n"
        "         /| |\\\n"
        "        /_|_|_\\\n"
        "       | ★ 猫仙 |\n"
        "       |________|\n"
        "      🔮 传说级猫仙！",
    ],
}

def main():
    n, h = get_git_info()
    stage, icon, sname = get_stage(n)
    micon, mname, mdesc = get_mood(h)
    aicon, aname, adesc = get_action(n)

    arts = ARTS[stage]
    art = arts[n % len(arts)]

    content = f"""# 🐱 Okami

```
{art}
```

**年龄**: {n} 次 commit  **阶段**: {icon} {sname}
**动作**: {aicon} {aname}  **心情**: {micon} {mname}

> {adesc}
> {mdesc}

_每次 commit Okami 都会成长变化哦！_
"""

    path = os.path.join(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip(), "README.md")
    with open(path, "w") as f:
        f.write(content)
    print(f"🐱 Okami 已更新！({sname} | {mname} | {aname})")

if __name__ == "__main__":
    main()
