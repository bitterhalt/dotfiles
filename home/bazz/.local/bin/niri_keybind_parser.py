#!/usr/bin/env python3

from pathlib import Path
import re

CONFIG = Path.home() / ".config/niri/binds.kdl"

OUTPUTS = [
    Path.home() / "Documents/personal/notes/niri-binds.md",
    Path.home() / ".config/niri/keybinds.md",
]

section = "General"
sections = {}

comment_re = re.compile(r"^\s*//\s*(.+)$")

bind_re = re.compile(
    r"^\s*([^\s{]+)"
    r'(?:.*?hotkey-overlay-title="([^"]+)")?'
    r".*?\{\s*(.*?)\s*;\s*\}"
)


def action_name(action: str) -> str:
    action = action.strip()

    if action.startswith("spawn"):
        return "Launch program"

    action = re.sub(r'"[^"]*"', "", action)
    action = re.sub(r"\s+", " ", action).strip()

    return action.replace("-", " ").title()


with CONFIG.open(encoding="utf-8") as f:
    for line in f:
        line = line.rstrip()

        # Section headers
        m = comment_re.match(line)
        if m:
            section = m.group(1).strip()
            sections.setdefault(section, [])
            continue

        # Keybinds
        m = bind_re.match(line)
        if not m:
            continue

        key = m.group(1)
        title = m.group(2)
        action = m.group(3)

        desc = title if title else action_name(action)

        sections.setdefault(section, []).append((key, desc))


markdown = [
    "# Niri Keybindings",
    "",
    "_Generated automatically from `~/.config/niri/binds.kdl`._",
    "",
]

for section, binds in sections.items():
    markdown.append(f"## {section}")
    markdown.append("")
    markdown.append("| Key | Action |")
    markdown.append("| --- | ------ |")

    for key, desc in binds:
        markdown.append(f"| `{key}` | {desc} |")

    markdown.append("")

text = "\n".join(markdown)

for output in OUTPUTS:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding="utf-8")

print("Generated:")
for output in OUTPUTS:
    print(f"  {output}")
