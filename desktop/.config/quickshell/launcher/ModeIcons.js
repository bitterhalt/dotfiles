// Prompt prefix icon for each launcher mode. Empty means no prefix.
var ICONS = {
  apps: "󰵆",
  emoji: "󰇷",
  files: "󰱼",
};

function icon(mode) {
  return ICONS[mode] || "";
}
