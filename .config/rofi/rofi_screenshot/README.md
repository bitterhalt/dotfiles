# screenshot

## Dependencies

- [ffmpeg](http://ffmpeg.org/)
- [ffcast](https://github.com/lolilolicon/FFcast)
- [rofi](https://github.com/davatorium/rofi) - only if you want to use the menu

## How to install

- add `screenshot` file (or a `soft link`) to a directory in your `$PATH`. (`~/.local/bin`)
- copy `rofi-screenshot` directory to `~/.config/rofi`

## Other useful info

- The record+audio part will fail sometimes. You will get this error likely.
  - [Thread message queue blocking; consider raising the thread_queue_size option (current value: 8](https://stackoverflow.com/questions/61723571/correct-usage-of-thread-queue-size-in-ffmpeg)
- The record+audio part assumes that you use `pulseaudio` if not change it, here are some useful links
  - [How to capture desktop](https://trac.ffmpeg.org/wiki/Capture/Desktop)
  - [Capture using ALSA](https://trac.ffmpeg.org/wiki/Capture/ALSA)
  - [Capture using pulse audio](https://trac.ffmpeg.org/wiki/Capture/PulseAudio)
- using compositor `picom` you get shadow in the recording, add this to your config file
  - `shadow-exclude = [ "window_type = 'unknown'" ]`