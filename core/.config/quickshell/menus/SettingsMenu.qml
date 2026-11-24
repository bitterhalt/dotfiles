pragma ComponentBehavior: Bound

import "../components"
import "../services/config/Schema.js" as Schema
import "../services/idle/Duration.js" as Duration
import QtQuick
import Quickshell
import Quickshell.Wayland

// One settings window: category sidebar on the left, page on the right.
// Pages are described by data (`pages`) and drawn by the same delegate. Most apply
// instantly through Config.setValue() / SettingsService. Two pages are saved with
// Apply instead: Idle (custom timeouts, validated together) and Theming (`staged`:
// rows edit a draft, because saving regenerates the Hellwal colors).
Item {
    id: root

    required property var config
    required property var idleService
    required property var settingsService
    required property var wallpaperController
    required property var targetScreen
    property var menuScreen: null
    property bool opened: false
    property int page: 0
    property string errorText: ""
    property string noteText: ""
    // Edited values of a staged page; written by Apply, dropped when the page changes.
    property var draft: ({})
    property bool themingPending: false
    property bool themingAttempted: false
    // Sidebar delegates, kept by index so Up/Down can move focus with the page.
    property var pageRows: []
    readonly property var current: pages[page]
    readonly property bool staged: current.staged === true
    readonly property var pages: [
        {
            id: "idle",
            label: "Idle",
            icon: "󰤄",
            custom: true,
            rows: []
        },
        {
            id: "appearance",
            label: "Appearance",
            icon: "󰏘",
            rows: [
                {
                    kind: "stepper",
                    name: "fontScale",
                    label: "Font scale",
                    step: 0.1,
                    decimals: 1
                },
                {
                    kind: "stepper",
                    name: "iconScale",
                    label: "Icon scale",
                    step: 0.1,
                    decimals: 1
                },
                {
                    kind: "text",
                    name: "iconFontFamily",
                    label: "Icon font",
                    wide: true
                },
                {
                    kind: "toggle",
                    name: "popupAnimations",
                    label: "Animations"
                },
                {
                    kind: "stepper",
                    name: "popupGap",
                    label: "Popup gap",
                    step: 2,
                    suffix: " px"
                },
                {
                    kind: "stepper",
                    name: "popupRadius",
                    label: "Popup radius",
                    suffix: " px"
                }
            ]
        },
        {
            id: "theming",
            label: "Theming",
            icon: "󰃣",
            staged: true,
            hint: "Colors are generated from the current wallpaper",
            rows: [
                {
                    kind: "choice",
                    name: "hellwalMode",
                    label: "Mode",
                    options: [
                        {
                            value: "dark",
                            label: "Dark"
                        },
                        {
                            value: "light",
                            label: "Light"
                        }
                    ]
                },
                {
                    kind: "stepper",
                    name: "hellwalDarkOffset",
                    label: "Dark offset",
                    from: 0,
                    to: 1,
                    step: 0.05,
                    decimals: 2
                },
                {
                    kind: "stepper",
                    name: "hellwalBrightOffset",
                    label: "Bright offset",
                    from: 0,
                    to: 1,
                    step: 0.05,
                    decimals: 2
                },
                {
                    kind: "stepper",
                    name: "hellwalGrayScale",
                    label: "Grayscale",
                    from: 0,
                    to: 1,
                    step: 0.05,
                    decimals: 2
                },
                {
                    kind: "choice",
                    name: "hellwalBackgroundMode",
                    label: "Background",
                    options: [
                        {
                            value: "dynamic",
                            label: "Dynamic"
                        },
                        {
                            value: "fixed",
                            label: "Fixed"
                        }
                    ]
                },
                {
                    kind: "text",
                    name: "hellwalBackgroundColor",
                    label: "Fixed color",
                    when: {
                        name: "hellwalBackgroundMode",
                        value: "fixed"
                    }
                }
            ]
        },
        {
            id: "bar",
            label: "Bar",
            icon: "󰍜",
            rows: [
                {
                    kind: "stepper",
                    name: "barHeight",
                    label: "Height",
                    step: 2,
                    suffix: " px"
                },
                {
                    kind: "toggle",
                    name: "showTray",
                    label: "Show tray"
                },
                {
                    kind: "choice",
                    name: "workspaceLayout",
                    label: "Workspace layout",
                    options: [
                        {
                            value: "dots",
                            label: "Dots"
                        },
                        {
                            value: "minimal",
                            label: "Minimal"
                        }
                    ]
                },
                {
                    kind: "text",
                    name: "clockFormat",
                    label: "Clock format"
                },
                {
                    kind: "text",
                    name: "clockAlternativeFormat",
                    label: "Alternative format"
                }
            ]
        },
        {
            id: "audio",
            label: "Audio",
            icon: "󰕾",
            hint: "Values above 100% amplify the signal",
            rows: [
                {
                    kind: "stepper",
                    name: "maxVolume",
                    label: "Max volume",
                    step: 0.05,
                    factor: 100,
                    suffix: "%"
                }
            ]
        },
        {
            id: "launcher",
            label: "Launcher",
            icon: "󰀻",
            rows: [
                {
                    kind: "toggle",
                    name: "launcherEnabled",
                    label: "Launcher enabled"
                }
            ]
        },
        {
            id: "notifications",
            label: "Notifications",
            icon: "󰂚",
            hint: "Excluded apps are comma separated app names",
            rows: [
                {
                    kind: "integer",
                    name: "notificationHistoryLimit",
                    label: "History limit"
                },
                {
                    kind: "list",
                    name: "notificationHistoryExcludedApps",
                    label: "Excluded apps"
                }
            ]
        },
        {
            id: "bluetooth",
            label: "Bluetooth",
            icon: "󰂯",
            hint: "0 disables a battery notification",
            rows: [
                {
                    kind: "stepper",
                    name: "bluetoothBatteryWarningPercent",
                    label: "Battery warning",
                    step: 5,
                    suffix: "%"
                },
                {
                    kind: "stepper",
                    name: "bluetoothBatteryCriticalPercent",
                    label: "Battery critical",
                    step: 5,
                    suffix: "%"
                },
                {
                    kind: "stepper",
                    name: "bluetoothBatteryRearmMargin",
                    label: "Re-arm margin",
                    step: 5,
                    suffix: "%"
                }
            ]
        }
    ]

    function open(screen, pageId) {
        menuScreen = screen || targetScreen;
        const index = pages.findIndex(entry => entry.id === pageId);
        selectPage(index >= 0 ? index : page, true);
        opened = true;
        Qt.callLater(() => card.forceActiveFocus());
    }

    function close() {
        opened = false;
        themingPending = false;
        themingAttempted = false;
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

    // Staged pages read and write the draft, workspace layout lives in
    // SettingsService, everything else in Config.
    function valueOf(name) {
        if (staged)
            return draft[name];
        return name === "workspaceLayout" ? settingsService.workspaceLayout : config.values[name];
    }

    function save(name, value) {
        if (staged) {
            errorText = "";
            draft = Object.assign({}, draft, {
                [name]: value
            });
            return true;
        }
        errorText = name === "workspaceLayout" ? settingsService.saveWorkspaceLayout(value) : config.setValue(name, value);
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

    function formatText(kind, value) {
        return kind === "list" ? value.join(", ") : String(value);
    }

    function parseText(kind, text) {
        if (kind === "integer")
            return /^\d+$/.test(text.trim()) ? Number(text) : NaN;
        if (kind === "list")
            return text.split(",").map(item => item.trim()).filter(item => item !== "");
        return text;
    }

    function applyIdle() {
        const field = index => idleFields.itemAt(index) ? idleFields.itemAt(index).value : "";
        errorText = settingsService.saveTimeouts(Duration.parse(field(0)), Duration.parse(field(1)), Duration.parse(field(2)));
        noteText = errorText === "" ? "Saved" : "";
    }

    function statusIsError() {
        if (errorText !== "")
            return true;
        if (current.id === "theming" && themingAttempted)
            return wallpaperController.errorText !== "";
        return current.custom === true && idleService.errorText !== "";
    }

    function statusText() {
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
        if (noteText !== "")
            return noteText;
        return current.custom === true ? "30s, 30m, 2h · 0 disables an idle action" : current.hint || "";
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
                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down)
                    return;
                const forward = event.key === Qt.Key_Down;
                if (card.activeFocus)
                    root.selectPage(root.page + (forward ? 1 : -1));
                else
                    root.focusStep(forward);
                event.accepted = true;
            }

            Shortcut {
                sequence: "Escape"
                onActivated: root.close()
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
                height: Math.max(sidebar.implicitHeight, pageTitle.implicitHeight + pageContent.implicitHeight + root.config.panelPadding * 2 + root.config.spacingControl)

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
                        text: root.current.label
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

                        Repeater {
                            model: root.current.rows

                            delegate: SettingRow {
                                id: item

                                required property var modelData
                                readonly property string kind: modelData.kind
                                readonly property bool isText: kind === "text" || kind === "integer" || kind === "list"
                                readonly property var range: Schema.bounds(modelData.name) || [-1e9, 1e9]

                                visible: !modelData.when || root.valueOf(modelData.when.name) === modelData.when.value
                                config: root.config
                                label: modelData.label
                                stacked: kind === "list"
                                controlInset: {
                                    if (kind === "stepper")
                                        return 136;
                                    if (kind === "toggle")
                                        return 32;
                                    if (kind === "choice")
                                        return 176;
                                    return isText && !stacked ? (modelData.wide ? 280 : 160) : 0;
                                }

                                ShellStepper {
                                    visible: item.kind === "stepper"
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    config: root.config
                                    value: Number(root.valueOf(item.modelData.name))
                                    step: item.modelData.step || 1
                                    factor: item.modelData.factor || 1
                                    decimals: item.modelData.decimals || 0
                                    suffix: item.modelData.suffix || ""
                                    from: item.modelData.from !== undefined ? item.modelData.from : item.range[0]
                                    to: item.modelData.to !== undefined ? item.modelData.to : item.range[1]
                                    onMoved: next => root.save(item.modelData.name, next)
                                }

                                ToggleSwitch {
                                    visible: item.kind === "toggle"
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    config: root.config
                                    keyboard: true
                                    checked: !!root.valueOf(item.modelData.name)
                                    onToggled: root.save(item.modelData.name, !checked)
                                }

                                Row {
                                    visible: item.kind === "choice"
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: root.config.spacingControl

                                    Repeater {
                                        model: item.modelData.options || []

                                        delegate: ShellButton {
                                            required property var modelData

                                            config: root.config
                                            outlined: true
                                            width: 84
                                            selected: root.valueOf(item.modelData.name) === modelData.value
                                            text: modelData.label
                                            onClicked: root.save(item.modelData.name, modelData.value)
                                        }
                                    }
                                }

                                // Short fields sit right of the label; lists get a wide wrapped box.
                                ShellTextField {
                                    id: field

                                    visible: item.isText
                                    x: item.stacked ? 0 : parent.width - width
                                    y: item.stacked ? item.stackedOffset : (parent.height - height) / 2
                                    width: item.stacked ? parent.width : item.modelData.wide ? 280 : 160
                                    height: item.stacked ? item.stackedHeight : 28
                                    config: root.config
                                    wrapMode: item.stacked ? TextInput.Wrap : TextInput.NoWrap
                                    verticalAlignment: item.stacked ? TextInput.AlignTop : TextInput.AlignVCenter
                                    font.pointSize: root.config.textSizeMedium
                                    text: root.formatText(item.kind, root.valueOf(item.modelData.name))
                                    // Saved on Enter or blur; the stored value is shown again afterwards,
                                    // which also restores it after a rejected entry.
                                    onEditingFinished: {
                                        root.save(item.modelData.name, root.parseText(item.kind, text));
                                        text = Qt.binding(() => root.formatText(item.kind, root.valueOf(item.modelData.name)));
                                    }
                                }
                            }
                        }

                        // Idle page: timeouts are validated together and saved with Apply.
                        SettingRow {
                            visible: root.current.custom === true
                            config: root.config
                            label: root.idleService.disabled ? "Idle paused" : "Idle active"
                            muted: true
                            controlInset: 72

                            ShellButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                config: root.config
                                outlined: true
                                text: root.idleService.disabled ? "Enable" : "Pause"
                                onClicked: root.idleService.toggle(root.menuScreen)
                            }
                        }

                        Repeater {
                            id: idleFields

                            model: root.current.custom === true ? [
                                {
                                    label: "Lock",
                                    key: "lockTimeout"
                                },
                                {
                                    label: "Monitors off",
                                    key: "offTimeout"
                                },
                                {
                                    label: "Suspend",
                                    key: "suspendTimeout"
                                }
                            ] : []

                            delegate: SettingRow {
                                id: idleRow

                                required property var modelData
                                property alias value: idleInput.text

                                config: root.config
                                label: modelData.label
                                controlInset: 104

                                ShellTextField {
                                    id: idleInput

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 104
                                    implicitHeight: 28
                                    config: root.config
                                    font.pointSize: root.config.textSizeMedium
                                    Component.onCompleted: text = Duration.format(root.settingsService[idleRow.modelData.key])
                                    onAccepted: root.applyIdle()
                                }
                            }
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

            // Footer like the clipboard and wallpaper menus: status or hint on the
            // left, keys on the right, under an inset separator.
            Item {
                id: footer

                width: parent.width
                height: footerKeys.implicitHeight + root.config.panelPadding * 2

                PanelSeparator {
                    config: root.config
                    horizontalInset: root.config.panelPadding
                    anchors.top: parent.top
                }

                Text {
                    renderType: Text.NativeRendering
                    anchors.left: parent.left
                    anchors.leftMargin: root.config.panelPadding
                    anchors.right: footerKeys.left
                    anchors.rightMargin: root.config.spacingControl
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    color: root.statusIsError() ? root.config.urgent : root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: root.statusText()
                }

                Text {
                    id: footerKeys

                    renderType: Text.NativeRendering
                    anchors.right: parent.right
                    anchors.rightMargin: root.config.panelPadding
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: "Tab focus · ↑↓ move · Ctrl+J/K page · Esc close"
                }
            }
        }
    }

    PopupCatcher {
        targetScreen: menuWindow.screen
        visible: menuWindow.visible
        onDismissed: root.close()
    }
}
