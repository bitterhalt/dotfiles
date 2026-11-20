import "../components"
import "Languages.js" as Languages
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var popupMotion
    property string sourceLanguage: ""
    property string targetLanguage: "EN-GB"
    property string translation: ""
    property string detectedLanguage: ""
    property string errorText: ""
    property string noticeText: ""
    property string pendingRequest: ""
    property string pendingCopy: ""
    property bool replyReceived: false
    property bool copied: false
    property string picker: ""
    property int pickerIndex: 0
    readonly property int inputLimit: 10000
    readonly property bool busy: translateProcess.running
    readonly property var languageRows: {
        if (picker === "")
            return [];

        const needle = languageSearch.text.trim().toLowerCase();
        const choices = picker === "source" ? Languages.sources() : Languages.targets();
        return choices.filter(language => {
            return language.label.toLowerCase().includes(needle) || language.code.toLowerCase().includes(needle);
        });
    }

    signal closeRequested

    Binding {
        target: root.popupMotion
        property: "surfaceHeight"
        value: root.height
    }

    function focusInput(): void {
        if (!root.visible || !root.popupMotion.shown)
            return;
        if (picker !== "")
            languageSearch.forceActiveFocus();
        else
            sourceInput.forceActiveFocus();
    }

    function clearResult() {
        translation = "";
        detectedLanguage = "";
        errorText = "";
        noticeText = "";
        copied = false;
    }

    function translate() {
        if (busy || picker !== "" || sourceInput.text.trim() === "")
            return;

        clearResult();
        pendingRequest = JSON.stringify({
            "text": sourceInput.text,
            "source": sourceLanguage,
            "target": targetLanguage
        });
        replyReceived = false;
        translateProcess.stdinEnabled = true;
        translateProcess.running = true;
    }

    function copyResult() {
        if (translation === "" || copyProcess.running)
            return;

        pendingCopy = translation;
        copyProcess.stdinEnabled = true;
        copyProcess.running = true;
    }

    function openPicker(which) {
        if (busy)
            return;

        languageSearch.text = "";
        pickerIndex = 0;
        picker = which;
        Qt.callLater(() => {
            return languageSearch.forceActiveFocus();
        });
    }

    function closePicker() {
        picker = "";
        Qt.callLater(() => {
            return sourceInput.forceActiveFocus();
        });
    }

    function moveLanguage(direction) {
        if (languageRows.length === 0)
            return;

        pickerIndex = (pickerIndex + direction + languageRows.length) % languageRows.length;
        languageList.positionViewAtIndex(pickerIndex, ListView.Contain);
    }

    function chooseLanguage(index) {
        if (index < 0 || index >= languageRows.length)
            return;

        const code = languageRows[index].code;
        if (picker === "source")
            sourceLanguage = code;
        else
            targetLanguage = code;
        clearResult();
        closePicker();
    }

    function swapLanguages() {
        const source = sourceLanguage || detectedLanguage;
        if (busy || source === "")
            return;

        const previousTarget = targetLanguage.split("-")[0];
        const previousText = sourceInput.text;
        const hadTranslation = translation !== "";
        const nextText = translation || previousText;
        sourceLanguage = previousTarget;
        targetLanguage = Languages.targetFor(source);
        sourceInput.text = nextText;
        clearResult();
        if (hadTranslation)
            translation = previousText;

        sourceInput.forceActiveFocus();
    }

    screen: targetScreen
    visible: root.popupMotion.surfaceVisible
    color: "transparent"
    implicitWidth: 520
    implicitHeight: 410
    exclusiveZone: 0
    focusable: root.popupMotion.shown
    anchors.top: true
    anchors.left: true
    margins.top: config.popupGap
    margins.left: targetScreen ? Math.max(0, Math.round((targetScreen.width - width) / 2)) : 0
    WlrLayershell.namespace: "slim-translator"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.popupMotion.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Component.onCompleted: Qt.callLater(root.focusInput)
    Component.onDestruction: {
        if (translateProcess.running)
            translateProcess.signal(15);

        if (copyProcess.running)
            copyProcess.signal(15);
    }

    Process {
        id: translateProcess

        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/translator/deepl.py"]
        onStarted: {
            write(root.pendingRequest + "\n");
            stdinEnabled = false;
            root.pendingRequest = "";
        }
        onExited: exitCode => {
            root.pendingRequest = "";
            if (exitCode !== 0 && !root.replyReceived)
                root.errorText = "Could not run the DeepL helper";
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.replyReceived = true;
                try {
                    const reply = JSON.parse(text);
                    if (reply.ok && typeof reply.text === "string") {
                        root.translation = reply.text;
                        root.detectedLanguage = reply.detected || "";
                        if (reply.text.trim() === sourceInput.text.trim())
                            root.noticeText = root.detectedLanguage === root.targetLanguage.split("-")[0] ? "Already " + Languages.label(root.detectedLanguage) + "; change target language" : "DeepL returned unchanged text";
                    } else {
                        root.errorText = reply.error || "Translation failed";
                    }
                } catch (error) {
                    root.errorText = "Could not read the translation response";
                }
            }
        }
        // Unexpected Python errors must not leak request data into shell logs.

        stderr: StdioCollector {}
    }

    Process {
        id: copyProcess

        command: ["wl-copy"]
        environment: ({
                "DEEPL_API": null
            })
        onStarted: {
            write(root.pendingCopy);
            stdinEnabled = false;
            root.pendingCopy = "";
        }
        onExited: exitCode => {
            root.copied = exitCode === 0;
            if (exitCode !== 0)
                root.errorText = "Could not copy the translation";
        }
    }

    PopupCatcher {
        targetScreen: root.targetScreen
        visible: root.visible
        onDismissed: root.closeRequested()
    }

    Connections {
        target: root.popupMotion
        function onShownChanged(): void {
            if (root.popupMotion.shown)
                Qt.callLater(root.focusInput);
        }
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config
        enabled: root.popupMotion.shown
        opacity: root.popupMotion.contentOpacity
        transform: Translate {
            y: root.popupMotion.contentOffset
        }
        clip: true

        // Initial completion can precede compositor keyboard activation.
        Window.onActiveChanged: {
            if (Window.active)
                Qt.callLater(root.focusInput);
        }

        Shortcut {
            sequence: "Ctrl+Return"
            onActivated: root.translate()
        }

        Shortcut {
            sequence: "Ctrl+Enter"
            onActivated: root.translate()
        }

        Shortcut {
            sequence: "Ctrl+Shift+C"
            onActivated: root.copyResult()
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.picker !== "" ? root.closePicker() : root.closeRequested()
        }

        // Source/target language controls and swap action.
        Row {
            id: header
            objectName: "translatorHeader"

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.config.panelPadding
            spacing: root.config.spacingControl

            ShellButton {
                id: sourceButton

                config: root.config
                tinted: true
                width: (parent.width - swapButton.width - parent.spacing * 2) / 2
                text: "From: " + Languages.label(root.sourceLanguage) + " ▾"
                enabled: !root.busy
                onClicked: root.openPicker("source")
                KeyNavigation.tab: swapButton.enabled ? swapButton : targetButton
                KeyNavigation.backtab: copyButton.enabled ? copyButton : translateButton
            }

            ShellButton {
                id: swapButton

                config: root.config
                iconOnly: true
                text: "⇄"
                ShellToolTip {
                    config: root.config
                    anchorItem: swapButton
                    shown: swapButton.hovered && swapButton.enabled
                    text: "Swap languages and input/output"
                }
                enabled: !root.busy && root.picker === "" && (root.sourceLanguage !== "" || root.detectedLanguage !== "")
                onClicked: root.swapLanguages()
                KeyNavigation.tab: targetButton
                KeyNavigation.backtab: sourceButton
            }

            ShellButton {
                id: targetButton

                config: root.config
                tinted: true
                width: sourceButton.width
                text: "To: " + Languages.label(root.targetLanguage) + " ▾"
                enabled: !root.busy
                onClicked: root.openPicker("target")
                KeyNavigation.tab: sourceInput
                KeyNavigation.backtab: swapButton.enabled ? swapButton : sourceButton
            }
        }

        Item {
            id: body
            objectName: "translatorBody"

            anchors.top: header.bottom
            anchors.topMargin: root.config.panelPadding
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.config.panelPadding
            anchors.rightMargin: root.config.panelPadding
            anchors.bottomMargin: root.config.spacingControl

            // Input text and translated result panes.
            Column {
                anchors.fill: parent
                visible: root.picker === ""
                spacing: root.config.spacingControl

                ScrollView {
                    id: sourceScroll
                    objectName: "translatorSourceScroll"

                    width: parent.width
                    height: Math.floor((parent.height - parent.spacing) / 2)
                    contentWidth: availableWidth
                    clip: true

                    background: Rectangle {
                        objectName: "translatorSourceCard"
                        radius: 5
                        color: Qt.alpha(root.config.selectionBackground, 0.05)
                        border.color: root.config.border
                        border.width: 1
                    }

                    TextArea {
                        id: sourceInput
                        objectName: "translatorSourceInput"

                        renderType: Text.NativeRendering
                        placeholderText: "Type or paste text…"
                        placeholderTextColor: root.config.muted
                        color: root.config.fg
                        selectionColor: root.config.selectionBackground
                        selectedTextColor: root.config.selectionForeground
                        font.pointSize: root.config.textSizeNormal
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        selectByMouse: true
                        readOnly: root.busy
                        leftPadding: root.config.panelPadding
                        rightPadding: root.config.panelPadding
                        topPadding: root.config.panelPadding
                        bottomPadding: root.config.panelPadding
                        background: null
                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: outputArea
                        KeyNavigation.backtab: targetButton
                        onTextChanged: {
                            root.clearResult();
                            if (length > root.inputLimit) {
                                let end = root.inputLimit;
                                const last = text.charCodeAt(end - 1);
                                if (last >= 55296 && last <= 56319)
                                    --end;

                                remove(end, length);
                                root.errorText = "Input is limited to 10,000 characters";
                            }
                        }
                    }
                }

                ScrollView {
                    objectName: "translatorOutputScroll"
                    width: parent.width
                    height: sourceScroll.height
                    contentWidth: availableWidth
                    clip: true

                    background: Rectangle {
                        objectName: "translatorOutputCard"
                        radius: 5
                        color: Qt.alpha(root.config.selectionBackground, 0.05)
                        border.color: root.config.border
                        border.width: 1
                    }

                    TextArea {
                        id: outputArea

                        renderType: Text.NativeRendering
                        text: root.translation
                        placeholderText: root.busy ? "Translating…" : "Translation"
                        placeholderTextColor: root.config.muted
                        color: root.config.fg
                        selectionColor: root.config.selectionBackground
                        selectedTextColor: root.config.selectionForeground
                        font.pointSize: root.config.textSizeNormal
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        selectByMouse: true
                        readOnly: true
                        activeFocusOnTab: true
                        leftPadding: root.config.panelPadding
                        rightPadding: root.config.panelPadding
                        topPadding: root.config.panelPadding
                        bottomPadding: root.config.panelPadding
                        background: null
                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: translateButton.enabled ? translateButton : copyButton
                        KeyNavigation.backtab: sourceInput
                    }
                }
            }

            Column {
                anchors.fill: parent
                visible: root.picker !== ""
                spacing: root.config.spacingControl

                TextField {
                    id: languageSearch
                    objectName: "translatorLanguageSearch"

                    renderType: Text.NativeRendering
                    width: parent.width
                    height: 34
                    placeholderText: "Search languages…"
                    color: root.config.fg
                    placeholderTextColor: root.config.muted
                    selectionColor: root.config.selectionBackground
                    selectedTextColor: root.config.selectionForeground
                    font.pointSize: root.config.textSizeNormal
                    onTextChanged: root.pickerIndex = 0
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Down:
                        case Qt.Key_Tab:
                            root.moveLanguage(1);
                            event.accepted = true;
                            break;
                        case Qt.Key_Up:
                        case Qt.Key_Backtab:
                            root.moveLanguage(-1);
                            event.accepted = true;
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.chooseLanguage(root.pickerIndex);
                            event.accepted = true;
                            break;
                        }
                    }

                    background: Rectangle {
                        color: root.config.bg
                        radius: 4
                        border.width: 1
                        border.color: root.config.selectionBackground
                    }
                }

                ListView {
                    id: languageList

                    width: parent.width
                    height: parent.height - languageSearch.height - parent.spacing
                    model: root.languageRows
                    currentIndex: root.pickerIndex
                    clip: true

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 32
                        radius: 4
                        color: index === root.pickerIndex ? root.config.selectionBackground : "transparent"

                        Text {
                            renderType: Text.NativeRendering
                            anchors.fill: parent
                            anchors.leftMargin: root.config.spacingControl
                            anchors.rightMargin: root.config.spacingControl
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: root.config.textSizeMedium
                            color: index === root.pickerIndex ? root.config.selectionForeground : root.config.fg
                            text: modelData.label
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.pickerIndex = parent.index
                            onClicked: root.chooseLanguage(parent.index)
                        }
                    }
                }
            }
        }

        // Translate/copy buttons and current status.
        Item {
            id: footer
            objectName: "translatorFooter"

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            height: Math.max(footerActions.implicitHeight, footerStatus.implicitHeight) + root.config.panelPadding * 2

            PanelSeparator {
                objectName: "translatorFooterSeparator"
                config: root.config
                horizontalInset: root.config.panelPadding
            }

            Text {
                id: footerStatus
                renderType: Text.NativeRendering
                anchors.left: parent.left
                anchors.leftMargin: root.config.panelPadding
                anchors.right: footerActions.left
                anchors.rightMargin: root.config.spacingControl
                anchors.verticalCenter: parent.verticalCenter
                color: root.errorText ? root.config.urgent : root.config.muted
                font.pointSize: root.config.textSizeSmall
                elide: Text.ElideRight
                text: root.errorText || root.noticeText || (root.picker !== "" ? "Tab Select · Enter Apply" : root.detectedLanguage !== "" && root.sourceLanguage === "" ? "Detected: " + Languages.label(root.detectedLanguage) : "DeepL · Ctrl+Enter Translate")
            }

            Row {
                id: footerActions

                anchors.right: parent.right
                anchors.rightMargin: root.config.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.config.spacingControl

                ShellButton {
                    id: translateButton

                    config: root.config
                    text: root.busy ? "Translating…" : "Translate"
                    enabled: !root.busy && root.picker === "" && sourceInput.text.trim() !== ""
                    onClicked: root.translate()
                    KeyNavigation.tab: copyButton.enabled ? copyButton : sourceButton
                    KeyNavigation.backtab: outputArea
                }

                ShellButton {
                    id: copyButton

                    config: root.config
                    text: root.copied ? "Copied" : "Copy"
                    enabled: root.translation !== "" && root.picker === ""
                    onClicked: root.copyResult()
                    KeyNavigation.tab: sourceButton
                    KeyNavigation.backtab: translateButton.enabled ? translateButton : outputArea
                }
            }
        }
    }
}
