#!/usr/bin/env python3
import re
import os

NIRI_CONFIG = os.path.expanduser("~/.config/niri/binds.kdl")
OUTPUT_FILE = os.path.expanduser("~/.config/niri/keybinds.md")


def parse_niri_binds(config_path):
    markdown_content = "# ⌨️ Niri Keybindids\n\n"
    current_section = "General Bindings"
    table_started = False

    bind_pattern = re.compile(
        r'^\s*([^\s{]+)(?:\s+hotkey-overlay-title="([^"]+)")?.*{\s*([^}]+)\s*}'
    )
    section_pattern = re.compile(r"^\s*//\s*(.*)")

    with open(config_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip("\n")

            # Catch sections defined by comments
            section_match = section_pattern.match(line)
            if section_match:
                comment = section_match.group(1).strip()
                # Skip small inline comments, catch section headers
                if (
                    len(comment) > 3
                    and not comment.startswith("/")
                    and "allow-when-locked" not in comment
                ):
                    current_section = comment
                    markdown_content += f"\n## {current_section}\n"
                    markdown_content += "| Keybinding | Description | Action / Command |\n| :--- | :--- | :--- |\n"
                    table_started = True
                continue

            bind_match = bind_pattern.match(line)
            if bind_match:
                if not table_started:
                    markdown_content += f"\n## {current_section}\n"
                    markdown_content += "| Keybinding | Description | Action / Command |\n| :--- | :--- | :--- |\n"
                    table_started = True

                keys = bind_match.group(1).strip()
                title = bind_match.group(2) if bind_match.group(2) else "Custom Action"
                action = bind_match.group(3).strip().replace(";", "")

                # Clean up string visuals for commands
                action = (
                    action.replace("spawn-sh ", "")
                    .replace("spawn ", "")
                    .replace('"', "")
                )

                markdown_content += f"| `{keys}` | {title} | `{action}` |\n"

    return markdown_content


def main():
    if not os.path.exists(NIRI_CONFIG):
        print(f"Error: Could not find Niri config at {NIRI_CONFIG}")
        return

    md_data = parse_niri_binds(NIRI_CONFIG)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(md_data)

    print(f"Success!")


if __name__ == "__main__":
    main()
