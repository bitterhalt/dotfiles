import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import "../polkit"

Scope {
    id: root

    required property var config
    required property var targetScreen

    readonly property var flow: agent.flow

    function clearResponse(): void {
        promptCard.clearResponse();
    }

    function focusPrompt(): void {
        promptCard.focusPrompt();
    }

    function submitResponse(): void {
        if (!flow || !flow.isResponseRequired)
            return;
        const response = promptCard.response;
        clearResponse();
        flow.submit(response);
    }

    function cancelRequest(): void {
        if (flow)
            flow.cancelAuthenticationRequest();
        clearResponse();
    }

    PolkitAgent {
        id: agent
    }

    PanelWindow {
        id: promptWindow

        screen: root.targetScreen
        visible: agent.isActive
        color: "transparent"
        exclusiveZone: 0
        focusable: true
        implicitWidth: 390
        implicitHeight: promptCard.implicitHeight

        anchors {
            top: true
            left: true
        }

        margins.top: screen ? Math.max(0, Math.round((screen.height - implicitHeight) / 2)) : 0
        margins.left: screen ? Math.max(0, Math.round((screen.width - implicitWidth) / 2)) : 0

        WlrLayershell.namespace: "slim-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => root.focusPrompt());
            else
                root.clearResponse();
        }

        PolkitPrompt {
            id: promptCard
            anchors.fill: parent
            config: root.config
            flow: root.flow
            onSubmitted: root.submitResponse()
            onCancelled: root.cancelRequest()
            onIdentitySelected: index => {
                if (root.flow && index >= 0 && index < root.flow.identities.length) {
                    root.clearResponse();
                    root.flow.selectedIdentity = root.flow.identities[index];
                    Qt.callLater(() => root.focusPrompt());
                }
            }
        }

        Connections {
            target: agent

            function onFlowChanged(): void {
                root.clearResponse();
                if (agent.isActive)
                    Qt.callLater(() => root.focusPrompt());
            }
        }

        Connections {
            target: root.flow
            ignoreUnknownSignals: true

            function onIsResponseRequiredChanged(): void {
                if (root.flow && root.flow.isResponseRequired)
                    Qt.callLater(() => root.focusPrompt());
            }
        }
    }
}
