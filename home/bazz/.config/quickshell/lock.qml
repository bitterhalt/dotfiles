import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "lock"
import "services"

ShellRoot {
	ThemeService { id: lockTheme }
	Config { id: lockConfig; theme: lockTheme }
	// This stores all the information shared between the lock surfaces on each screen.
	LockContext {
		id: lockContext

		onUnlocked: {
			// Unlock the screen before exiting, or the compositor will display a
			// fallback lock you can't interact with.
			lock.locked = false;

			Qt.quit();
		}
	}

	WlSessionLock {
		id: lock

		// Lock the session immediately when quickshell starts.
		locked: true

		WlSessionLockSurface {
			LockSurface {
				anchors.fill: parent
				context: lockContext
				config: lockConfig
			}
		}
	}

	IpcHandler {
		target: "locker"
		function isSecure(): bool { return lock.secure; }
	}
}
