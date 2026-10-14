import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var config
    required property var targetScreen
    property bool opened: false
    // Only language preferences survive closing; no text/history is retained.
    property string sourceLanguage: ""
    property string targetLanguage: "EN-GB"

    function open() { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }

    LazyLoader {
        active: root.opened

        TranslatorWindow {
            config: root.config
            targetScreen: root.targetScreen
            sourceLanguage: root.sourceLanguage
            targetLanguage: root.targetLanguage
            onSourceLanguageChanged: root.sourceLanguage = sourceLanguage
            onTargetLanguageChanged: root.targetLanguage = targetLanguage
            onCloseRequested: root.close()
        }
    }

    IpcHandler {
        target: "translator"
        function open() { root.open() }
        function close() { root.close() }
        function toggle() { root.toggle() }
    }
}
