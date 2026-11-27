//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

////////////////////
// RENDERING MODE //
////////////////////
// Remove first 2 "//" to run without GPU renderer. This is good way to save some RAM static shells like this one, since system does not need to load complex GPU stack.
// Trade-off is larger CPU utilization, but IRL you probably wont see any difference with modern CPU. If you add some costly stuff like blurs and transistions use GPU
////@ pragma Env QT_QUICK_BACKEND=software

import QtQuick
import Quickshell
import Quickshell.Io

import "components"
import "services"
import "recorder"
import "osd"
import "bar"
import "menus"
import "bar/modules/bluetooth"
import "notifications"
import "launcher"
import "clipboard"
import "translator"
import "wallpaper"
import "updates"

ShellRoot {
    id: root

    readonly property bool barVisible: appSettingsService.barVisible
    readonly property var activeScreen: {
        const screens = Quickshell.screens;

        if (!screens || screens.length === 0)
            return null;

        for (let i = 0; i < screens.length; ++i) {
            if (screens[i].name === niriService.focusedOutput)
                return screens[i];
        }

        return screens[0];
    }

    ThemeService {
        id: themeService
    }

    Settings {
        id: appConfig
        theme: themeService
    }

    SettingsService {
        id: appSettingsService
    }

    ResumeService {
        id: appResumeService
    }

    PolkitService {
        config: appConfig
        targetScreen: root.activeScreen
    }

    NiriService {
        id: niriService
    }

    AudioService {
        id: appAudioService
        config: appConfig
    }

    NetworkService {
        id: appNetworkService
    }

    DriveService {
        id: appDriveService
        resumeService: appResumeService
    }

    PrivacyService {
        id: appPrivacyService
    }

    Updates {
        id: appUpdates
        config: appConfig
        targetScreen: root.activeScreen
    }

    LockService {
        id: appLockService
    }

    Loader {
        active: appConfig.launcherEnabled

        sourceComponent: Component {
            Launcher {
                config: appConfig
                targetScreen: root.activeScreen
            }
        }
    }

    Clipboard {
        config: appConfig
        targetScreen: root.activeScreen
    }

    Translator {
        config: appConfig
        targetScreen: root.activeScreen
    }

    WallpaperService {
        id: appWallpaperService
    }

    WallpaperLayer {
        service: appWallpaperService
    }

    Wallpaper {
        id: appWallpaperPicker
        config: appConfig
        wallpaperService: appWallpaperService
        targetScreen: root.activeScreen
        settingsService: appSettingsService
    }

    NotificationService {
        id: appNotificationService
        config: appConfig
    }

    NotificationPopup {
        id: appNotificationPopup
        config: appConfig
        targetScreen: root.activeScreen
        notificationService: appNotificationService
    }

    Connections {
        target: appNotificationPopup

        function onOpenNotificationCenterRequested(): void {
            shellUiService.notificationCenterActionRequested("open");
        }
    }

    Connections {
        target: appNotificationService

        function onToastSerialChanged(): void {
            if (appNotificationService.historyOpenCount > 0) {
                appNotificationService.finishToast(appNotificationService.toastNotification);
                return;
            }
            if (!appNotificationService.dnd && appNotificationService.toastNotification) {
                appNotificationPopup.show(appNotificationService.toastNotification);
            }
        }

        function onDndChanged(): void {
            if (appNotificationService.dnd)
                appNotificationPopup.hide();
        }
    }

    BluetoothService {
        id: appBluetoothService
        config: appConfig
    }

    BluetoothNotifier {
        config: appConfig
        targetScreen: root.activeScreen
        bluetoothService: appBluetoothService
    }

    BatteryService {
        id: appBatteryService
    }

    WeatherService {
        id: appWeatherService
    }

    IdleService {
        id: appIdleService
        settingsService: appSettingsService
        lockService: appLockService
        targetScreen: root.activeScreen
    }

    PowerService {
        id: appPowerService
        idleService: appIdleService
    }

    PowerMenu {
        id: powerMenu
        config: appConfig
        lockService: appLockService
        powerService: appPowerService
        targetScreen: root.activeScreen
    }

    SettingsMenu {
        id: settingsMenu
        config: appConfig
        wallpaperController: appWallpaperPicker
        idleService: appIdleService
        settingsService: appSettingsService
        targetScreen: root.activeScreen
    }

    Connections {
        target: appIdleService
        function onSettingsRequested(screen) {
            settingsMenu.open(screen, "idle");
        }
    }

    RecorderService {
        id: appRecorderService
        targetScreen: root.activeScreen
    }

    // The recorder menu is gone, but region recording still needs a selector.
    RegionSelector {
        id: appRegionSelector

        config: appConfig
        targetScreen: root.activeScreen
        onAccepted: geometry => appRecorderService.startRegion(geometry)
    }

    Connections {
        target: appRecorderService

        function onRegionSelectionRequested(): void {
            appRegionSelector.open();
        }
    }

    ShellUiService {
        id: shellUiService
        targetScreen: root.activeScreen
    }

    VolumeOsd {
        id: appVolumeOsd
        config: appConfig
        targetScreen: root.activeScreen
    }

    Variants {
        model: Quickshell.screens

        WorkspaceOsd {
            required property var modelData

            config: appConfig
            niri: niriService
            targetScreen: modelData
            barVisible: root.barVisible
        }
    }

    // Niri/keybind control:
    //
    //   qs ipc call bar toggle
    //   qs ipc call bar hide
    //   qs ipc call bar show
    IpcHandler {
        target: "bar"

        function toggle(): void {
            appSettingsService.saveBarVisible(!appSettingsService.barVisible);
        }

        function hide(): void {
            appSettingsService.saveBarVisible(false);
        }

        function show(): void {
            appSettingsService.saveBarVisible(true);
        }

        function isVisible(): bool {
            return appSettingsService.barVisible;
        }
    }

    Variants {
        model: Quickshell.screens

        ZenCard {
            required property var modelData

            targetScreen: modelData
            config: appConfig
            resumeService: appResumeService
            visible: !root.barVisible
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData

            targetScreen: modelData
            config: appConfig
            niri: niriService
            resumeService: appResumeService
            notificationService: appNotificationService
            notificationPopup: appNotificationPopup
            bluetoothService: appBluetoothService
            audioService: appAudioService
            networkService: appNetworkService
            driveService: appDriveService
            privacyService: appPrivacyService
            batteryService: appBatteryService
            weatherService: appWeatherService
            idleService: appIdleService
            settingsService: appSettingsService
            recorderService: appRecorderService
            uiService: shellUiService

            visible: root.barVisible
        }
    }
}
