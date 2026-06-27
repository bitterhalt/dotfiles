# ⌨️ Niri Keybindids


## General Bindings
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Return` | Open Terminal | `foot` |
| `Mod+Shift+Delete` | BTOP | `foot -a btop -T poptop -e btop` |
| `Mod+Ctrl+Delete` | HTOP | `foot -a htop -T poptop -e htop` |
| `Mod+Shift+F11` | Toggle Idle-deamon | `idle.sh -t && pkill -SIGRTMIN+1 waybar` |
| `Mod+V` | Open Editor | `foot -T nvim -e nvim` |
| `Mod+F11` | Lock Screen | `swaylock -C ~/.cache/wal/colors-swaylock` |
| `Mod+Shift+A` | Custom Action | `~/.config/niri/scripts/apps.sh` |
| `Mod+T` | Display Time | `noti_time` |
| `Mod+F2` | Open Calculator | `galculator` |

## Www/Mail
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+W` | Web browser | `vivaldi` |
| `Mod+M` | Open Email | `thunderbird` |

## File managers
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+E` | TUI Filemanager | `foot -T lf -e lf` |
| `Mod+Shift+E` | GUI Filemanager | `thunar` |

## System
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+B` | Toggle Waybar | `bar-hider.sh` |

## Menus
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Ctrl+C` | Open Clipboard | `fuzzel_clipboard` |
| `Mod+Ctrl+D` | Hide Notification Pop-ups | `makoctl mode -t dnd && pkill -SIGRTMIN+3 waybar` |
| `Mod+Ctrl+E` | Browse Emojis 😀 | `fuzzel_emoji` |
| `Mod+Ctrl+H` | Show Notfication History | `foot -T 'Mako History' -e mako_hist.py` |
| `Mod+Ctrl+P` | Color Picker | `wl-colorpicker` |
| `Mod+D` | Run Application | `fuzzel --line-height 26` |
| `Mod+Escape` | Open Power Menu | `fuzzel_power` |
| `Mod+F3` | Custom Action | `~/.config/niri/scripts/keybinds.sh` |
| `Mod+F4` | Process Killer | ` fuzzel_killer` |
| `Mod+F5` | Passwords and AUTH | `fuzzel_submap -pass` |
| `Mod+Shift+D` | Run Binary | `fuzzel_run` |
| `Mod+Shift+T` | Attach Tmux sessions | `fuzzel_tmuxer` |
| `Mod+F8` | Open Screenshot Menu | `fuzzel_screenshot` |

## Submaps
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+A` | Quick apps | `fuzzel_submap -apps` |
| `Mod+F1` | Audio and connection switcher | `fuzzel_submap -system` |
| `Mod+F12` | System and shell setting | `fuzzel_submap -settings` |
| `Mod+N` | Open Notes | `fuzzel_submap -notes` |
| `Mod+Shift+W` | Set Wallpaper | `fuzzel_submap -theming` |
| `Mod+U` | Install and Mange Packages | `fuzzel_submap -packages` |

## Screen Recording
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Ctrl+F8` | Stop Recording | `wl-record -k && pkill -SIGRTMIN+2 waybar` |
| `Mod+Print` | Screenshot (Full Screen) | `wl-shot -f` |
| `Mod+Shift+Print` | Screenshot (Region) | `wl-shot -re` |

## Media - Volume
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `XF86AudioRaiseVolume` | Increase Volume | `volume.sh up` |
| `XF86AudioLowerVolume` | Decrease Volume | `volume.sh down` |
| `Ctrl+Shift+Up` | Increase Volume | `volume.sh up` |
| `Ctrl+Shift+Down` | Decrease Volume | `volume.sh down` |
| `XF86AudioMute` | Mute Audio | `/volume.sh mute` |
| `XF86AudioMicMute` | Mute Microphone | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| `Mod+F10` | Mute Microphone | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |

## Media - Playback
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `XF86AudioPlay` | Play/Pause | `~/.config/niri/scripts/mediactrl.sh --play` |
| `XF86AudioStop` | Stop Playback | `~/.config/niri/scripts/mediactrl.sh --stop` |
| `XF86AudioPrev` | Previous Track | `~/.config/niri/scripts/mediactrl.sh --prv` |
| `XF86AudioNext` | Next Track | `~/.config/niri/scripts/mediactrl.sh --nxt` |
| `Mod+Shift+M` | Show Current Track | `~/.config/niri/scripts/mediactrl.sh --noti` |

## Hardware - Brightness
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `XF86MonBrightnessUp` | Increase Brightness | `brightnessctl --class=backlight set +10%` |
| `XF86MonBrightnessDown` | Decrease Brightness | `brightnessctl --class=backlight set 10%-` |

## Overview
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Tab` | Overview | `toggle-overview` |

## Close Window
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Q` | Close Window | `close-window` |

## Navigation (Focus)
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Left` | Focus Left | `focus-column-left` |
| `Mod+Down` | Focus Down | `focus-window-or-workspace-down` |
| `Mod+J` | Focus Down (Vim) | `focus-window-or-workspace-down` |
| `Mod+K` | Focus Up (Vim) | `focus-window-or-workspace-up` |
| `Mod+Up` | Focus Up | `focus-window-or-workspace-up` |
| `Mod+Right` | Focus Right | `focus-column-right` |
| `Mod+H` | Focus Left (Vim) | `focus-column-left` |
| `Mod+L` | Focus Right (Vim) | `focus-column-right` |

## Moving Windows/Columns
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Shift+Left` | Move Left | `move-column-left` |
| `Mod+Shift+Down` | Move Down | `move-window-down-or-to-workspace-down` |
| `Mod+Shift+Up` | Move Up | `move-window-up-or-to-workspace-up` |
| `Mod+Shift+Right` | Move Right | `move-column-right` |
| `Mod+Shift+H` | Move Left (Vim) | `move-column-left` |
| `Mod+Shift+J` | Move Down (Vim) | `move-window-down-or-to-workspace-down` |
| `Mod+Shift+K` | Move Up (Vim) | `move-window-up-or-to-workspace-up` |
| `Mod+Shift+L` | Move Right (Vim) | `move-column-right` |
| `Mod+Home` | Focus First Column | `focus-column-first` |
| `Mod+End` | Focus Last Column | `focus-column-last` |
| `Mod+Shift+Home` | Move Column to First | `move-column-to-first` |
| `Mod+Shift+End` | Move Column to Last | `move-column-to-last` |

## Monitor Management
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Alt+Left` | Focus Monitor Left | `focus-monitor-left` |
| `Mod+Alt+Down` | Focus Monitor Down | `focus-monitor-down` |
| `Mod+Alt+Up` | Focus Monitor Up | `focus-monitor-up` |
| `Mod+Alt+Right` | Focus Monitor Right | `focus-monitor-right` |
| `Mod+Alt+H` | Focus Monitor Left (Vim) | `focus-monitor-left` |
| `Mod+Alt+J` | Focus Monitor Down (Vim) | `focus-monitor-down` |
| `Mod+Alt+K` | Focus Monitor Up (Vim) | `focus-monitor-up` |
| `Mod+Alt+L` | Focus Monitor Right (Vim) | `focus-monitor-right` |
| `Mod+Alt+Ctrl+Left` | Move Column to Monitor Left | `move-column-to-monitor-left` |
| `Mod+Alt+Ctrl+Down` | Move Column to Monitor Down | `move-column-to-monitor-down` |
| `Mod+Alt+Ctrl+Up` | Move Column to Monitor Up | `move-column-to-monitor-up` |
| `Mod+Alt+Ctrl+Right` | Move Column to Monitor Right | `move-column-to-monitor-right` |
| `Mod+Alt+Ctrl+H` | Move Column to Monitor Left (Vim) | `move-column-to-monitor-left` |
| `Mod+Alt+Ctrl+J` | Move Column to Monitor Down (Vim) | `move-column-to-monitor-down` |
| `Mod+Alt+Ctrl+K` | Move Column to Monitor Up (Vim) | `move-column-to-monitor-up` |
| `Mod+Alt+Ctrl+L` | Move Column to Monitor Right (Vim) | `move-column-to-monitor-right` |

## Workspace Management
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Page_Down` | Focus Workspace Down | `focus-workspace-down` |
| `Mod+Page_Up` | Focus Workspace Up | `focus-workspace-up` |
| `Mod+Ctrl+Page_Down` | Move Column to Workspace Down | `move-column-to-workspace-down` |
| `Mod+Ctrl+Page_Up` | Move Column to Workspace Up | `move-column-to-workspace-up` |
| `Mod+Shift+Page_Down` | Move Workspace Down | `move-workspace-down` |
| `Mod+Shift+Page_Up` | Move Workspace Up | `move-workspace-up` |

## Mouse Wheel Bindings
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+WheelScrollDown` | Workspace Down | `focus-workspace-down` |
| `Mod+WheelScrollUp` | Workspace Up | `focus-workspace-up` |
| `Mod+Ctrl+WheelScrollDown` | Move Column Workspace Down | `move-column-to-workspace-down` |
| `Mod+Ctrl+WheelScrollUp` | Move Column Workspace Up | `move-column-to-workspace-up` |
| `Mod+WheelScrollRight` | Focus Right | `focus-column-right` |
| `Mod+WheelScrollLeft` | Focus Left | `focus-column-left` |
| `Mod+Ctrl+WheelScrollRight` | Move Column Right | `move-column-right` |
| `Mod+Ctrl+WheelScrollLeft` | Move Column Left | `move-column-left` |

## Numeric Workspaces (1-9)
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+1` | Switch to Workspace 1 | `focus-workspace 1` |
| `Mod+2` | Switch to Workspace 2 | `focus-workspace 2` |
| `Mod+3` | Switch to Workspace 3 | `focus-workspace 3` |
| `Mod+4` | Switch to Workspace 4 | `focus-workspace 4` |
| `Mod+5` | Switch to Workspace 5 | `focus-workspace 5` |
| `Mod+6` | Switch to Workspace 6 | `focus-workspace 6` |
| `Mod+7` | Switch to Workspace 7 | `focus-workspace 7` |
| `Mod+8` | Switch to Workspace 8 | `focus-workspace 8` |
| `Mod+9` | Switch to Workspace 9 | `focus-workspace 9` |
| `Mod+Shift+1` | Move Column to Workspace 1 | `move-column-to-workspace 1 focus=false` |
| `Mod+Shift+2` | Move Column to Workspace 2 | `move-column-to-workspace 2 focus=false` |
| `Mod+Shift+3` | Move Column to Workspace 3 | `move-column-to-workspace 3 focus=false` |
| `Mod+Shift+4` | Move Column to Workspace 4 | `move-column-to-workspace 4 focus=false` |
| `Mod+Shift+5` | Move Column to Workspace 5 | `move-column-to-workspace 5 focus=false` |
| `Mod+Shift+6` | Move Column to Workspace 6 | `move-column-to-workspace 6 focus=false` |
| `Mod+Shift+7` | Move Column to Workspace 7 | `move-column-to-workspace 7 focus=false` |
| `Mod+Shift+8` | Move Column to Workspace 8 | `move-column-to-workspace 8 focus=false` |
| `Mod+Shift+9` | Move Column to Workspace 9 | `move-column-to-workspace 9 focus=false` |
| `Mod+0` | Previous Workspace | `focus-workspace-previous` |

## Column and Window Organization
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Comma` | Consume Window into Column | `consume-window-into-column` |
| `Mod+Period` | Expel Window from Column | `expel-window-from-column` |
| `Mod+Shift+Comma` | Consume/Expel Window Left | `consume-or-expel-window-left` |
| `Mod+Shift+Period` | Consume/Expel Window Right | `consume-or-expel-window-right` |

## Sizing and Layout
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+R` | Switch Preset Width | `switch-preset-column-width` |
| `Mod+Ctrl+R` | Reset Window Height | `reset-window-height` |
| `Mod+Ctrl+Shift+R` | Switch Preset Height | `switch-preset-window-height` |
| `Mod+F` | Maximize Column | `maximize-column` |
| `Mod+Shift+F` | Fullscreen Window | `fullscreen-window` |
| `Mod+Ctrl+Shift+F` | Toggle Windowed Fullscreen | `toggle-windowed-fullscreen` |
| `Mod+Ctrl+F` | Maximize Window to Edges | `maximize-window-to-edges` |
| `Mod+Ctrl+M` | Expand Column Width | `expand-column-to-available-width` |
| `Mod+C` | Center Column | `center-column` |
| `Mod+Shift+C` | Center All Visible Columns | `center-visible-columns` |
| `Mod+Ctrl+Left` | Decrease Column Width | `set-column-width -10%` |
| `Mod+Ctrl+Right` | Increase Column Width | `set-column-width +10%` |
| `Mod+Ctrl+Down` | Decrease Window Height | `set-window-height -10%` |
| `Mod+Ctrl+Up` | Increase Window Height | `set-window-height +10%` |

## Floating and Tabs
| Keybinding | Description | Action / Command |
| :--- | :--- | :--- |
| `Mod+Space` | Toggle Floating | `toggle-window-floating` |
| `Mod+Ctrl+Space` | Toggle Floating/Tiling Focus | `switch-focus-between-floating-and-tiling` |
| `Mod+G` | Toggle Column Tabs | `toggle-column-tabbed-display` |
