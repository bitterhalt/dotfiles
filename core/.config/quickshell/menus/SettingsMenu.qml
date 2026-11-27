pragma ComponentBehavior: Bound

import "../components"
import "SettingsPages.js" as SettingsPages
import "settings"
import QtQuick
import Quickshell
import Quickshell.Wayland

// One settings window: category sidebar on the left, page on the right.
// Pages are described by data (`pages`) and drawn by the same delegate. Most apply
// instantly through Settings.setValue() / SettingsService. Two pages are saved with
// Apply instead: Idle (custom timeouts, validated together) and Theming (`staged`:
// rows edit a draft, because saving regenerates the Hellwal colors).
Item {
    id: root

    required property var config
    required property var idleService
    required property var powerService
    required property var settingsService
    required property var wallpaperController
    required property var targetScreen
    property var menuScreen: null
    property bool opened: false
    property int page: 0
    property string errorText: ""
    property string noteText: ""
    property bool helpOpen: false
    // Destructive footer action awaiting Yes/No ("exit", "reboot", or "shutdown").
    property string pendingPower: ""
    readonly property var powerActions: [
        {
            id: "exit",
            label: "[E]xit"
        },
        {
            id: "sleep",
            label: "[Z]zz"
        },
        {
            id: "reboot",
            label: "[R]eboot"
        },
        {
            id: "shutdown",
            label: "[S]hutdown"
        }
    ]

    // Edited values of a staged page; written by Apply, dropped when the page changes.
    property var draft: ({})
    property bool themingPending: false
    property bool themingAttempted: false
    // Sidebar delegates, kept by index so Up/Down can move focus with the page.
    property var pageRows: []
    readonly property var current: pages[page]
    readonly property bool staged: current.staged === true
    readonly property var pages: SettingsPages.pages

    function open(screen, pageId) {
        menuScreen = screen || targetScreen;
        helpOpen = false;
        pendingPower = "";
        const index = pages.findIndex(entry => entry.id === pageId);
        selectPage(index >= 0 ? index : page, true);
        opened = true;
        Qt.callLater(() => card.forceActiveFocus());
    }

    function close() {
        opened = false;
        helpOpen = false;
        pendingPower = "";
        themingPending = false;
        themingAttempted = false;
    }

    function toggleHelp() {
        pendingPower = "";
        helpOpen = !helpOpen;
        if (helpOpen)
            card.forceActiveFocus();
        else if (pageRows[page])
            pageRows[page].forceActiveFocus(Qt.TabFocusReason);
    }

    // Destructive actions wait for [Y]es / [N]o; sleep runs immediately.
    function requestPower(action) {
        if (action === "sleep") {
            close();
            powerService.suspend();
            return;
        }
        pendingPower = action;
        card.forceActiveFocus();
    }

    function confirmPower() {
        const action = pendingPower;
        pendingPower = "";
        if (action === "")
            return;
        close();
        if (action === "exit")
            powerService.exitSession();
        else if (action === "reboot")
            powerService.reboot();
        else if (action === "shutdown")
            powerService.shutdown();
    }

    function cancelPower() {
        pendingPower = "";
        card.forceActiveFocus();
    }

    function toggle(screen) {
        opened ? close() : open(screen);
    }

    function handleAction(action) {
        if (action === "open")
            open(targetScreen);
        else if (action === "close")
            close();
        else
            toggle(targetScreen);
    }

    function selectPage(index, resetDraft) {
        const next = (index + pages.length) % pages.length;
        const leavingTheming = pages[page].id === "theming" && next !== page;
        helpOpen = false;
        pendingPower = "";
        errorText = "";
        noteText = "";
        if (leavingTheming) {
            themingPending = false;
            themingAttempted = false;
        }
        if (pages[next].staged && (next !== page || resetDraft === true))
            beginDraft();
        page = next;
    }

    function beginDraft() {
        themingPending = false;
        themingAttempted = false;
        draft = {
            hellwalMode: settingsService.hellwalMode,
            hellwalDarkOffset: settingsService.hellwalDarkOffset,
            hellwalBrightOffset: settingsService.hellwalBrightOffset,
            hellwalGrayScale: settingsService.hellwalGrayScale,
            hellwalBackgroundMode: settingsService.hellwalBackgroundMode,
            hellwalBackgroundColor: settingsService.hellwalBackgroundColor
        };
    }

    // Up/Down in the sidebar moves the page and keyboard focus together.
    function focusPage(index) {
        const target = Math.max(0, Math.min(pages.length - 1, index));
        selectPage(target);
        if (pageRows[target])
            pageRows[target].forceActiveFocus(Qt.TabFocusReason);
    }

    // Staged pages read and write the draft, workspace layout and bar
    // visibility live in SettingsService, everything else in Settings.
    function valueOf(name) {
        if (staged)
            return draft[name];
        if (name === "workspaceLayout")
            return settingsService.workspaceLayout;
        if (name === "barVisible")
            return settingsService.barVisible;
        return config.values[name];
    }

    function save(name, value) {
        if (staged) {
            errorText = "";
            draft = Object.assign({}, draft, {
                [name]: value
            });
            return true;
        }
        if (name === "workspaceLayout")
            errorText = settingsService.saveWorkspaceLayout(value);
        else if (name === "barVisible")
            errorText = settingsService.saveBarVisible(value);
        else
            errorText = config.setValue(name, value);
        return errorText === "";
    }

    // Apply button and Ctrl+Enter.
    function apply() {
        if (current.id === "idle")
            applyIdle();
        else if (current.id === "theming")
            applyTheming();
    }

    function applyTheming() {
        if (wallpaperController.busy)
            return;
        themingAttempted = false;
        errorText = settingsService.saveHellwalSettings(draft.hellwalMode, Number(draft.hellwalDarkOffset), Number(draft.hellwalBrightOffset), draft.hellwalBackgroundMode, draft.hellwalBackgroundColor, Number(draft.hellwalGrayScale));
        noteText = "";
        themingPending = errorText === "";
        if (themingPending) {
            themingAttempted = true;
            wallpaperController.refreshHellwal();
        }
    }

    function applyIdle() {
        errorText = idlePage.apply();
        noteText = idlePage.noteText;
    }

    function statusIsError() {
        if (errorText !== "")
            return true;
        if (current.id === "theming" && themingAttempted)
            return wallpaperController.errorText !== "";
        return current.custom === true && idleService.errorText !== "";
    }

    // Only real status replaces the footer buttons; page hints are gone.
    function footerStatusText() {
        if (errorText !== "")
            return errorText;
        if (current.id === "theming" && themingAttempted) {
            if (wallpaperController.busy)
                return "Generating colors…";
            if (wallpaperController.errorText !== "")
                return wallpaperController.errorText;
        }
        if (current.custom === true && idleService.errorText !== "")
            return idleService.errorText;
        return noteText;
    }

    // Tab order and Up/Down follow the same focus chain.
    function focusStep(forward) {
        const item = card.Window.activeFocusItem;
        const next = item ? item.nextItemInFocusChain(forward) : null;
        if (next)
            next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    // Report the end of a Theming apply once the Hellwal run has finished.
    Connections {
        target: root.wallpaperController

        function onBusyChanged() {
            if (root.wallpaperController.busy || !root.themingPending || root.current.id !== "theming")
                return;
            root.themingPending = false;
            root.noteText = root.wallpaperController.errorText === "" ? "Colors updated" : "";
        }
    }

    PopupIpcHandler {
        target: "settings"
        handleAction: action => root.handleAction(action)
    }

    PanelWindow {
        id: menuWindow

        screen: root.menuScreen || root.targetScreen
        visible: popupMotion.surfaceVisible
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        anchors.top: true
        anchors.left: true
        margins.top: root.config.popupGap
        margins.left: screen ? Math.max(0, Math.round((screen.width - width) / 2)) : 0
        color: "transparent"
        exclusiveZone: 0
        focusable: root.opened
        WlrLayershell.namespace: "slim-barpopup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        PopupMotion {
            id: popupMotion

            duration: 150
            surfaceHeight: menuWindow.height
            shown: root.opened
            animationsEnabled: root.config.popupAnimations
            animationType: "fade"
        }

        PopoutPanel {
            id: card

            enabled: root.opened
            opacity: popupMotion.contentOpacity
            transform: Translate {
                y: popupMotion.contentOffset
            }
            config: root.config
            contentWidth: 600
            padding: 0
            spacing: 0
            focus: true

            // Up/Down walk the page list from the sidebar, or the page controls
            // once one has focus (same order as Tab).
            Keys.onPressed: event => {
                const key = event.text.toLowerCase();
                if (root.pendingPower !== "") {
                    if (key === "y") {
                        root.confirmPower();
                        event.accepted = true;
                    } else if (key === "n") {
                        root.cancelPower();
                        event.accepted = true;
                    }
                    return;
                }
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    const forward = event.key === Qt.Key_Down;
                    if (card.activeFocus)
                        root.selectPage(root.page + (forward ? 1 : -1));
                    else
                        root.focusStep(forward);
                    event.accepted = true;
                    return;
                }
                if (root.helpOpen)
                    return;
                const action = key === "e" ? "exit" : key === "z" ? "sleep" : key === "r" ? "reboot" : key === "s" ? "shutdown" : "";
                if (action !== "") {
                    root.requestPower(action);
                    event.accepted = true;
                }
            }

            Shortcut {
                sequence: "Escape"
                onActivated: {
                    if (root.pendingPower !== "")
                        root.cancelPower();
                    else if (root.helpOpen)
                        root.toggleHelp();
                    else
                        root.close();
                }
            }

            Shortcut {
                sequence: "?"
                enabled: root.opened
                onActivated: root.toggleHelp()
            }

            Shortcut {
                sequences: ["Ctrl+Return", "Ctrl+Enter"]
                enabled: root.opened && (root.staged || root.current.custom === true) && !(root.staged && root.wallpaperController.busy)
                onActivated: root.apply()
            }

            // Page switching that also works while a text field has focus.
            Shortcut {
                sequences: ["Ctrl+J", "Ctrl+Down"]
                onActivated: root.selectPage(root.page + 1)
            }

            Shortcut {
                sequences: ["Ctrl+K", "Ctrl+Up"]
                onActivated: root.selectPage(root.page - 1)
            }

            Row {
                id: body

                width: parent.width
                height: Math.max(sidebar.implicitHeight, root.helpOpen ? helpPanel.implicitHeight + root.config.panelPadding * 2 : pageTitle.implicitHeight + pageContent.implicitHeight + root.config.panelPadding * 2 + root.config.spacingControl)

                Column {
                    id: sidebar

                    width: 168
                    height: parent.height
                    padding: root.config.panelPadding
                    spacing: root.config.spacingTight

                    Repeater {
                        model: root.pages

                        delegate: Item {
                            id: category

                            required property var modelData
                            required property int index

                            width: sidebar.width - sidebar.padding * 2
                            height: 32
                            activeFocusOnTab: true

                            Keys.onUpPressed: root.focusPage(category.index - 1)
                            Keys.onDownPressed: root.focusPage(category.index + 1)
                            Keys.onReturnPressed: root.selectPage(category.index)
                            Keys.onSpacePressed: root.selectPage(category.index)
                            Component.onCompleted: root.pageRows[category.index] = category
                            Component.onDestruction: root.pageRows[category.index] = null

                            MenuRow {
                                anchors.fill: parent
                                config: root.config
                                selected: root.page === category.index || categoryMouse.containsMouse
                                icon: category.modelData.icon
                                label: category.modelData.label
                            }

                            MouseArea {
                                id: categoryMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectPage(category.index);
                                    category.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Vertical rule, inset like the footer separator.
                PanelSeparator {
                    config: root.config
                    vertical: true
                    verticalInset: root.config.panelPadding
                }

                Item {
                    id: pageArea

                    width: parent.width - sidebar.width - 1
                    height: parent.height

                    Text {
                        id: pageTitle

                        renderType: Text.NativeRendering
                        anchors.top: parent.top
                        anchors.topMargin: root.config.panelPadding
                        anchors.left: parent.left
                        anchors.leftMargin: root.config.panelPadding
                        color: root.config.fg
                        font.pointSize: root.config.textSizeNormal
                        font.weight: Font.DemiBold
                        visible: !root.helpOpen
                        text: root.current.label
                    }

                    // Settings shortcuts, shown in place of the page like the bar popups.
                    KeyboardHelp {
                        id: helpPanel

                        anchors.top: parent.top
                        anchors.topMargin: root.config.panelPadding
                        anchors.left: parent.left
                        anchors.leftMargin: root.config.panelPadding
                        anchors.right: parent.right
                        anchors.rightMargin: root.config.panelPadding
                        visible: root.helpOpen
                        config: root.config
                        entries: [
                            {
                                name: "Next / previous page",
                                key: "Ctrl+J / Ctrl+K"
                            },
                            {
                                name: "Next / previous control",
                                key: "Tab / Shift+Tab"
                            },
                            {
                                name: "Move within page",
                                key: "↑ / ↓"
                            },
                            {
                                name: "Change value",
                                key: "← / → · Enter"
                            },
                            {
                                name: "Apply changes",
                                key: "Ctrl+Enter"
                            },
                            {
                                name: "Power actions",
                                key: "E / Z / R / S"
                            },
                            {
                                name: "Confirm / cancel power action",
                                key: "Y / N"
                            },
                            {
                                name: "Show / hide help",
                                key: "?"
                            },
                            {
                                name: "Back / close",
                                key: "Esc"
                            }
                        ]
                    }

                    Column {
                        id: pageContent

                        anchors.top: pageTitle.bottom
                        anchors.topMargin: root.config.spacingControl
                        anchors.left: parent.left
                        anchors.leftMargin: root.config.panelPadding
                        anchors.right: parent.right
                        anchors.rightMargin: root.config.panelPadding
                        spacing: root.config.spacingTight
                        visible: !root.helpOpen

                        Repeater {
                            model: root.current.rows

                            delegate: SettingControl {
                                config: root.config
                                value: root.valueOf(modelData.name)
                                visible: !modelData.when || root.valueOf(modelData.when.name) === modelData.when.value
                                onSaveRequested: (name, next) => root.save(name, next)
                            }
                        }

                        IdleSettingsPage {
                            id: idlePage

                            config: root.config
                            idleService: root.idleService
                            settingsService: root.settingsService
                            menuScreen: root.menuScreen
                            active: root.current.custom === true
                            onApplyRequested: root.applyIdle()
                        }

                        SettingRow {
                            visible: root.current.custom === true || root.staged
                            config: root.config
                            controlInset: 64

                            ShellButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                config: root.config
                                outlined: true
                                enabled: !(root.staged && root.wallpaperController.busy)
                                text: "Apply"
                                onClicked: root.apply()
                            }
                        }
                    }
                }
            }

            SettingsFooter {
                config: root.config
                powerActions: root.powerActions
                pendingPower: root.pendingPower
                statusText: root.footerStatusText()
                statusIsError: root.statusIsError()
                helpOpen: root.helpOpen
                onPowerRequested: action => root.requestPower(action)
                onConfirmRequested: root.confirmPower()
                onCancelRequested: root.cancelPower()
                onHelpToggled: root.toggleHelp()
            }
        }
    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: menuWindow.visible
        onDismissed: root.close()
    }
}
