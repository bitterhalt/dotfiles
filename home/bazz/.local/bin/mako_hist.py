#!/usr/bin/env python3
import sys
import json
import re
import subprocess


def parse_body(body: str) -> str:
    if not body:
        return ""
    body = re.sub(r"<[^>]+>", "", body)
    lines = [line.strip() for line in body.splitlines() if line.strip()]
    return " │ ".join(lines)


def format_entry(n: dict) -> str:
    icon = "❗" if n.get("urgency") == "critical" else "🔔"
    app = n.get("app_name", "unknown")
    summary = n.get("summary", "")
    body = parse_body(n.get("body", ""))

    line = f"{icon} [{app}] {summary}"
    if body:
        line += f" ➜ {body}"
    return line


def main():
    try:
        data = json.loads(subprocess.check_output(["makoctl", "history", "-j"]))
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        print(f"Failed to get notification history: {e}", file=sys.stderr)
        sys.exit(1)

    if not data:
        print("No notifications in history.")
        sys.exit(0)

    input_text = "\n".join(format_entry(n) for n in data)

    result = subprocess.run(
        [
            "fzf",
            "--no-info",
            "--layout",
            "reverse",
            "--border-label",
            "Mako-history",
            "--delimiter",
            " ➜ ",
            "--preview",
            "echo {2} | tr '│' '\\n' | fmt -s",
            "--preview-window",
            "bottom:wrap",
            "--bind",
            "alt-0:execute(pkill mako; mako & sleep 0.2 && pkill -RTMIN+3 waybar)+abort",
        ],
        input=input_text,
        text=True,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
