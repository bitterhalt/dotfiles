pragma ComponentBehavior: Bound

import "../../components"
import "../../services/config/Schema.js" as Schema
import QtQuick

// One settings row: picks the control from `modelData.kind` and delegates saving
// to the owning menu through saveRequested(). The menu keeps valueOf()/save() so
// staged pages and SettingsService-backed values stay in one place.
SettingRow {
    id: root

    required property var modelData
    property var value: undefined
    signal saveRequested(string name, var nextValue)

    readonly property string kind: modelData.kind
    readonly property bool isText: kind === "text" || kind === "integer" || kind === "list"
    readonly property var range: Schema.bounds(modelData.name) || [-1e9, 1e9]

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

    function formatText(kind, value) {
        if (kind === "list")
            return Array.isArray(value) ? value.join(", ") : "";
        return value === undefined || value === null ? "" : String(value);
    }

    function parseText(kind, text) {
        if (kind === "integer")
            return /^\d+$/.test(text.trim()) ? Number(text) : NaN;
        if (kind === "list")
            return text.split(",").map(item => item.trim()).filter(item => item !== "");
        return text;
    }

    ShellStepper {
        visible: root.kind === "stepper"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        config: root.config
        value: Number(root.value)
        step: root.modelData.step || 1
        factor: root.modelData.factor || 1
        decimals: root.modelData.decimals || 0
        suffix: root.modelData.suffix || ""
        from: root.modelData.from !== undefined ? root.modelData.from : root.range[0]
        to: root.modelData.to !== undefined ? root.modelData.to : root.range[1]
        onMoved: next => root.saveRequested(root.modelData.name, next)
    }

    ToggleSwitch {
        visible: root.kind === "toggle"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        config: root.config
        keyboard: true
        checked: !!root.value
        onToggled: root.saveRequested(root.modelData.name, !checked)
    }

    Row {
        visible: root.kind === "choice"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.config.spacingControl

        Repeater {
            model: root.modelData.options || []

            delegate: ShellButton {
                required property var modelData

                config: root.config
                outlined: true
                width: 84
                selected: root.value === modelData.value
                text: modelData.label
                onClicked: root.saveRequested(root.modelData.name, modelData.value)
            }
        }
    }

    // Short fields sit right of the label; lists get a wide wrapped box.
    ShellTextField {
        id: field

        visible: root.isText
        x: root.stacked ? 0 : parent.width - width
        y: root.stacked ? root.stackedOffset : (parent.height - height) / 2
        width: root.stacked ? parent.width : root.modelData.wide ? 280 : 160
        height: root.stacked ? root.stackedHeight : 28
        config: root.config
        wrapMode: root.stacked ? TextInput.Wrap : TextInput.NoWrap
        verticalAlignment: root.stacked ? TextInput.AlignTop : TextInput.AlignVCenter
        font.pointSize: root.config.textSizeMedium
        text: root.formatText(root.kind, root.value)
        // Saved on Enter or blur; the stored value is shown again afterwards,
        // which also restores it after a rejected entry.
        onEditingFinished: {
            root.saveRequested(root.modelData.name, root.parseText(root.kind, text));
            text = Qt.binding(() => root.formatText(root.kind, root.value));
        }
    }
}
