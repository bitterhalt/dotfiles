import QtQuick
import QtQuick.Controls.Basic
import "../components"

// Authentication integration stays in PolkitService; this view emits user intent.
PanelSurface {
    id: root

    required property var flow
    property alias response: responseField.text

    signal submitted
    signal cancelled
    signal identitySelected(int index)

    function clearResponse(): void {
        responseField.text = "";
    }

    function focusPrompt(): void {
        if (flow && flow.isResponseRequired)
            responseField.forceActiveFocus();
        else
            cancelButton.forceActiveFocus();
    }

    border.color: config.selectionBackground
    border.width: 2
    implicitHeight: content.implicitHeight + 32

    Window.onActiveChanged: {
        if (Window.active)
            root.focusPrompt();
    }

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            color: root.config.fg
            font.pointSize: root.config.textSizeNormal
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            text: root.flow ? root.flow.message : "Authentication required"
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !!root.flow && root.flow.actionId !== ""
            color: root.config.muted
            font.pointSize: root.config.textSizeSmall
            wrapMode: Text.WordWrap
            text: root.flow ? root.flow.actionId : ""
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !!root.flow && root.flow.identities.length > 1
            color: root.config.fg
            font.pointSize: root.config.textSizeMedium
            text: "Authenticate as"
        }

        ComboBox {
            objectName: "polkitIdentityPicker"
            width: parent.width
            visible: !!root.flow && root.flow.identities.length > 1
            model: root.flow ? root.flow.identities : []
            textRole: "displayName"
            currentIndex: root.flow ? root.flow.identities.indexOf(root.flow.selectedIdentity) : -1
            onActivated: index => root.identitySelected(index)
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !!root.flow && root.flow.identities.length === 1
            color: root.config.muted
            font.pointSize: root.config.textSizeMedium
            text: root.flow && root.flow.selectedIdentity ? root.flow.selectedIdentity.displayName : ""
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: !!root.flow && root.flow.supplementaryMessage !== ""
            color: root.flow && root.flow.supplementaryIsError ? root.config.urgent : root.config.muted
            font.pointSize: root.config.textSizeSmall
            wrapMode: Text.WordWrap
            text: root.flow ? root.flow.supplementaryMessage : ""
        }

        ShellTextField {
            id: responseField
            objectName: "polkitResponseField"
            config: root.config
            surfaceColor: root.config.bg
            outlineColor: root.config.muted
            width: parent.width
            visible: !!root.flow && root.flow.isResponseRequired
            placeholderText: root.flow ? root.flow.inputPrompt : ""
            echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
            activeFocusOnTab: true
            onAccepted: root.submitted()
            onVisibleChanged: {
                if (visible)
                    Qt.callLater(() => forceActiveFocus());
            }
            Keys.onEscapePressed: event => {
                root.cancelled();
                event.accepted = true;
            }
        }

        Row {
            width: parent.width
            spacing: 8
            layoutDirection: Qt.RightToLeft

            ShellButton {
                id: cancelButton
                objectName: "polkitCancelButton"
                config: root.config
                text: "Cancel"
                outlined: true
                onClicked: root.cancelled()
                Keys.onEscapePressed: event => {
                    root.cancelled();
                    event.accepted = true;
                }
            }

            ShellButton {
                objectName: "polkitSubmitButton"
                config: root.config
                visible: !!root.flow && root.flow.isResponseRequired
                text: "Authenticate"
                filled: true
                onClicked: root.submitted()
            }
        }
    }
}
