import QtQuick
import "../../../components"

Column {
    id: root

    required property var config
    required property string ssid
    property string errorText: ""
    property alias text: passwordInput.text

    signal submitted(string password)
    signal cancelled

    function focusInput(): void {
        passwordInput.forceActiveFocus();
    }

    spacing: 8

    Text {
        renderType: Text.NativeRendering
        width: parent.width
        color: root.config.fg
        font.pointSize: root.config.textSizeNormal
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        text: root.ssid
    }

    Text {
        renderType: Text.NativeRendering
        color: root.config.muted
        font.pointSize: root.config.textSizeSmall
        text: "Enter network password"
    }

    ShellTextField {
        id: passwordInput
        objectName: "networkPasswordInput"
        config: root.config
        surfaceColor: root.config.bg
        outlineColor: root.config.selectionBackground
        cornerRadius: root.config.popupRadius
        KeyNavigation.tab: cancelPassword
        KeyNavigation.backtab: connectButton
        width: parent.width
        height: 32
        focus: root.visible
        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => forceActiveFocus());
        }
        echoMode: TextInput.Password
        passwordCharacter: "•"
        placeholderText: "Password"
        font.pointSize: root.config.textSizeNormal
        Keys.onReturnPressed: if (connectButton.enabled)
            root.submitted(text)
        Keys.onEnterPressed: if (connectButton.enabled)
            root.submitted(text)
    }

    Text {
        renderType: Text.NativeRendering
        width: parent.width
        visible: root.errorText !== ""
        color: root.config.urgent
        font.pointSize: root.config.textSizeSmall
        text: root.errorText
    }

    Row {
        width: parent.width
        spacing: 6

        ShellButton {
            id: cancelPassword
            objectName: "networkCancelPassword"
            config: root.config
            outlined: true
            cornerRadius: 3
            KeyNavigation.tab: connectButton
            KeyNavigation.backtab: passwordInput
            width: (parent.width - 6) / 2
            text: "Cancel"
            onClicked: root.cancelled()
        }

        ShellButton {
            id: connectButton
            objectName: "networkSubmitPassword"
            config: root.config
            filled: true
            outlined: true
            cornerRadius: 3
            KeyNavigation.tab: passwordInput
            KeyNavigation.backtab: cancelPassword
            width: (parent.width - 6) / 2
            text: "Connect"
            enabled: root.ssid !== "" && passwordInput.text.length > 0
            onClicked: root.submitted(passwordInput.text)
        }
    }
}
