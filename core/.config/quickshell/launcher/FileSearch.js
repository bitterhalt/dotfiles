.pragma library

// Patterns passed to fd's --exclude option. Keep this list easy to edit as
// file search's scope and result types evolve.
var excludedPatterns = [
    "*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.svg",
    "*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi",
    "*.ttf", "*.otf", "*.woff", "*.woff2",
    "*.so", "*.so.*", "*.exe", "*.dll",
    "*.zip", "*.7z", "*.tar", "*.gz"
];

function command(needle, home) {
    var args = ["fd", "-H", "-t", "f", "--max-results", "100"];
    for (var i = 0; i < excludedPatterns.length; ++i)
        args.push("--exclude", excludedPatterns[i]);
    args.push("--", needle, home + "/.config", home + "/Documents", home + "/.local/bin", "/etc");
    return args;
}
