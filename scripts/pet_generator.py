#!/usr/bin/env python3
"""🐱 Okami 电子猫 - 根据 commit 历史生成猫咪状态"""

import subprocess
import os

def get_git_info():
    try:
        r = subprocess.run(["git", "log", "--oneline", "--grep=auto-merge", "--invert-grep", "--grep=skip ci", "--invert-grep", "--grep=Okami", "--invert-grep", "--grep=Merge", "--invert-grep"], capture_output=True, text=True, check=True)
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
    if v <= 24: return "😊", "开心", "在代码花园里追蝴蝶~"
    elif v <= 49: return "😴", "困倦", "趴在键盘上睡得正香..."
    elif v <= 74: return "🤩", "兴奋", "追着 bug 满屏跑！"
    else: return "😈", "调皮", "偷偷把场景文件藏起来了~"

def get_action(n):
    if n % 2 == 0: return "🧶", "玩耍中", "和毛线球大战三百回合~"
    else: return "🐟", "干饭中", "认真吃掉每个 commit 小鱼干..."

ARTS = {
    "egg": [
        "      .-~~~-. \n"
        "     /       \\\n"
        "    |  z   z  |\n"
        "    |    ^    |\n"
        "     \\  ~~~  /\n"
        "      '-...-' \n"
        "   💤 蛋蛋猫...",

        "       _____\n"
        "      /     \\\n"
        "     | ~   ~ |\n"
        "     |   ^   |\n"
        "      \\ ___ /\n"
        "      (_____)\n"
        "   (˘ω˘) 好梦~",
    ],
    "kitten": [
        "      /\\_/\\\n"
        "     ( o.o )\n"
        "      > ^ <\n"
        "     (_____)\n"
        "   🐱 喵~",

        "      /\\_/\\\n"
        "     ( ^.^ )\n"
        "      > \" <\n"
        "     (_____)\n"
        "   🎵 喵呜~",
    ],
    "cat": [
        "    /\\_/\\\n"
        "   ( o.o )\n"
        "    > ^ <\n"
        "   (_______)\n"
        "   🐈 趴趴猫~",

        "     /\\_/\\\n"
        "    ( O.o )\n"
        "     > ^ <\n"
        "    (_______)\n"
        "   ~~~~~~~\n"
        "   ✨ 慵懒猫~",
    ],
    "master": [
        "     /\\_/\\\n"
        "    ( ★ ★ )\n"
        "     > ^ <\n"
        "    (_______)\n"
        "   👑 猫仙~",

        "      /\\_/\\\n"
        "     ( ★ ★ )\n"
        "      > ^ <\n"
        "     (_____)\n"
        "    /       \\\n"
        "   🌟 传说猫仙~",
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
