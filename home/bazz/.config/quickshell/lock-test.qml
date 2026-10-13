import QtQuick
import Quickshell
import "lock"
import "services"

ShellRoot {
	ThemeService { id: lockTheme }
	Config { id: lockConfig; theme: lockTheme }
	LockContext {
		id: lockContext
		onUnlocked: Qt.quit();
	}

	FloatingWindow {
		LockSurface {
			anchors.fill: parent
			context: lockContext
			config: lockConfig
		}
	}

	// exit the example if the window closes
	Connections {
		target: Quickshell

		function onLastWindowClosed() {
			Qt.quit();
		}
	}
}
